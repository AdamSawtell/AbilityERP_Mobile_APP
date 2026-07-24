import { pool } from "../pool";
import { formatTimestamp, nextSequenceId } from "../helpers";

export interface ClientListItem {
  id: number;
  name: string;
  value: string | null;
  nextShiftAt: string | null;
  hasCarePlan: boolean;
}

export interface ClientDetail {
  id: number;
  name: string;
  value: string | null;
  email: string | null;
  phone: string | null;
  address: string | null;
}

export interface CarePlanSummary {
  id: number;
  assessmentId: number;
  documentNo: string | null;
  name: string | null;
  validFrom: string | null;
  validTo: string | null;
  importantToMe: string | null;
  likes: string | null;
  dislikes: string | null;
  hobbies: string | null;
  culturalNeeds: string | null;
  amRoutine: string | null;
  dayRoutine: string | null;
  pmRoutine: string | null;
  nightRoutine: string | null;
  weeklyRoutine: string | null;
  allergiesFlag: boolean;
  fallRisk: boolean;
  medicationRequired: boolean;
  behaviourSupportRequired: boolean;
  strategies: string | null;
  behaviourDescription: string | null;
  details: string | null;
}

export interface ActivityItem {
  id: number;
  type: string | null;
  typeLabel: string | null;
  description: string | null;
  comments: string | null;
  startDate: string | null;
  isComplete: boolean;
}

const WORKER_CLIENT_ACCESS = `
  EXISTS (
    SELECT 1
    FROM aberp_rostered_shiftstaff ss
    JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id = ss.aberp_rostered_shift_id
    JOIN aberp_rostered_shiftreceiver r ON r.aberp_rostered_shift_id = s.aberp_rostered_shift_id
    WHERE ss.isactive = 'Y'
      AND s.isactive = 'Y'
      AND r.isactive = 'Y'
      AND r.c_bpartner_id = bp.c_bpartner_id
      AND (ss.c_bpartner_staff_id = $1 OR ss.aberp_user_contact_id = $2)
      AND COALESCE(s.starttime, s.startdate) >= NOW() - INTERVAL '90 days'
      AND COALESCE(s.starttime, s.startdate) <= NOW() + INTERVAL '60 days'
  )
`;

async function assertClientAccess(
  clientId: number,
  cBPartnerStaffId: number,
  adUserId: number,
): Promise<boolean> {
  const result = await pool.query(
    `SELECT 1
     FROM c_bpartner bp
     WHERE bp.c_bpartner_id = $3
       AND bp.isactive = 'Y'
       AND bp.iscustomer = 'Y'
       AND ${WORKER_CLIENT_ACCESS}
     LIMIT 1`,
    [cBPartnerStaffId, adUserId, clientId],
  );
  return result.rowCount !== null && result.rowCount > 0;
}

export async function listMyClients(
  cBPartnerStaffId: number,
  adUserId: number,
): Promise<ClientListItem[]> {
  const result = await pool.query(
    `SELECT
       bp.c_bpartner_id AS id,
       bp.name,
       bp.value,
       (
         SELECT MIN(COALESCE(s2.starttime, s2.startdate))
         FROM aberp_rostered_shiftreceiver r2
         JOIN aberp_rostered_shift s2 ON s2.aberp_rostered_shift_id = r2.aberp_rostered_shift_id
         JOIN aberp_rostered_shiftstaff ss2 ON ss2.aberp_rostered_shift_id = s2.aberp_rostered_shift_id
         WHERE r2.c_bpartner_id = bp.c_bpartner_id
           AND r2.isactive = 'Y' AND s2.isactive = 'Y' AND ss2.isactive = 'Y'
           AND (ss2.c_bpartner_staff_id = $1 OR ss2.aberp_user_contact_id = $2)
           AND COALESCE(s2.starttime, s2.startdate) >= date_trunc('day', NOW())
       ) AS next_shift_at,
       EXISTS (
         SELECT 1
         FROM aberp_plans_assessment pa
         JOIN aberp_supportplans sp ON sp.aberp_plans_assessment_id = pa.aberp_plans_assessment_id
         WHERE pa.c_bpartner_id = bp.c_bpartner_id
           AND pa.isactive = 'Y' AND sp.isactive = 'Y'
       ) AS has_care_plan
     FROM c_bpartner bp
     WHERE bp.isactive = 'Y'
       AND bp.iscustomer = 'Y'
       AND ${WORKER_CLIENT_ACCESS}
     ORDER BY bp.name
     LIMIT 100`,
    [cBPartnerStaffId, adUserId],
  );

  return result.rows.map((row) => ({
    id: Number(row.id),
    name: String(row.name),
    value: row.value ? String(row.value) : null,
    nextShiftAt: formatTimestamp(row.next_shift_at),
    hasCarePlan: Boolean(row.has_care_plan),
  }));
}

