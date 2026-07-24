import { pool } from "../pool";
import { formatTimestamp, nextSequenceId } from "../helpers";
import { PayPeriod, resolvePayPeriod, type PayPeriodKey } from "./pay-period";

export type ResponseCode = "REQ" | "DEC";
export type ApplicationStatus = "open" | "requested" | "declined" | "assigned" | "unavailable";
export type ReviewStatus = "pending" | "reviewed" | null;

export interface ShiftClient {
  id: number;
  name: string;
}

export interface ShiftRow {
  id: number;
  document_no: string | null;
  start_time: string | null;
  end_time: string | null;
  shift_type: string | null;
  location: string | null;
  status: string | null;
  application_status: ApplicationStatus;
  response_code: ResponseCode | null;
  review_status: ReviewStatus;
  pay_period_id: number | null;
  clients: ShiftClient[];
}

export interface ShiftResponseRow extends ShiftRow {
  response_log_id: number | null;
  responded_at: string | null;
}

function mapClients(value: unknown): ShiftClient[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => {
      if (!item || typeof item !== "object") return null;
      const row = item as { id?: unknown; name?: unknown };
      const id = Number(row.id);
      if (!Number.isFinite(id) || !row.name) return null;
      return { id, name: String(row.name) };
    })
    .filter((item): item is ShiftClient => item !== null);
}

function mapShiftRow(row: {
  id: number;
  document_no: string | null;
  start_time: unknown;
  end_time: unknown;
  shift_type: string | null;
  location: string | null;
  status?: string | null;
  application_status: ApplicationStatus;
  response_code?: ResponseCode | null;
  review_status?: ReviewStatus;
  pay_period_id?: number | null;
  response_log_id?: number | null;
  responded_at?: unknown;
  clients?: unknown;
}): ShiftRow {
  return {
    id: row.id,
    document_no: row.document_no,
    start_time: formatTimestamp(row.start_time),
    end_time: formatTimestamp(row.end_time),
    shift_type: row.shift_type,
    location: row.location,
    status: row.status ?? null,
    application_status: row.application_status,
    response_code: row.response_code ?? null,
    review_status: row.review_status ?? null,
    pay_period_id: row.pay_period_id ?? null,
    clients: mapClients(row.clients),
  };
}

const CLIENTS_JSON_SQL = `COALESCE((
  SELECT json_agg(json_build_object('id', bp.c_bpartner_id, 'name', bp.name) ORDER BY bp.name)
  FROM aberp_rostered_shiftreceiver r
  JOIN c_bpartner bp ON bp.c_bpartner_id = r.c_bpartner_id
  WHERE r.aberp_rostered_shift_id = s.aberp_rostered_shift_id
    AND r.isactive = 'Y'
    AND bp.isactive = 'Y'
), '[]'::json)`;

function mapResponseRow(row: Parameters<typeof mapShiftRow>[0]): ShiftResponseRow {
  return {
    ...mapShiftRow(row),
    response_log_id: row.response_log_id ?? null,
    responded_at: formatTimestamp(row.responded_at),
  };
}

const PERIOD_SHIFT_FILTER = `COALESCE(s.starttime, s.startdate) >= $1::timestamp
  AND COALESCE(s.starttime, s.startdate) <= $2::timestamp`;

const LATEST_RESPONSE_SUBQUERY = `(
  SELECT rl.aberp_rosteredresponse
  FROM aberp_rosteredresponselog rl
  WHERE rl.aberp_rostered_shift_id = s.aberp_rostered_shift_id
    AND rl.isactive = 'Y'
    AND rl.aberp_user_contact_id = $4
    AND COALESCE(rl.issuperseded, 'N') <> 'Y'
  ORDER BY rl.created DESC
  LIMIT 1
)`;

const LATEST_REVIEW_SUBQUERY = `(
  SELECT CASE
    WHEN rl.isreviewed = 'Y' THEN 'reviewed'
    ELSE 'pending'
  END
  FROM aberp_rosteredresponselog rl
  WHERE rl.aberp_rostered_shift_id = s.aberp_rostered_shift_id
    AND rl.isactive = 'Y'
    AND rl.aberp_user_contact_id = $4
    AND COALESCE(rl.issuperseded, 'N') <> 'Y'
  ORDER BY rl.created DESC
  LIMIT 1
)`;

