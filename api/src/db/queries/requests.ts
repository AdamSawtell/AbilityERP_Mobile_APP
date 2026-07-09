import { pool } from "../pool";
import { formatTimestamp, nextSequenceId } from "../helpers";

/** General worker → rostering request (not shift-specific). */
const WORKER_REQUEST_TYPE_ID = 1000000;
const ROSTERING_ROLE_ID = 1000012;
const REQUEST_STATUS_OPEN = 1000000;
const REQUEST_GROUP_ID = 1000003;
const REQUEST_CATEGORY_ID = 1000031;
const REQUEST_STATUS_CLOSED = 102;

async function getRosteringSalesRepId(): Promise<number> {
  const result = await pool.query<{ ad_user_id: number }>(
    `SELECT u.ad_user_id
     FROM ad_user u
     JOIN ad_user_roles ur ON ur.ad_user_id = u.ad_user_id AND ur.isactive = 'Y'
     WHERE ur.ad_role_id = $1 AND u.isactive = 'Y'
     ORDER BY u.ad_user_id ASC
     LIMIT 1`,
    [ROSTERING_ROLE_ID],
  );
  const id = result.rows[0]?.ad_user_id;
  if (!id) {
    throw new Error("No rostering officer user found");
  }
  return Number(id);
}

export interface TaskRow {
  id: number;
  document_no: string | null;
  summary: string | null;
  request_type: string | null;
  status: string | null;
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
    assigned_to_role: row.assigned_to_role,
    created_at: formatTimestamp(row.created_at),
    updated_at: formatTimestamp(row.updated_at),
    last_message: cleanRequestMessage(row.last_message ?? null),
    last_message_at: formatTimestamp(row.last_message_at),
  };
}

const STANDALONE_REQUEST_FILTER = `r.aberp_rostered_shift_id IS NULL`;

/** Strip iDempiere system lines appended to request update text. */
export function cleanRequestMessage(body: string | null): string | null {
  if (!body) return body;
  const trimmed = body.trim();
  const systemSplit = trimmed.split(/\n-\nRequest \d+ was /);
  const message = systemSplit[0]?.trim();
  return message || trimmed;
}

