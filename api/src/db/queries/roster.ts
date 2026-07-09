import { pool } from "../pool";
import { formatTimestamp } from "../helpers";

export interface RosterShiftRow {
  id: number;
  document_no: string | null;
  start_time: string | null;
  end_time: string | null;
  shift_type: string | null;
  location: string | null;
  staff_name: string | null;
}

export interface RosterTemplateRow {
  id: number;
  name: string;
  value: string | null;
}

function mapRosterShift(row: {
  id: number;
  document_no: string | null;
  start_time: unknown;
  end_time: unknown;
  shift_type: string | null;
  location: string | null;
  staff_name: string | null;
}): RosterShiftRow {
  return {
    id: row.id,
    document_no: row.document_no,
    start_time: formatTimestamp(row.start_time),
    end_time: formatTimestamp(row.end_time),
    shift_type: row.shift_type,
    location: row.location,
    staff_name: row.staff_name,
  };
}

export async function getCurrentRoster(): Promise<RosterShiftRow[]> {
  const result = await pool.query(
    `SELECT
       s.aberp_rostered_shift_id AS id,
       s.documentno AS document_no,
       s.starttime AS start_time,
       s.endtime AS end_time,
       st.name AS shift_type,
       ml.name AS location,
       bp.name AS staff_name
     FROM aberp_rostered_shift s
     LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
     LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
     LEFT JOIN aberp_rostered_shiftstaff ss
       ON ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id AND ss.isactive = 'Y'
     LEFT JOIN c_bpartner bp ON bp.c_bpartner_id = ss.c_bpartner_staff_id
     WHERE s.isactive = 'Y'
     ORDER BY s.starttime DESC NULLS LAST
     LIMIT 100`,
  );
  return result.rows.map(mapRosterShift);
}

export async function getMasterRoster(): Promise<RosterTemplateRow[]> {
  const result = await pool.query<RosterTemplateRow>(
    `SELECT
       t.aberp_rostered_shifttemplate_id AS id,
       t.name,
       t.value
     FROM aberp_rostered_shifttemplate t
     WHERE t.isactive = 'Y'
     ORDER BY t.name ASC
     LIMIT 100`,
  );
  return result.rows;
}