const ACTIVE_REQ_SQL = `(
  EXISTS (
    SELECT 1 FROM aberp_rosteredresponselog rl
    WHERE rl.aberp_rostered_shift_id = s.aberp_rostered_shift_id
      AND rl.isactive = 'Y'
      AND rl.aberp_user_contact_id = $4
      AND rl.aberp_rosteredresponse = 'REQ'
      AND COALESCE(rl.issuperseded, 'N') <> 'Y'
  )
  OR EXISTS (
    SELECT 1 FROM aberp_rostered_shiftstaff ss
    WHERE ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id
      AND ss.isactive = 'Y'
      AND (ss.c_bpartner_staff_id = $3 OR ss.aberp_user_contact_id = $4)
      AND ss.aberp_requestshift = 'Y'
  )
)`;

const ACTIVE_DEC_SQL = `EXISTS (
  SELECT 1 FROM aberp_rosteredresponselog rl
  WHERE rl.aberp_rostered_shift_id = s.aberp_rostered_shift_id
    AND rl.isactive = 'Y'
    AND rl.aberp_user_contact_id = $4
    AND rl.aberp_rosteredresponse = 'DEC'
    AND COALESCE(rl.issuperseded, 'N') <> 'Y'
)`;

const CONFIRMED_ASSIGNEE_SQL = `ss.c_bpartner_staff_id IS NOT NULL
  AND (ss.aberp_requestshift IS NULL OR ss.aberp_requestshift <> 'Y')`;

export async function getOpenShiftsForPeriod(
  periodKey: PayPeriodKey,
  cBPartnerStaffId: number,
  adUserId: number,
): Promise<{ period: PayPeriod | null; items: ShiftRow[] }> {
  const period = await resolvePayPeriod(periodKey);
  if (!period) {
    return { period: null, items: [] };
  }

  const result = await pool.query(
    `SELECT
       s.aberp_rostered_shift_id AS id,
       s.documentno AS document_no,
       s.starttime AS start_time,
       s.endtime AS end_time,
       st.name AS shift_type,
       ml.name AS location,
       rs.name AS status,
       $5::numeric AS pay_period_id,
       ${LATEST_RESPONSE_SUBQUERY} AS response_code,
       ${LATEST_REVIEW_SUBQUERY} AS review_status,
       CASE
         WHEN ${ACTIVE_REQ_SQL} THEN 'requested'
         WHEN EXISTS (
           SELECT 1 FROM aberp_rostered_shiftstaff ss
           WHERE ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id
             AND ss.isactive = 'Y'
             AND (ss.c_bpartner_staff_id = $3 OR ss.aberp_user_contact_id = $4)
             AND ${CONFIRMED_ASSIGNEE_SQL}
         ) THEN 'assigned'
         WHEN EXISTS (
           SELECT 1 FROM aberp_rostered_shiftstaff ss
           WHERE ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id
             AND ss.isactive = 'Y'
             AND ${CONFIRMED_ASSIGNEE_SQL}
             AND ss.c_bpartner_staff_id <> $3
             AND ss.aberp_user_contact_id IS DISTINCT FROM $4
         ) THEN 'unavailable'
         ELSE 'open'
       END AS application_status
     FROM aberp_rostered_shift s
     LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
     LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
     LEFT JOIN r_status rs ON rs.r_status_id = s.r_status_id
     WHERE s.isactive = 'Y'
       AND ${PERIOD_SHIFT_FILTER}
       AND NOT ${ACTIVE_DEC_SQL}
       AND (
         NOT EXISTS (
           SELECT 1 FROM aberp_rostered_shiftstaff ss
           WHERE ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id
             AND ss.isactive = 'Y'
             AND ${CONFIRMED_ASSIGNEE_SQL}
             AND ss.c_bpartner_staff_id <> $3
             AND ss.aberp_user_contact_id IS DISTINCT FROM $4
         )
         OR ${ACTIVE_REQ_SQL}
       )
     ORDER BY s.starttime ASC NULLS LAST
     LIMIT 100`,
    [period.start_date, period.end_date, cBPartnerStaffId, adUserId, period.id],
  );

  return { period, items: result.rows.map(mapShiftRow) };
}