async function insertStandaloneRequest(
  adUserId: number,
  cBPartnerStaffId: number,
  adClientId: number,
  summary: string,
  firstMessage: string,
): Promise<number> {
  const requestId = await nextSequenceId("R_Request");
  const salesRepId = await getRosteringSalesRepId();
  const message = firstMessage.slice(0, 2000);

  await pool.query(
    `INSERT INTO r_request (
       r_request_id, ad_client_id, ad_org_id, isactive,
       created, createdby, updated, updatedby,
       documentno, r_requesttype_id, r_group_id, r_category_id, r_status_id,
       summary, priority, duetype, nextaction, confidentialtype, confidentialtypeentry,
       isselfservice, processed,
       ad_user_id, c_bpartner_id, ad_role_id, salesrep_id,
       datelastaction, lastresult
     ) VALUES (
       $1, $2, 0, 'Y',
       NOW(), $3, NOW(), $3,
       $13, $4, $5, $6, $7,
       $8, '5', '7', 'F', 'C', 'C', 'Y', 'N',
       $3, $9, $10, $11,
       NOW(), $12
     )`,
    [
      requestId,
      adClientId,
      adUserId,
      WORKER_REQUEST_TYPE_ID,
      REQUEST_GROUP_ID,
      REQUEST_CATEGORY_ID,
      REQUEST_STATUS_OPEN,
      summary,
      cBPartnerStaffId,
      ROSTERING_ROLE_ID,
      salesRepId,
      message,
      String(requestId),
    ],
  );

  const updateId = await nextSequenceId("R_RequestUpdate");
  await pool.query(
    `INSERT INTO r_requestupdate (
       r_requestupdate_id, ad_client_id, ad_org_id, isactive,
       created, createdby, updated, updatedby,
       r_request_id, result, confidentialtypeentry
     ) VALUES ($1, $2, 0, 'Y', NOW(), $3, NOW(), $3, $4, $5, 'C')`,
    [updateId, adClientId, adUserId, requestId, message],
  );

  return requestId;
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
       COALESCE(role.name, 'Rostering Officer') AS assigned_to_role,
       r.created AS created_at,
       r.updated AS updated_at,
       (
         SELECT ru.result FROM r_requestupdate ru
         WHERE ru.r_request_id = r.r_request_id AND ru.isactive = 'Y'
         ORDER BY ru.created DESC LIMIT 1
       ) AS last_message,
       (
         SELECT ru.created FROM r_requestupdate ru
         WHERE ru.r_request_id = r.r_request_id AND ru.isactive = 'Y'
         ORDER BY ru.created DESC LIMIT 1
       ) AS last_message_at
     FROM r_request r
     LEFT JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
     LEFT JOIN r_status rs ON rs.r_status_id = r.r_status_id
     LEFT JOIN ad_role role ON role.ad_role_id = r.ad_role_id
     WHERE r.isactive = 'Y'
       AND ${STANDALONE_REQUEST_FILTER}
       AND (r.ad_user_id = $1 OR r.c_bpartner_id = $2)
     ORDER BY COALESCE(
       (SELECT MAX(ru.created) FROM r_requestupdate ru WHERE ru.r_request_id = r.r_request_id),
       r.updated, r.created
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
       COALESCE(role.name, 'Rostering Officer') AS assigned_to_role,
       r.created AS created_at,
       r.updated AS updated_at
     FROM r_request r
     LEFT JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
     LEFT JOIN r_status rs ON rs.r_status_id = r.r_status_id
     LEFT JOIN ad_role role ON role.ad_role_id = r.ad_role_id
     WHERE r.r_request_id = $1
       AND r.isactive = 'Y'
       AND ${STANDALONE_REQUEST_FILTER}
       AND (r.ad_user_id = $2 OR r.c_bpartner_id = $3)
     LIMIT 1`,
    [requestId, adUserId, cBPartnerStaffId],
  );

  const row = result.rows[0];
  return row ? mapTaskRow(row) : null;
}

export async function getOrCreateRosteringChat(
  adUserId: number,
  cBPartnerStaffId: number,
  adClientId: number,
): Promise<TaskRow> {
  const existing = await pool.query(
    `SELECT r.r_request_id AS id
     FROM r_request r
     WHERE r.isactive = 'Y'
       AND ${STANDALONE_REQUEST_FILTER}
       AND (r.ad_user_id = $1 OR r.c_bpartner_id = $2)
       AND r.r_status_id <> $3
     ORDER BY COALESCE(
       (SELECT MAX(ru.created) FROM r_requestupdate ru WHERE ru.r_request_id = r.r_request_id),
       r.updated,
       r.created
     ) DESC
     LIMIT 1`,
    [adUserId, cBPartnerStaffId, REQUEST_STATUS_CLOSED],
  );

  let requestId = existing.rows[0]?.id ? Number(existing.rows[0].id) : null;
  if (!requestId) {
    requestId = await insertStandaloneRequest(
      adUserId,
      cBPartnerStaffId,
      adClientId,
      "Message to Rostering",
      "Hello — I would like to get in touch with rostering.",
    );
  }

  const task = await getWorkerTask(requestId, adUserId, cBPartnerStaffId);
  if (!task) {
    throw new Error("Failed to open rostering chat");
  }
  return task;
}

export async function createStandaloneRequest(
  adUserId: number,
  cBPartnerStaffId: number,
  adClientId: number,
  data: { summary?: string; body: string },
): Promise<{ id: number }> {
  const summary = (data.summary?.trim() || "Message to Rostering").slice(0, 255);
  const body = data.body.trim();
  if (!body) {
    throw new Error("Message cannot be empty");
  }

  const id = await insertStandaloneRequest(adUserId, cBPartnerStaffId, adClientId, summary, body);
  return { id };
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
    body: cleanRequestMessage(row.body),
    author_name: row.author_name,
    author_id: row.author_id ? Number(row.author_id) : null,
    is_mine: row.author_id ? Number(row.author_id) === adUserId : false,
    created_at: formatTimestamp(row.created_at),
  }));
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
