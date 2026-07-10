import { pool } from "../pool";
import { formatTimestamp, nextSequenceId } from "../helpers";

/** Dedicated request type for mobile worker ↔ rostering chat (see install-rostering-chat.sql). */
const ROSTERING_CHAT_REQUEST_TYPE_NAME = "Rostering Chat";
const ROSTERING_CHAT_TYPE_FILTER = `r.r_requesttype_id = (
  SELECT r_requesttype_id FROM r_requesttype
  WHERE name = '${ROSTERING_CHAT_REQUEST_TYPE_NAME}' AND isactive = 'Y'
  LIMIT 1
)`;
const ROSTERING_ROLE_ID = 1000012;
const REQUEST_STATUS_OPEN = 1000000;
const REQUEST_GROUP_ID = 1000003;
const REQUEST_CATEGORY_ID = 1000031;
/** Fallback Closed status id — prefer resolveClosedStatusId() at runtime. */
const REQUEST_STATUS_CLOSED_FALLBACK = 102;

async function resolveClosedStatusId(): Promise<number> {
  const result = await pool.query<{ r_status_id: number }>(
    `SELECT r_status_id
     FROM r_status
     WHERE isactive = 'Y' AND LOWER(name) = 'closed'
     ORDER BY r_status_id ASC
     LIMIT 1`,
  );
  return result.rows[0]?.r_status_id
    ? Number(result.rows[0].r_status_id)
    : REQUEST_STATUS_CLOSED_FALLBACK;
}

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
  is_closed: boolean;
  /** Who should respond next: rostering officer, worker, or null when closed. */
  awaiting_reply_from: "rostering" | "worker" | null;
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
  r_status_id?: number | null;
  ad_role_id?: number | null;
}): TaskRow {
  const statusName = (row.status ?? "").trim().toLowerCase();
  const isClosed =
    statusName === "closed" ||
    (row.r_status_id != null && Number(row.r_status_id) === REQUEST_STATUS_CLOSED_FALLBACK);
  const queuedToRostering =
    row.ad_role_id != null && Number(row.ad_role_id) === ROSTERING_ROLE_ID;

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
    is_closed: isClosed,
    awaiting_reply_from: isClosed ? null : queuedToRostering ? "rostering" : "worker",
  };
}

