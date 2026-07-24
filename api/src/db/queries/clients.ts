import { pool } from "../pool";
import { formatTimestamp, nextSequenceId } from "../helpers";

export interface ClientListItem {
  id: number;
  name: string;
  value: string | null;
  nextShiftAt: string | null;
  hasCarePlan: boolean;
}

export interface ClientAlert {
  id: number;
  type: string | null;
  name: string | null;
  description: string | null;
  isAlert: boolean;
  validFrom: string | null;
  validTo: string | null;
}

export interface ClientKeyPerson {
  id: number;
  name: string;
  relationship: string | null;
  phone: string | null;
  email: string | null;
  notes: string | null;
}

export interface ClientAddress {
  label: string | null;
  address: string;
  phone: string | null;
  isHome: boolean;
}

export interface ShiftEssentials {
  allergiesFlag: boolean;
  fallRisk: boolean;
  medicationRequired: boolean;
  behaviourSupportRequired: boolean;
  interpreterRequired: boolean;
  swallowingRisk: boolean;
  importantToMe: string | null;
  communication: string | null;
  mobility: string | null;
  transport: string | null;
  dietaryAllergies: string | null;
  likes: string | null;
  dislikes: string | null;
}

export interface ClientDetail {
  id: number;
  name: string;
  preferredName: string | null;
  value: string | null;
  email: string | null;
  phone: string | null;
  phone2: string | null;
  address: string | null;
  addresses: ClientAddress[];
  birthday: string | null;
  age: number | null;
  gender: string | null;
  disability: string | null;
  ndisNumber: string | null;
  about: string | null;
  alerts: ClientAlert[];
  keyPeople: ClientKeyPerson[];
  shiftEssentials: ShiftEssentials | null;
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

  const profile = await pool.query(
    `SELECT
       bp.c_bpartner_id AS id,
       bp.name,
       NULLIF(TRIM(bp.aberp_preferred_name), '') AS preferred_name,
       bp.value,
       COALESCE(u.email, bp.email) AS email,
       COALESCE(NULLIF(TRIM(bp.phone), ''), NULLIF(TRIM(u.phone), '')) AS phone,
       NULLIF(TRIM(bp.phone2), '') AS phone2,
       bp.birthday,
       bp.aberp_age AS age,
       g.name AS gender,
       d.name AS disability,
       NULLIF(TRIM(bp.aberp_ndis_region), '') AS ndis_number,
       NULLIF(TRIM(bp.aberp_about), '') AS about
     FROM c_bpartner bp
     LEFT JOIN aberp_gender g ON g.aberp_gender_id = bp.aberp_gender_id
     LEFT JOIN aberp_disability d ON d.aberp_disability_id = bp.aberp_disability_id
     LEFT JOIN LATERAL (
       SELECT email, phone
       FROM ad_user
       WHERE c_bpartner_id = bp.c_bpartner_id AND isactive = 'Y'
       ORDER BY ad_user_id
       LIMIT 1
     ) u ON TRUE
     WHERE bp.c_bpartner_id = $1`,
    [clientId],
  );

  const row = profile.rows[0];
  if (!row) return null;

