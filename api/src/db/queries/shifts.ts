import { pool } from "../pool";
import { formatTimestamp, nextSequenceId } from "../helpers";
import { PayPeriod, resolvePayPeriod, type PayPeriodKey } from "./pay-period";

export type ApplicationStatus = "open" | "applied" | "assigned" | "unavailable";

export interface ShiftRow {
  id: number;
  document_no: string | null;
  start_time: string | null;
  end_time: string | null;
  shift_type: string | null;
  location: string | null;
  status: string | null;
  application_status: ApplicationStatus;
  pay_period_id: number | null;
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
  pay_period_id?: number | null;
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
    pay_period_id: row.pay_period_id ?? null,
  };
}

const PERIOD_SHIFT_FILTER = `COALESCE(s.starttime, s.startdate) >= $1::timestamp
  AND COALESCE(s.starttime, s.startdate) <= $2::timestamp`;

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
       CASE
         WHEN EXISTS (
           SELECT 1 FROM aberp_rostered_shiftstaff ss
           WHERE ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id
             AND ss.isactive = 'Y'
             AND (ss.c_bpartner_staff_id = $3 OR ss.aberp_user_contact_id = $4)
             AND ss.aberp_requestshift = 'Y'
         ) THEN 'applied'
         WHEN EXISTS (
           SELECT 1 FROM aberp_rostered_shiftstaff ss
           WHERE ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id
             AND ss.isactive = 'Y'
             AND ss.c_bpartner_staff_id IS NOT NULL
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
       AND (
         NOT EXISTS (
           SELECT 1 FROM aberp_rostered_shiftstaff ss
           WHERE ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id
             AND ss.isactive = 'Y'
             AND ss.c_bpartner_staff_id IS NOT NULL
             AND ss.c_bpartner_staff_id <> $3
             AND ss.aberp_user_contact_id IS DISTINCT FROM $4
         )
         OR EXISTS (
           SELECT 1 FROM aberp_rostered_shiftstaff ss
           WHERE ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id
             AND ss.isactive = 'Y'
             AND (ss.c_bpartner_staff_id = $3 OR ss.aberp_user_contact_id = $4)
             AND ss.aberp_requestshift = 'Y'
         )
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
       'assigned'::text AS application_status
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

export async function getMyApplicationsForPeriod(
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
       'applied'::text AS application_status
     FROM aberp_rostered_shiftstaff ss
     JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id = ss.aberp_rostered_shift_id
     LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
     LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
     LEFT JOIN r_status rs ON rs.r_status_id = s.r_status_id
     WHERE ss.isactive = 'Y'
       AND s.isactive = 'Y'
       AND (ss.c_bpartner_staff_id = $3 OR ss.aberp_user_contact_id = $4)
       AND ss.aberp_requestshift = 'Y'
       AND ${PERIOD_SHIFT_FILTER}
     ORDER BY s.starttime ASC NULLS LAST
     LIMIT 100`,
    [period.start_date, period.end_date, cBPartnerStaffId, adUserId, period.id],
  );

  return { period, items: result.rows.map(mapShiftRow) };
}

export async function applyForShift(
  shiftId: number,
  cBPartnerStaffId: number,
  adUserId: number,
  adClientId: number,
): Promise<{ applied: boolean; message: string }> {
  const existing = await pool.query(
    `SELECT aberp_rostered_shiftstaff_id, aberp_requestshift
     FROM aberp_rostered_shiftstaff
     WHERE aberp_rostered_shift_id = $1 AND isactive = 'Y'
       AND (c_bpartner_staff_id = $2 OR aberp_user_contact_id = $3)
     LIMIT 1`,
    [shiftId, cBPartnerStaffId, adUserId],
  );

  if (existing.rows[0]?.aberp_requestshift === "Y") {
    return { applied: false, message: "You have already applied for this shift" };
  }

  if (existing.rows[0]) {
    return { applied: false, message: "You are already assigned to this shift" };
  }

  const taken = await pool.query(
    `SELECT aberp_rostered_shiftstaff_id
     FROM aberp_rostered_shiftstaff
     WHERE aberp_rostered_shift_id = $1 AND isactive = 'Y'
       AND c_bpartner_staff_id IS NOT NULL
       AND c_bpartner_staff_id <> $2
       AND aberp_user_contact_id IS DISTINCT FROM $3
     LIMIT 1`,
    [shiftId, cBPartnerStaffId, adUserId],
  );
  if (taken.rows.length > 0) {
    return { applied: false, message: "This shift is no longer available" };
  }

  const unassigned = await pool.query(
    `SELECT aberp_rostered_shiftstaff_id
     FROM aberp_rostered_shiftstaff
     WHERE aberp_rostered_shift_id = $1 AND isactive = 'Y' AND c_bpartner_staff_id IS NULL
     ORDER BY line ASC NULLS LAST
     LIMIT 1`,
    [shiftId],
  );

  if (unassigned.rows[0]) {
    await pool.query(
      `UPDATE aberp_rostered_shiftstaff
       SET c_bpartner_staff_id = $1,
           aberp_user_contact_id = $2,
           aberp_requestshift = 'Y',
           updated = NOW(),
           updatedby = $3
       WHERE aberp_rostered_shiftstaff_id = $4`,
      [cBPartnerStaffId, adUserId, adUserId, unassigned.rows[0].aberp_rostered_shiftstaff_id],
    );
    return { applied: true, message: "Shift application submitted" };
  }

  const newId = await nextSequenceId("AbERP_Rostered_ShiftStaff");
  await pool.query(
    `INSERT INTO aberp_rostered_shiftstaff (
       aberp_rostered_shiftstaff_id, ad_client_id, ad_org_id, isactive,
       created, createdby, updated, updatedby, line,
       aberp_rostered_shift_id, c_bpartner_staff_id, aberp_user_contact_id, aberp_requestshift
     ) VALUES (
       $1, $2, 0, 'Y',
       NOW(), $3, NOW(), $3, 10,
       $4, $5, $3, 'Y'
     )`,
    [newId, adClientId, adUserId, shiftId, cBPartnerStaffId],
  );
  return { applied: true, message: "Shift application submitted" };
}
