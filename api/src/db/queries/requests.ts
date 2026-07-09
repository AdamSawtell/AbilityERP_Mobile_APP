import { pool } from "../pool";
import { formatTimestamp, nextSequenceId } from "../helpers";

const SHIFT_REQUEST_TYPE_ID = 1000011;
const ROSTERING_ROLE_ID = 1000012;
const REQUEST_STATUS_OPEN = 1000000;
const REQUEST_GROUP_ID = 1000003;
const REQUEST_CATEGORY_ID = 1000031;

export interface TaskRow {
  id: number;
  document_no: string | null;
  summary: string | null;
  request_type: string | null;
  status: string | null;
  shift_id: number | null;
  shift_document_no: string | null;
  assigned_to_role: string | null;
  created_at: string | null;
  updated_at: string | null;
  last_message: string | null;
  last_message_at: string | null;
}

export interface TaskMessageRow {
  id: number;
  body: string | null;
  author_name: string | null;
  author_id: number | null;
  is_mine: boolean;
  created_at: string | null;
}

function mapTaskRow(row: {
  id: number;
  document_no: string | null;
  summary: string | null;
  request_type: string | null;
  status: string | null;
  shift_id: number | null;
  shift_document_no: string | null;
  assigned_to_role: string | null;
  created_at: unknown;
  updated_at: unknown;
  last_message?: string | null;
  last_message_at?: unknown;
}): TaskRow {
  return {
    id: row.id,
    document_no: row.document_no,
    summary: row.summary,
    request_type: row.request_type,
    status: row.status,
    shift_id: row.shift_id,
    shift_document_no: row.shift_document_no,
    assigned_to_role: row.assigned_to_role,
    created_at: formatTimestamp(row.created_at),
    updated_at: formatTimestamp(row.updated_at),
    last_message: row.last_message ?? null,
    last_message_at: formatTimestamp(row.last_message_at),
  };
}

export async function getWorkerTasks(
  adUserId: number,
  cBPartnerStaffId: number,
): Promise<TaskRow[]> {
  const result = await pool.query(
    `SELECT
       r.r_request_id AS id,
       r.documentno AS document_no,
       r.summary,
       rt.name AS request_type,
       rs.name AS status,
       r.aberp_rostered_shift_id AS shift_id,
       s.documentno AS shift_document_no,
       role.name AS assigned_to_role,
       r.created AS created_at,
       r.updated AS updated_at,
       (
         SELECT ru.result
         FROM r_requestupdate ru
         WHERE ru.r_request_id = r.r_request_id AND ru.isactive = 'Y'
         ORDER BY ru.created DESC
         LIMIT 1
       ) AS last_message,
       (
         SELECT ru.created
         FROM r_requestupdate ru
         WHERE ru.r_request_id = r.r_request_id AND ru.isactive = 'Y'
         ORDER BY ru.created DESC
         LIMIT 1
       ) AS last_message_at
     FROM r_request r
     LEFT JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
     LEFT JOIN r_status rs ON rs.r_status_id = r.r_status_id
     LEFT JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id = r.aberp_rostered_shift_id
     LEFT JOIN ad_role role ON role.ad_role_id = r.ad_role_id
     WHERE r.isactive = 'Y'
       AND (r.ad_user_id = $1 OR r.c_bpartner_id = $2)
     ORDER BY COALESCE(
       (SELECT MAX(ru.created) FROM r_requestupdate ru WHERE ru.r_request_id = r.r_request_id),
       r.updated,
       r.created
     ) DESC
     LIMIT 100`,
    [adUserId, cBPartnerStaffId],
  );

  return result.rows.map(mapTaskRow);
}

export async function getWorkerTask(
  requestId: number,
  adUserId: number,
  cBPartnerStaffId: number,
): Promise<TaskRow | null> {
  const result = await pool.query(
    `SELECT
       r.r_request_id AS id,
       r.documentno AS document_no,
       r.summary,
       rt.name AS request_type,
       rs.name AS status,
       r.aberp_rostered_shift_id AS shift_id,
       s.documentno AS shift_document_no,
       role.name AS assigned_to_role,
       r.created AS created_at,
       r.updated AS updated_at
     FROM r_request r
     LEFT JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
     LEFT JOIN r_status rs ON rs.r_status_id = r.r_status_id
     LEFT JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id = r.aberp_rostered_shift_id
     LEFT JOIN ad_role role ON role.ad_role_id = r.ad_role_id
     WHERE r.r_request_id = $1
       AND r.isactive = 'Y'
       AND (r.ad_user_id = $2 OR r.c_bpartner_id = $3)
     LIMIT 1`,
    [requestId, adUserId, cBPartnerStaffId],
  );

  const row = result.rows[0];
  return row ? mapTaskRow(row) : null;
}

export async function getTaskByShiftId(
  shiftId: number,
  adUserId: number,
  cBPartnerStaffId: number,
): Promise<TaskRow | null> {
  const result = await pool.query(
    `SELECT r_request_id AS id FROM r_request
     WHERE isactive = 'Y'
       AND aberp_rostered_shift_id = $1
       AND (ad_user_id = $2 OR c_bpartner_id = $3)
     ORDER BY created DESC
     LIMIT 1`,
    [shiftId, adUserId, cBPartnerStaffId],
  );
  const id = result.rows[0]?.id;
  if (!id) return null;
  return getWorkerTask(Number(id), adUserId, cBPartnerStaffId);
}