  const [addressesResult, alertsResult, peopleResult, essentialsResult] =
    await Promise.all([
      pool.query(
        `SELECT
           COALESCE(NULLIF(TRIM(bpl.name), ''), CASE WHEN bpl.isshipto = 'Y' THEN 'Service location' ELSE 'Address' END) AS label,
           NULLIF(TRIM(CONCAT_WS(', ',
             NULLIF(loc.address1, ''),
             NULLIF(loc.address2, ''),
             NULLIF(loc.city, ''),
             NULLIF(reg.name, ''),
             NULLIF(loc.postal, '')
           )), '') AS address,
           NULLIF(TRIM(bpl.phone), '') AS phone,
           (
             bpl.isshipto = 'Y'
             AND (
               bpl.name ILIKE '%home%'
               OR bpl.name ILIKE '%house%'
               OR bpl.isbillto = 'N'
             )
           ) AS is_home
         FROM c_bpartner_location bpl
         JOIN c_location loc ON loc.c_location_id = bpl.c_location_id
         LEFT JOIN c_region reg ON reg.c_region_id = loc.c_region_id
         WHERE bpl.c_bpartner_id = $1
           AND bpl.isactive = 'Y'
         ORDER BY
           CASE
             WHEN bpl.name ILIKE '%home%' OR bpl.name ILIKE '%house%' THEN 0
             WHEN bpl.isshipto = 'Y' AND bpl.isbillto = 'N' THEN 1
             WHEN bpl.isshipto = 'Y' THEN 2
             ELSE 3
           END,
           bpl.c_bpartner_location_id
         LIMIT 8`,
        [clientId],
      ),
      pool.query(
        `SELECT
           a.aberp_alert_sr_id AS id,
           t.name AS type,
           a.name,
           a.description,
           COALESCE(a.aberp_isalert, 'N') = 'Y' AS is_alert,
           a.validfrom AS valid_from,
           a.validto AS valid_to
         FROM aberp_alert_sr a
         LEFT JOIN aberp_alert_type t ON t.aberp_alert_type_id = a.aberp_alert_type_id
         WHERE a.c_bpartner_id = $1
           AND a.isactive = 'Y'
           AND (a.validfrom IS NULL OR a.validfrom::date <= CURRENT_DATE)
           AND (a.validto IS NULL OR a.validto::date >= CURRENT_DATE)
         ORDER BY COALESCE(a.aberp_isalert, 'N') DESC, a.line NULLS LAST, a.aberp_alert_sr_id
         LIMIT 20`,
        [clientId],
      ),
      pool.query(
        `SELECT
           a.aberp_bp_associations_id AS id,
           COALESCE(
             NULLIF(TRIM(a.name), ''),
             NULLIF(TRIM(assoc.name), ''),
             NULLIF(TRIM(u.name), ''),
             'Contact'
           ) AS name,
           (
             SELECT string_agg(DISTINCT rt.name, ', ' ORDER BY rt.name)
             FROM unnest(COALESCE(a.aberp_relationshiptype_id, ARRAY[]::numeric[])) AS rid(id)
             JOIN aberp_relationshiptype rt ON rt.aberp_relationshiptype_id = rid.id
           ) AS relationship,
           COALESCE(
             NULLIF(TRIM(u.phone), ''),
             NULLIF(TRIM(assoc.phone), ''),
             NULLIF(TRIM(assoc.phone2), '')
           ) AS phone,
           COALESCE(NULLIF(TRIM(u.email), ''), NULLIF(TRIM(assoc.email), '')) AS email,
           NULLIF(TRIM(CONCAT_WS(' — ',
             NULLIF(TRIM(a.description), ''),
             NULLIF(TRIM(a.aberp_other), '')
           )), '') AS notes
         FROM aberp_bp_associations a
         LEFT JOIN c_bpartner assoc ON assoc.c_bpartner_id = a.c_bp_associate_id
         LEFT JOIN ad_user u ON u.ad_user_id = a.ad_user_id
         WHERE a.c_bpartner_id = $1
           AND a.isactive = 'Y'
           AND COALESCE(a.c_bp_associate_id, 0) IS DISTINCT FROM $1
         ORDER BY a.aberp_bp_associations_id
         LIMIT 20`,
        [clientId],
      ),
      pool.query(
        `SELECT
           COALESCE(sp.aberp_isallergies, 'N') = 'Y' AS allergies_flag,
           COALESCE(sp.aberp_isfallrisk, 'N') = 'Y' AS fall_risk,
           COALESCE(sp.aberp_ismedicationreq, 'N') = 'Y' AS medication_required,
           COALESCE(sp.aberp_isbehavioursuppreq, 'N') = 'Y' AS behaviour_support_required,
           COALESCE(sp.aberp_isinterpreterreq, 'N') = 'Y' AS interpreter_required,
           COALESCE(sp.aberp_swallowing_risk, 'N') = 'Y' AS swallowing_risk,
           sp.aberp_importanttome AS important_to_me,
           sp.aberp_comm_describe AS communication,
           NULLIF(TRIM(CONCAT_WS(' — ',
             CASE WHEN COALESCE(sp.aberp_ismobilityaidused, 'N') = 'Y' THEN 'Mobility aid used' END,
             NULLIF(TRIM(sp.aberp_mobility_support), ''),
             NULLIF(TRIM(sp.aberp_mobility_detail), '')
           )), '') AS mobility,
           sp.aberp_transport_arr AS transport,
           sp.aberp_dietary_allergies AS dietary_allergies,
           sp.aberp_likes AS likes,
           sp.aberp_dislikes AS dislikes
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
      ),
    ]);

  const addresses: ClientAddress[] = addressesResult.rows
    .map((item) => ({
      label: item.label ? String(item.label) : null,
      address: item.address ? String(item.address) : "",
      phone: item.phone ? String(item.phone) : null,
      isHome: Boolean(item.is_home),
    }))
    .filter((item) => item.address);

  const primaryAddress =
    addresses.find((a) => a.isHome)?.address ?? addresses[0]?.address ?? null;

  const essentialsRow = essentialsResult.rows[0];
  const shiftEssentials: ShiftEssentials | null = essentialsRow
    ? {
        allergiesFlag: Boolean(essentialsRow.allergies_flag),
        fallRisk: Boolean(essentialsRow.fall_risk),
        medicationRequired: Boolean(essentialsRow.medication_required),
        behaviourSupportRequired: Boolean(essentialsRow.behaviour_support_required),
        interpreterRequired: Boolean(essentialsRow.interpreter_required),
        swallowingRisk: Boolean(essentialsRow.swallowing_risk),
        importantToMe: essentialsRow.important_to_me
          ? String(essentialsRow.important_to_me)
          : null,
        communication: essentialsRow.communication
          ? String(essentialsRow.communication)
          : null,
        mobility: essentialsRow.mobility ? String(essentialsRow.mobility) : null,
        transport: essentialsRow.transport ? String(essentialsRow.transport) : null,
        dietaryAllergies: essentialsRow.dietary_allergies
          ? String(essentialsRow.dietary_allergies)
          : null,
        likes: essentialsRow.likes ? String(essentialsRow.likes) : null,
        dislikes: essentialsRow.dislikes ? String(essentialsRow.dislikes) : null,
      }
    : null;

  return {
    id: Number(row.id),
    name: String(row.name),
    preferredName: row.preferred_name ? String(row.preferred_name) : null,
    value: row.value ? String(row.value) : null,
    email: row.email ? String(row.email) : null,
    phone: row.phone ? String(row.phone) : null,
    phone2: row.phone2 ? String(row.phone2) : null,
    address: primaryAddress,
    addresses,
    birthday: formatTimestamp(row.birthday),
    age: row.age !== null && row.age !== undefined ? Number(row.age) : null,
    gender: row.gender ? String(row.gender) : null,
    disability: row.disability ? String(row.disability) : null,
    ndisNumber: row.ndis_number ? String(row.ndis_number) : null,
    about: row.about ? String(row.about) : null,
    alerts: alertsResult.rows.map((item) => ({
      id: Number(item.id),
      type: item.type ? String(item.type) : null,
      name: item.name ? String(item.name) : null,
      description: item.description ? String(item.description) : null,
      isAlert: Boolean(item.is_alert),
      validFrom: formatTimestamp(item.valid_from),
      validTo: formatTimestamp(item.valid_to),
    })),
    keyPeople: peopleResult.rows.map((item) => ({
      id: Number(item.id),
      name: String(item.name),
      relationship: item.relationship ? String(item.relationship) : null,
      phone: item.phone ? String(item.phone) : null,
      email: item.email ? String(item.email) : null,
      notes: item.notes ? String(item.notes) : null,
    })),
    shiftEssentials,
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
