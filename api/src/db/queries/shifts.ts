import { pool } from "../pool";
import { formatTimestamp, nextSequenceId } from "../helpers";

export interface ShiftRow {
  id: number;
  document_no: string | null;
  start_time: string | null;
  end_time: string | null;
  shift_type: string | null;
  location: string | null;
  status: string | null;
  request_status: string | null;
}

function mapShiftRow(row: {
  id: number;
  document_no: string | null;
  start_time: unknown;
  end_time: unknown;
  shift_type: string | null;
  location: string | null;
  status?: string | null;
  request_status?: string | null;
}): ShiftRow {
  return {
    id: row.id,
    document_no: row.document_no,
    start_time: formatTimestamp(row.start_time),
    end_time: formatTimestamp(row.end_time),
    shift_type: row.shift_type,
    location: row.location,
    status: row.status ?? null,
    request_status: row.request_status ?? null,
  };
}

export async function getOpenShifts(): Promise<ShiftRow[]> {
  const result = await pool.query(
    `SELECT
       s.aberp_rostered_shift_id AS id,
       s.documentno AS document_no,
       s.starttime AS start_time,
       s.endtime AS end_time,
       st.name AS shift_type,
       ml.name AS location,
       rs.name AS status
     FROM aberp_rostered_shift s
     LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
     LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
     LEFT JOIN r_status rs ON rs.r_status_id = s.r_status_id
     WHERE s.isactive = 'Y'
       AND NOT EXISTS (
         SELECT 1 FROM aberp_rostered_shiftstaff ss
         WHERE ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id
           AND ss.isactive = 'Y'
           AND ss.c_bpartner_staff_id IS NOT NULL
       )
     ORDER BY s.starttime DESC NULLS LAST
     LIMIT 50`,
  );
  return result.rows.map(mapShiftRow);
}

export async function getMyShifts(
  cBPartnerStaffId: number,
  adUserId: number,
): Promise<ShiftRow[]> {
  const result = await pool.query(
    `SELECT
       s.aberp_rostered_shift_id AS id,
       s.documentno AS document_no,
       s.starttime AS start_time,
       s.endtime AS end_time,
       st.name AS shift_type,
       ml.name AS location,
       rs.name AS status,
       ss.aberp_requestshift AS request_status
     FROM aberp_rostered_shiftstaff ss
     JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id = ss.aberp_rostered_shift_id
     LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
     LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
     LEFT JOIN r_status rs ON rs.r_status_id = s.r_status_id
     WHERE ss.isactive = 'Y' AND s.isactive = 'Y'
       AND (ss.c_bpartner_staff_id = $1 OR ss.aberp_user_contact_id = $2)
     ORDER BY s.starttime DESC NULLS LAST
     LIMIT 50`,
    [cBPartnerStaffId, adUserId],
  );
  return result.rows.map(mapShiftRow);
}

export async function applyForShift(
  shiftId: number,
  cBPartnerStaffId: number,
  adUserId: number,
  adClientId: number,
): Promise<{ applied: boolean; message: string }> {
  const existing = await pool.query(
    `SELECT aberp_rostered_shiftstaff_id
     FROM aberp_rostered_shiftstaff
     WHERE aberp_rostered_shift_id = $1 AND isactive = 'Y'
       AND (c_bpartner_staff_id = $2 OR aberp_user_contact_id = $3)
     LIMIT 1`,
    [shiftId, cBPartnerStaffId, adUserId],
  );
  if (existing.rows.length > 0) {
    return { applied: false, message: "You have already applied or are assigned to this shift" };
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