export async function getMyShiftsForPeriod(
  periodKey: PayPeriodKey,
  cBPartnerStaffId: number,
  adUserId: number,
): Promise<{ period: PayPeriod | null; items: ShiftRow[] }> {
  const period = await resolvePayPeriod(periodKey);
  if (!period) {
    return { period: null, items: [] };
  }

  const result = await pool.query(
    `SELECT
       s.aberp_rostered_shift_id AS id,
       s.documentno AS document_no,
       s.starttime AS start_time,
       s.endtime AS end_time,
       st.name AS shift_type,
       ml.name AS location,
       rs.name AS status,
       $5::numeric AS pay_period_id,
       NULL::text AS response_code,
       NULL::text AS review_status,
       'assigned'::text AS application_status,
       ${CLIENTS_JSON_SQL} AS clients
     FROM aberp_rostered_shiftstaff ss
     JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id = ss.aberp_rostered_shift_id
     LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
     LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
     LEFT JOIN r_status rs ON rs.r_status_id = s.r_status_id
     WHERE ss.isactive = 'Y'
       AND s.isactive = 'Y'
       AND (ss.c_bpartner_staff_id = $3 OR ss.aberp_user_contact_id = $4)
       AND (ss.aberp_requestshift IS NULL OR ss.aberp_requestshift <> 'Y')
       AND ${PERIOD_SHIFT_FILTER}
     ORDER BY s.starttime ASC NULLS LAST
     LIMIT 100`,
    [period.start_date, period.end_date, cBPartnerStaffId, adUserId, period.id],
  );

  return { period, items: result.rows.map(mapShiftRow) };
}

export async function getMyShiftResponsesForPeriod(
  periodKey: PayPeriodKey,
  cBPartnerStaffId: number,
  adUserId: number,
): Promise<{ period: PayPeriod | null; items: ShiftResponseRow[] }> {
  const period = await resolvePayPeriod(periodKey);
  if (!period) {
    return { period: null, items: [] };
  }

  const result = await pool.query(
    `SELECT
       s.aberp_rostered_shift_id AS id,
       s.documentno AS document_no,
       s.starttime AS start_time,
       s.endtime AS end_time,
       st.name AS shift_type,
       ml.name AS location,
       rs.name AS status,
       $4::numeric AS pay_period_id,
       rl.aberp_rosteredresponselog_id AS response_log_id,
       rl.aberp_rosteredresponse AS response_code,
       rl.created AS responded_at,
       CASE WHEN rl.isreviewed = 'Y' THEN 'reviewed' ELSE 'pending' END AS review_status,
       CASE
         WHEN rl.aberp_rosteredresponse = 'DEC' THEN 'declined'
         ELSE 'requested'
       END AS application_status
     FROM aberp_rosteredresponselog rl
     JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id = rl.aberp_rostered_shift_id
     LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
     LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
     LEFT JOIN r_status rs ON rs.r_status_id = s.r_status_id
     WHERE rl.isactive = 'Y'
       AND s.isactive = 'Y'
       AND rl.aberp_user_contact_id = $3
       AND COALESCE(rl.issuperseded, 'N') <> 'Y'
       AND ${PERIOD_SHIFT_FILTER}
     ORDER BY rl.created DESC
     LIMIT 100`,
    [period.start_date, period.end_date, adUserId, period.id],
  );

  return { period, items: result.rows.map(mapResponseRow) };
}

/** @deprecated use getMyShiftResponsesForPeriod */
export async function getMyApplicationsForPeriod(
  periodKey: PayPeriodKey,
  cBPartnerStaffId: number,
  adUserId: number,
) {
  return getMyShiftResponsesForPeriod(periodKey, cBPartnerStaffId, adUserId);
}