export async function getClientDetail(
  clientId: number,
  cBPartnerStaffId: number,
  adUserId: number,
): Promise<ClientDetail | null> {
  if (!(await assertClientAccess(clientId, cBPartnerStaffId, adUserId))) {
    return null;
  }

  const result = await pool.query(
    `SELECT
       bp.c_bpartner_id AS id,
       bp.name,
       bp.value,
       COALESCE(u.email, bp.email) AS email,
       COALESCE(u.phone, bp.phone) AS phone,
       NULLIF(TRIM(CONCAT_WS(', ',
         NULLIF(loc.address1, ''),
         NULLIF(loc.city, ''),
         NULLIF(reg.name, ''),
         NULLIF(loc.postal, '')
       )), '') AS address
     FROM c_bpartner bp
     LEFT JOIN LATERAL (
       SELECT email, phone
       FROM ad_user
       WHERE c_bpartner_id = bp.c_bpartner_id AND isactive = 'Y'
       ORDER BY ad_user_id
       LIMIT 1
     ) u ON TRUE
     LEFT JOIN LATERAL (
       SELECT c_location_id
       FROM c_bpartner_location
       WHERE c_bpartner_id = bp.c_bpartner_id AND isactive = 'Y'
       ORDER BY isbillto DESC, c_bpartner_location_id
       LIMIT 1
     ) bpl ON TRUE
     LEFT JOIN c_location loc ON loc.c_location_id = bpl.c_location_id
     LEFT JOIN c_region reg ON reg.c_region_id = loc.c_region_id
     WHERE bp.c_bpartner_id = $1`,
    [clientId],
  );

  const row = result.rows[0];
  if (!row) return null;

  return {
    id: Number(row.id),
    name: String(row.name),
    value: row.value ? String(row.value) : null,
    email: row.email ? String(row.email) : null,
    phone: row.phone ? String(row.phone) : null,
    address: row.address ? String(row.address) : null,
  };
}

export async function getCarePlan(
  clientId: number,
  cBPartnerStaffId: number,
  adUserId: number,
): Promise<CarePlanSummary | null> {
  if (!(await assertClientAccess(clientId, cBPartnerStaffId, adUserId))) {
    return null;
  }

  const result = await pool.query(
    `SELECT
       sp.aberp_supportplans_id AS id,
       pa.aberp_plans_assessment_id AS assessment_id,
       pa.documentno AS document_no,
       COALESCE(NULLIF(pa.name, ''), NULLIF(sp.name, ''), 'Support plan') AS name,
       pa.validfrom AS valid_from,
       pa.validto AS valid_to,
       sp.aberp_importanttome AS important_to_me,
       sp.aberp_likes AS likes,
       sp.aberp_dislikes AS dislikes,
       sp.aberp_hobbie AS hobbies,
       sp.aberp_cultural_needs AS cultural_needs,
       sp.aberp_am_routine AS am_routine,
       sp.aberp_day_routine AS day_routine,
       sp.aberp_pm_routine AS pm_routine,
       sp.aberp_night_routine AS night_routine,
       sp.aberp_weekly_routine AS weekly_routine,
       COALESCE(sp.aberp_isallergies, 'N') = 'Y' AS allergies_flag,
       COALESCE(sp.aberp_isfallrisk, 'N') = 'Y' AS fall_risk,
       COALESCE(sp.aberp_ismedicationreq, 'N') = 'Y' AS medication_required,
       COALESCE(sp.aberp_isbehavioursuppreq, 'N') = 'Y' AS behaviour_support_required,
       sp.aberp_strategies AS strategies,
       sp.aberp_behaviour_description AS behaviour_description,
       sp.aberp_details AS details
     FROM aberp_plans_assessment pa
     JOIN aberp_supportplans sp ON sp.aberp_plans_assessment_id = pa.aberp_plans_assessment_id
     WHERE pa.c_bpartner_id = $1
       AND pa.isactive = 'Y'
       AND sp.isactive = 'Y'
     ORDER BY
       CASE WHEN pa.validto IS NULL OR pa.validto::date >= CURRENT_DATE THEN 0 ELSE 1 END,
       pa.validto DESC NULLS LAST,
       pa.aberp_plans_assessment_id DESC
     LIMIT 1`,
    [clientId],
  );

  const row = result.rows[0];
  if (!row) return null;

  return {
    id: Number(row.id),
    assessmentId: Number(row.assessment_id),
    documentNo: row.document_no ? String(row.document_no) : null,
    name: row.name ? String(row.name) : null,
    validFrom: formatTimestamp(row.valid_from),
    validTo: formatTimestamp(row.valid_to),
    importantToMe: row.important_to_me ? String(row.important_to_me) : null,
    likes: row.likes ? String(row.likes) : null,
    dislikes: row.dislikes ? String(row.dislikes) : null,
    hobbies: row.hobbies ? String(row.hobbies) : null,
    culturalNeeds: row.cultural_needs ? String(row.cultural_needs) : null,
    amRoutine: row.am_routine ? String(row.am_routine) : null,
    dayRoutine: row.day_routine ? String(row.day_routine) : null,
    pmRoutine: row.pm_routine ? String(row.pm_routine) : null,
    nightRoutine: row.night_routine ? String(row.night_routine) : null,
    weeklyRoutine: row.weekly_routine ? String(row.weekly_routine) : null,
    allergiesFlag: Boolean(row.allergies_flag),
    fallRisk: Boolean(row.fall_risk),
    medicationRequired: Boolean(row.medication_required),
    behaviourSupportRequired: Boolean(row.behaviour_support_required),
    strategies: row.strategies ? String(row.strategies) : null,
    behaviourDescription: row.behaviour_description
      ? String(row.behaviour_description)
      : null,
    details: row.details ? String(row.details) : null,
  };
}