export async function getTaskMessages(
  requestId: number,
  adUserId: number,
  cBPartnerStaffId: number,
): Promise<TaskMessageRow[]> {
  const task = await getWorkerTask(requestId, adUserId, cBPartnerStaffId);
  if (!task) return [];

  const result = await pool.query(
    `SELECT
       ru.r_requestupdate_id AS id,
       ru.result AS body,
       u.name AS author_name,
       ru.createdby AS author_id,
       ru.created AS created_at
     FROM r_requestupdate ru
     LEFT JOIN ad_user u ON u.ad_user_id = ru.createdby
     WHERE ru.r_request_id = $1 AND ru.isactive = 'Y'
     ORDER BY ru.created ASC
     LIMIT 200`,
    [requestId],
  );

  return result.rows.map((row) => ({
    id: Number(row.id),
    body: row.body,
    author_name: row.author_name,
    author_id: row.author_id ? Number(row.author_id) : null,
    is_mine: row.author_id ? Number(row.author_id) === adUserId : false,
    created_at: formatTimestamp(row.created_at),
  }));
}

async function getShiftSummary(shiftId: number): Promise<string | null> {
  const result = await pool.query<{ documentno: string | null; shift_type: string | null }>(
    `SELECT s.documentno, st.name AS shift_type
     FROM aberp_rostered_shift s
     LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
     WHERE s.aberp_rostered_shift_id = $1
     LIMIT 1`,
    [shiftId],
  );
  const row = result.rows[0];
  if (!row) return null;
  const parts = [row.documentno, row.shift_type].filter(Boolean);
  return parts.length ? parts.join(" — ") : `Shift ${shiftId}`;
}

export async function findOpenShiftTaskId(
  shiftId: number,
  adUserId: number,
  cBPartnerStaffId: number,
): Promise<number | null> {
  const result = await pool.query<{ id: number }>(
    `SELECT r_request_id AS id
     FROM r_request
     WHERE isactive = 'Y'
       AND aberp_rostered_shift_id = $1
       AND (ad_user_id = $2 OR c_bpartner_id = $3)
       AND r_status_id <> 102
     ORDER BY created DESC
     LIMIT 1`,
    [shiftId, adUserId, cBPartnerStaffId],
  );
  return result.rows[0]?.id ? Number(result.rows[0].id) : null;
}

export async function addTaskMessage(
  requestId: number,
  adUserId: number,
  cBPartnerStaffId: number,
  adClientId: number,
  body: string,
): Promise<{ id: number } | null> {
  const task = await getWorkerTask(requestId, adUserId, cBPartnerStaffId);
  if (!task) return null;

  const trimmed = body.trim();
  if (!trimmed) {
    throw new Error("Message cannot be empty");
  }

  const updateId = await nextSequenceId("R_RequestUpdate");
  await pool.query(
    `INSERT INTO r_requestupdate (
       r_requestupdate_id, ad_client_id, ad_org_id, isactive,
       created, createdby, updated, updatedby,
       r_request_id, result, confidentialtypeentry
     ) VALUES (
       $1, $2, 0, 'Y',
       NOW(), $3, NOW(), $3,
       $4, $5, 'C'
     )`,
    [updateId, adClientId, adUserId, requestId, trimmed],
  );

  await pool.query(
    `UPDATE r_request
     SET updated = NOW(), updatedby = $2, datelastaction = NOW(), lastresult = $3
     WHERE r_request_id = $1`,
    [requestId, adUserId, trimmed],
  );

  return { id: updateId };
}

export async function ensureShiftRequestTask(
  shiftId: number,
  adUserId: number,
  cBPartnerStaffId: number,
  adClientId: number,
  response: "REQ" | "DEC",
  note?: string,
): Promise<{ requestId: number; created: boolean }> {
  const existingId = await findOpenShiftTaskId(shiftId, adUserId, cBPartnerStaffId);
  const shiftLabel = (await getShiftSummary(shiftId)) ?? `Shift ${shiftId}`;
  const defaultNote =
    response === "REQ"
      ? `I would like to request shift ${shiftLabel}.`
      : `I am declining shift ${shiftLabel}.`;
  const message = (note?.trim() || defaultNote).slice(0, 2000);

  if (existingId) {
    await addTaskMessage(existingId, adUserId, cBPartnerStaffId, adClientId, message);
    return { requestId: existingId, created: false };
  }

  const requestId = await nextSequenceId("R_Request");
  const summary =
    response === "REQ" ? `Shift request — ${shiftLabel}` : `Shift decline — ${shiftLabel}`;

  await pool.query(
    `INSERT INTO r_request (
       r_request_id, ad_client_id, ad_org_id, isactive,
       created, createdby, updated, updatedby,
       documentno, r_requesttype_id, r_group_id, r_category_id, r_status_id,
       summary, priority, confidentialtype, isselfservice, processed,
       ad_user_id, c_bpartner_id, ad_role_id, aberp_rostered_shift_id,
       datelastaction, lastresult
     ) VALUES (
       $1, $2, 0, 'Y',
       NOW(), $3, NOW(), $3,
       $1::varchar, $4, $5, $6, $7,
       $8, '5', 'C', 'Y', 'N',
       $3, $9, $10, $11,
       NOW(), $12
     )`,
    [
      requestId,
      adClientId,
      adUserId,
      SHIFT_REQUEST_TYPE_ID,
      REQUEST_GROUP_ID,
      REQUEST_CATEGORY_ID,
      REQUEST_STATUS_OPEN,
      summary,
      cBPartnerStaffId,
      ROSTERING_ROLE_ID,
      shiftId,
      message,
    ],
  );

  await addTaskMessage(requestId, adUserId, cBPartnerStaffId, adClientId, message);
  return { requestId, created: true };
}