async function validateShiftResponse(
  shiftId: number,
  response: ResponseCode,
  cBPartnerStaffId: number,
  adUserId: number,
): Promise<{ ok: false; message: string } | { ok: true }> {
  const shift = await pool.query(
    `SELECT aberp_rostered_shift_id
     FROM aberp_rostered_shift
     WHERE aberp_rostered_shift_id = $1 AND isactive = 'Y'
     LIMIT 1`,
    [shiftId],
  );
  if (!shift.rows[0]) {
    return { ok: false, message: "Shift not found" };
  }

  const existing = await pool.query<{ aberp_rosteredresponse: ResponseCode }>(
    `SELECT aberp_rosteredresponse
     FROM aberp_rosteredresponselog
     WHERE aberp_rostered_shift_id = $1
       AND isactive = 'Y'
       AND aberp_user_contact_id = $2
       AND COALESCE(issuperseded, 'N') <> 'Y'
     ORDER BY created DESC
     LIMIT 1`,
    [shiftId, adUserId],
  );
  if (existing.rows[0]?.aberp_rosteredresponse === response) {
    const label = response === "REQ" ? "requested" : "declined";
    return { ok: false, message: `You have already ${label} this shift` };
  }

  if (response === "REQ") {
    const legacyApplication = await pool.query(
      `SELECT aberp_rostered_shiftstaff_id
       FROM aberp_rostered_shiftstaff
       WHERE aberp_rostered_shift_id = $1 AND isactive = 'Y'
         AND (c_bpartner_staff_id = $2 OR aberp_user_contact_id = $3)
         AND aberp_requestshift = 'Y'
       LIMIT 1`,
      [shiftId, cBPartnerStaffId, adUserId],
    );
    if (legacyApplication.rows[0]) {
      return { ok: false, message: "You have already requested this shift" };
    }

    const alreadyAssigned = await pool.query(
      `SELECT aberp_rostered_shiftstaff_id
       FROM aberp_rostered_shiftstaff
       WHERE aberp_rostered_shift_id = $1 AND isactive = 'Y'
         AND (c_bpartner_staff_id = $2 OR aberp_user_contact_id = $3)
         AND (aberp_requestshift IS NULL OR aberp_requestshift <> 'Y')
       LIMIT 1`,
      [shiftId, cBPartnerStaffId, adUserId],
    );
    if (alreadyAssigned.rows[0]) {
      return { ok: false, message: "You are already assigned to this shift" };
    }

    const taken = await pool.query(
      `SELECT aberp_rostered_shiftstaff_id
       FROM aberp_rostered_shiftstaff
       WHERE aberp_rostered_shift_id = $1 AND isactive = 'Y'
         AND c_bpartner_staff_id IS NOT NULL
         AND (aberp_requestshift IS NULL OR aberp_requestshift <> 'Y')
         AND c_bpartner_staff_id <> $2
         AND aberp_user_contact_id IS DISTINCT FROM $3
       LIMIT 1`,
      [shiftId, cBPartnerStaffId, adUserId],
    );
    if (taken.rows.length > 0) {
      return { ok: false, message: "This shift is no longer available" };
    }
  }

  return { ok: true };
}

export async function recordShiftResponse(
  shiftId: number,
  response: ResponseCode,
  cBPartnerStaffId: number,
  adUserId: number,
  adClientId: number,
): Promise<{ recorded: boolean; message: string; response: ResponseCode }> {
  const validation = await validateShiftResponse(shiftId, response, cBPartnerStaffId, adUserId);
  if (!validation.ok) {
    return { recorded: false, message: validation.message, response };
  }

  await pool.query(
    `UPDATE aberp_rosteredresponselog
     SET issuperseded = 'Y', updated = NOW(), updatedby = $3
     WHERE aberp_rostered_shift_id = $1
       AND aberp_user_contact_id = $2
       AND isactive = 'Y'
       AND COALESCE(issuperseded, 'N') <> 'Y'`,
    [shiftId, adUserId, adUserId],
  );

  const newId = await nextSequenceId("AbERP_RosteredResponseLog");
  await pool.query(
    `INSERT INTO aberp_rosteredresponselog (
       aberp_rosteredresponselog_id, ad_client_id, ad_org_id, isactive,
       created, createdby, updated, updatedby,
       aberp_user_contact_id, aberp_rosteredresponse, aberp_rostered_shift_id,
       issuperseded, isreviewed
     ) VALUES (
       $1, $2, 0, 'Y',
       NOW(), $3, NOW(), $3,
       $3, $4, $5,
       'N', 'N'
     )`,
    [newId, adClientId, adUserId, response, shiftId],
  );

  const message =
    response === "REQ"
      ? "Shift request submitted for review"
      : "Shift declined — recorded in response log";

  return { recorded: true, message, response };
}

/** @deprecated use recordShiftResponse with REQ */
export async function applyForShift(
  shiftId: number,
  cBPartnerStaffId: number,
  adUserId: number,
  adClientId: number,
): Promise<{ applied: boolean; message: string }> {
  const result = await recordShiftResponse(shiftId, "REQ", cBPartnerStaffId, adUserId, adClientId);
  return { applied: result.recorded, message: result.message };
}