export async function listActivities(
  clientId: number,
  cBPartnerStaffId: number,
  adUserId: number,
): Promise<ActivityItem[] | null> {
  if (!(await assertClientAccess(clientId, cBPartnerStaffId, adUserId))) {
    return null;
  }

  const result = await pool.query(
    `SELECT
       a.c_contactactivity_id AS id,
       a.contactactivitytype AS type,
       COALESCE(rl.name, a.contactactivitytype) AS type_label,
       a.description,
       a.comments,
       a.startdate AS start_date,
       COALESCE(a.iscomplete, 'N') = 'Y' AS is_complete
     FROM c_contactactivity a
     LEFT JOIN ad_ref_list rl
       ON rl.value = a.contactactivitytype
      AND rl.ad_reference_id = (
        SELECT ad_reference_id FROM ad_reference WHERE name = 'C_ContactActivity Type' LIMIT 1
      )
     WHERE a.isactive = 'Y'
       AND a.c_bpartner_id = $1
     ORDER BY a.startdate DESC NULLS LAST, a.c_contactactivity_id DESC
     LIMIT 50`,
    [clientId],
  );

  return result.rows.map((row) => ({
    id: Number(row.id),
    type: row.type ? String(row.type) : null,
    typeLabel: row.type_label ? String(row.type_label) : null,
    description: row.description ? String(row.description) : null,
    comments: row.comments ? String(row.comments) : null,
    startDate: formatTimestamp(row.start_date),
    isComplete: Boolean(row.is_complete),
  }));
}

export async function createActivity(
  clientId: number,
  cBPartnerStaffId: number,
  adUserId: number,
  adClientId: number,
  input: { description: string; comments?: string; type?: string },
): Promise<ActivityItem | null> {
  if (!(await assertClientAccess(clientId, cBPartnerStaffId, adUserId))) {
    return null;
  }

  const type = input.type && input.type.trim() ? input.type.trim() : "PGNOTE";
  const description = input.description.trim();
  if (!description) {
    throw new Error("Description is required");
  }

  const id = await nextSequenceId(
    "C_ContactActivity",
    "c_contactactivity",
    "c_contactactivity_id",
  );

  await pool.query(
    `INSERT INTO c_contactactivity (
       c_contactactivity_id, ad_client_id, ad_org_id, isactive,
       created, createdby, updated, updatedby, c_contactactivity_uu,
       c_bpartner_id, contactactivitytype, c_contactactivityrelatedto,
       description, comments, startdate, enddate,
       salesrep_id, ad_user_id, iscomplete
     ) VALUES (
       $1, $2, 0, 'Y',
       NOW(), $3, NOW(), $3, md5(random()::text || clock_timestamp()::text),
       $4, $5, 'BP',
       $6, $7, NOW(), NOW(),
       $3, $3, 'Y'
     )`,
    [
      id,
      adClientId,
      adUserId,
      clientId,
      type,
      description,
      input.comments?.trim() || null,
    ],
  );

  const items = await listActivities(clientId, cBPartnerStaffId, adUserId);
  return items?.find((a) => a.id === id) ?? {
    id,
    type,
    typeLabel: type,
    description,
    comments: input.comments?.trim() || null,
    startDate: new Date().toISOString(),
    isComplete: true,
  };
}
