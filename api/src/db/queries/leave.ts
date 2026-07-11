import { pool } from "../pool";
import { formatTimestamp, nextSequenceId } from "../helpers";

export interface LeaveRow {
  id: number;
  start_date: string | null;
  end_date: string | null;
  note: string | null;
  leave_type: string | null;
  submitter_status: string | null;
  approver_status: string | null;
}

export async function getLeaveRecords(
  cBPartnerStaffId: number,
  adUserId: number,
): Promise<LeaveRow[]> {
  const result = await pool.query<{
    id: number;
    start_date: unknown;
    end_date: unknown;
    note: string | null;
    leave_type: string | null;
    submitter_status: string | null;
    approver_status: string | null;
  }>(
    `SELECT
       l.aberp_unavailability_leave_id AS id,
       l.startdate AS start_date,
       l.enddate AS end_date,
       l.note,
       ut.name AS leave_type,
       COALESCE(ss.name, l.aberp_submitterstatus) AS submitter_status,
       COALESCE(as_.name, l.aberp_approverstatus) AS approver_status
     FROM aberp_unavailability_leave l
     LEFT JOIN aberp_unavailability_type ut ON ut.aberp_unavailability_type_id = l.aberp_unavailability_type_id
     LEFT JOIN ad_ref_list ss
       ON ss.value = l.aberp_submitterstatus
      AND ss.ad_reference_id = (
        SELECT ad_reference_id FROM ad_reference WHERE name = 'AbERP_SubmitterStatus_List' LIMIT 1
      )
     LEFT JOIN ad_ref_list as_
       ON as_.value = l.aberp_approverstatus
      AND as_.ad_reference_id = (
        SELECT ad_reference_id FROM ad_reference WHERE name = 'AbERP_ApproverStatus_List' LIMIT 1
      )
     WHERE l.isactive = 'Y'
       AND (l.c_bpartner_staff_id = $1 OR l.aberp_user_contact_id = $2)
     ORDER BY l.startdate DESC NULLS LAST
     LIMIT 50`,
    [cBPartnerStaffId, adUserId],
  );

  return result.rows.map((row) => ({
    id: row.id,
    start_date: formatTimestamp(row.start_date),
    end_date: formatTimestamp(row.end_date),
    note: row.note,
    leave_type: row.leave_type,
    submitter_status: row.submitter_status,
    approver_status: row.approver_status,
  }));
}

export async function createLeaveRequest(
  cBPartnerStaffId: number,
  adUserId: number,
  adClientId: number,
  data: { startDate: string; endDate: string; note?: string },
): Promise<{ id: number }> {
  const leaveType = await pool.query<{ id: number }>(
    `SELECT aberp_unavailability_type_id AS id
     FROM aberp_unavailability_type
     WHERE isactive = 'Y'
     ORDER BY aberp_unavailability_type_id ASC
     LIMIT 1`,
  );
  const typeId = leaveType.rows[0]?.id ?? null;
  const newId = await nextSequenceId("AbERP_Unavailability_Leave");

  if (!typeId) {
    throw new Error("No active leave type configured");
  }

  await pool.query(
    `INSERT INTO aberp_unavailability_leave (
       aberp_unavailability_leave_id, ad_client_id, ad_org_id, isactive,
       created, createdby, updated, updatedby,
       c_bpartner_staff_id, aberp_user_contact_id,
       startdate, enddate, note, aberp_unavailability_type_id,
       aberp_submitterstatus, aberp_approverstatus,
       aberp_issubmitleaveclicked, processed
     ) VALUES (
       $1, $2, 0, 'Y',
       NOW(), $3, NOW(), $3,
       $4, $3,
       $5::timestamp, $6::timestamp, $7, $8,
       'SB', 'RV',
       'Y', 'N'
     )`,
    [
      newId,
      adClientId,
      adUserId,
      cBPartnerStaffId,
      data.startDate,
      data.endDate,
      data.note ?? null,
      typeId,
    ],
  );

  return { id: newId };
}