const STANDALONE_REQUEST_FILTER = ROSTERING_CHAT_TYPE_FILTER;

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
  const requestId = await nextSequenceId("R_Request", "r_request", "r_request_id");
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
       $12, (SELECT r_requesttype_id FROM r_requesttype WHERE name = $13 AND isactive = 'Y' LIMIT 1), $4, $5, $6,
       $7, '5', '7', 'F', 'C', 'C', 'Y', 'N',
       $3, $8, $9, $10,
       NOW(), $11
     )`,
    [
      requestId,
      adClientId,
      adUserId,
      REQUEST_GROUP_ID,
      REQUEST_CATEGORY_ID,
      REQUEST_STATUS_OPEN,
      summary,
      cBPartnerStaffId,
      ROSTERING_ROLE_ID,
      salesRepId,
      message,
      String(requestId),
      ROSTERING_CHAT_REQUEST_TYPE_NAME,
    ],
  );

  const updateId = await nextSequenceId("R_RequestUpdate", "r_requestupdate", "r_requestupdate_id");
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
       r.r_status_id,
       r.ad_role_id,
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
       r.updated AS updated_at,
       r.r_status_id,
       r.ad_role_id
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

export async function getRosteringChatState(
  adUserId: number,
  cBPartnerStaffId: number,
  adClientId: number,
): Promise<{ task: TaskRow | null; messages: TaskMessageRow[] }> {
  const closedStatusId = await resolveClosedStatusId();
  const open = await pool.query(
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
    [adUserId, cBPartnerStaffId, closedStatusId],
  );

  let requestId = open.rows[0]?.id ? Number(open.rows[0].id) : null;

  if (!requestId) {
    const anyThread = await pool.query(
      `SELECT COUNT(*)::int AS total
       FROM r_request r
       WHERE r.isactive = 'Y'
         AND ${STANDALONE_REQUEST_FILTER}
         AND (r.ad_user_id = $1 OR r.c_bpartner_id = $2)`,
      [adUserId, cBPartnerStaffId],
    );
    const hasHistory = Number(anyThread.rows[0]?.total ?? 0) > 0;

    if (!hasHistory) {
      requestId = await insertStandaloneRequest(
        adUserId,
        cBPartnerStaffId,
        adClientId,
        "Message to Rostering",
        "Hello — I would like to get in touch with rostering.",
      );
    } else {
      const closed = await pool.query(
        `SELECT r.r_request_id AS id
         FROM r_request r
         WHERE r.isactive = 'Y'
           AND ${STANDALONE_REQUEST_FILTER}
           AND (r.ad_user_id = $1 OR r.c_bpartner_id = $2)
           AND r.r_status_id = $3
         ORDER BY COALESCE(
           (SELECT MAX(ru.created) FROM r_requestupdate ru WHERE ru.r_request_id = r.r_request_id),
           r.updated,
           r.created
         ) DESC
         LIMIT 1`,
        [adUserId, cBPartnerStaffId, closedStatusId],
      );
      requestId = closed.rows[0]?.id ? Number(closed.rows[0].id) : null;
    }
  }

  if (!requestId) {
    return { task: null, messages: [] };
  }

  const task = await getWorkerTask(requestId, adUserId, cBPartnerStaffId);
  if (!task) {
    return { task: null, messages: [] };
  }

  const messages = await getTaskMessages(requestId, adUserId, cBPartnerStaffId);
  return { task, messages };
}

/** @deprecated use getRosteringChatState */
export async function getOrCreateRosteringChat(
  adUserId: number,
  cBPartnerStaffId: number,
  adClientId: number,
): Promise<TaskRow> {
  const { task } = await getRosteringChatState(adUserId, cBPartnerStaffId, adClientId);
  if (!task) {
    throw new Error("No chat thread available");
  }
  return task;
}

export async function startRosteringChat(
  adUserId: number,
  cBPartnerStaffId: number,
  adClientId: number,
  firstMessage?: string,
): Promise<TaskRow> {
  const closedStatusId = await resolveClosedStatusId();
  const open = await pool.query(
    `SELECT r.r_request_id AS id
     FROM r_request r
     WHERE r.isactive = 'Y'
       AND ${STANDALONE_REQUEST_FILTER}
       AND (r.ad_user_id = $1 OR r.c_bpartner_id = $2)
       AND r.r_status_id <> $3
     LIMIT 1`,
    [adUserId, cBPartnerStaffId, closedStatusId],
  );
  if (open.rows[0]?.id) {
    throw new Error("You already have an open chat with rostering");
  }

  const message =
    firstMessage?.trim() ||
    "Hello — I would like to get in touch with rostering.";
  const requestId = await insertStandaloneRequest(
    adUserId,
    cBPartnerStaffId,
    adClientId,
    "Message to Rostering",
    message,
  );

  const task = await getWorkerTask(requestId, adUserId, cBPartnerStaffId);
  if (!task) {
    throw new Error("Failed to start rostering chat");
  }
  return task;
}

export async function closeRosteringChat(
  requestId: number,
  adUserId: number,
  cBPartnerStaffId: number,
): Promise<TaskRow | null> {
  const task = await getWorkerTask(requestId, adUserId, cBPartnerStaffId);
  if (!task) return null;
  if (task.is_closed) {
    throw new Error("This chat is already closed");
  }

  const closedStatusId = await resolveClosedStatusId();
  await pool.query(
    `UPDATE r_request
     SET r_status_id = $2,
         ad_role_id = 0,
         updated = NOW(),
         updatedby = $3,
         datelastaction = NOW(),
         lastresult = COALESCE(lastresult, 'Chat closed')
     WHERE r_request_id = $1`,
    [requestId, closedStatusId, adUserId],
  );

  return getWorkerTask(requestId, adUserId, cBPartnerStaffId);
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
  if (task.is_closed) {
    throw new Error("This chat is closed. Start a new conversation to continue.");
  }

  const trimmed = body.trim();
  if (!trimmed) {
    throw new Error("Message cannot be empty");
  }

  const updateId = await nextSequenceId(
    "R_RequestUpdate",
    "r_requestupdate",
    "r_requestupdate_id",
  );
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
     SET updated = NOW(),
         updatedby = $2,
         datelastaction = NOW(),
         lastresult = $3,
         ad_role_id = $4,
         ad_user_id = $2
     WHERE r_request_id = $1`,
    [requestId, adUserId, trimmed, ROSTERING_ROLE_ID],
  );

  return { id: updateId };
}
