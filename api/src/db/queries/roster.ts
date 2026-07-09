import { pool } from "../pool";
import { formatTimestamp } from "../helpers";

export interface MasterRosterTemplate {
  id: number;
  name: string;
  value: string | null;
}

export interface MasterRosterLine {
  id: number;
  document_no: string | null;
  template_id: number | null;
  template_name: string | null;
  template_code: string | null;
  roster_start_day: number | null;
  roster_end_day: number | null;
  start_time: string | null;
  end_time: string | null;
  shift_type: string | null;
  location: string | null;
}

export interface EmployeeMasterRoster {
  templates: MasterRosterTemplate[];
  items: MasterRosterLine[];
}

function mapLine(row: {
  id: number;
  document_no: string | null;
  template_id: number | null;
  template_name: string | null;
  template_code: string | null;
  roster_start_day: number | null;
  roster_end_day: number | null;
  start_time: unknown;
  end_time: unknown;
  shift_type: string | null;
  location: string | null;
}): MasterRosterLine {
  return {
    id: row.id,
    document_no: row.document_no,
    template_id: row.template_id,
    template_name: row.template_name,
    template_code: row.template_code,
    roster_start_day: row.roster_start_day,
    roster_end_day: row.roster_end_day,
    start_time: formatTimestamp(row.start_time),
    end_time: formatTimestamp(row.end_time),
    shift_type: row.shift_type,
    location: row.location,
  };
}

export async function getEmployeeMasterRoster(
  cBPartnerStaffId: number,
  adUserId: number,
): Promise<EmployeeMasterRoster> {
  const result = await pool.query(
    `SELECT
       s.aberp_rostered_shift_id AS id,
       s.documentno AS document_no,
       t.aberp_rostered_shifttemplate_id AS template_id,
       t.name AS template_name,
       t.value AS template_code,
       NULLIF(s.aberp_rosterstartday, '')::int AS roster_start_day,
       NULLIF(s.aberp_rosterendday, '')::int AS roster_end_day,
       s.starttime AS start_time,
       s.endtime AS end_time,
       st.name AS shift_type,
       ml.name AS location
     FROM aberp_rostered_shift s
     JOIN aberp_rostered_shiftstaff ss
       ON ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id
     LEFT JOIN aberp_rostered_shifttemplate t
       ON t.aberp_rostered_shifttemplate_id = s.aberp_rostered_shifttemplate_id
     LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
     LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
     WHERE s.isactive = 'Y'
       AND ss.isactive = 'Y'
       AND s.aberp_isshiftrosteredtemplate = 'Y'
       AND (ss.c_bpartner_staff_id = $1 OR ss.aberp_user_contact_id = $2)
       AND NULLIF(s.aberp_rosterstartday, '')::int BETWEEN 1 AND 14
     ORDER BY NULLIF(s.aberp_rosterstartday, '')::int ASC,
       s.starttime::time ASC NULLS LAST,
       s.aberp_rostered_shift_id ASC
     LIMIT 200`,
    [cBPartnerStaffId, adUserId],
  );

  const items = result.rows.map(mapLine);
  const templateMap = new Map<number, MasterRosterTemplate>();

  for (const item of items) {
    if (item.template_id && !templateMap.has(item.template_id)) {
      templateMap.set(item.template_id, {
        id: item.template_id,
        name: item.template_name ?? "Master roster",
        value: item.template_code,
      });
    }
  }

  return {
    templates: Array.from(templateMap.values()),
    items,
  };
}
