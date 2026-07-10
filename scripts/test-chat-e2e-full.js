/**
 * Full app ↔ iDempiere chat sync test (via API + DB-shaped officer reply).
 */
const http = require("http");
const { execSync } = require("child_process");

function request(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const req = http.request(
      {
        hostname: "127.0.0.1",
        port: 3001,
        path,
        method,
        headers: {
          "Content-Type": "application/json",
          ...(token ? { Authorization: "Bearer " + token } : {}),
          ...(data ? { "Content-Length": Buffer.byteLength(data) } : {}),
        },
      },
      (res) => {
        let raw = "";
        res.on("data", (c) => (raw += c));
        res.on("end", () => {
          let parsed = {};
          try {
            parsed = JSON.parse(raw);
          } catch {
            parsed = { raw };
          }
          resolve({ status: res.statusCode, body: parsed });
        });
      },
    );
    req.on("error", reject);
    if (data) req.write(data);
    req.end();
  });
}

function psql(sql) {
  return execSync(
    `sudo -u postgres psql -d idempiere -t -A -c "SET search_path TO adempiere; ${sql.replace(/"/g, '\\"')}"`,
    { encoding: "utf8" },
  ).trim();
}

(async () => {
  const stamp = Date.now();
  const workerMsg = `E2E worker msg ${stamp}`;
  const officerMsg = `E2E officer reply ${stamp}`;

  const login = await request("POST", "/api/auth/login", {
    username: "ewilliam",
    password: "flamingo",
  });
  if (!login.body.token) throw new Error("login failed");
  const token = login.body.token;

  let chat = await request("GET", "/api/requests/chat", null, token);
  if (chat.body.task?.is_closed) {
    chat = await request("POST", "/api/requests/chat", { body: `E2E open ${stamp}` }, token);
  }
  if (!chat.body.task?.id) throw new Error("no chat thread " + JSON.stringify(chat.body));
  const threadId = chat.body.task.id;
  console.log("thread", threadId, "closed", chat.body.task.is_closed);

  const send = await request(
    "POST",
    `/api/requests/${threadId}/messages`,
    { body: workerMsg },
    token,
  );
  console.log("worker send", send.status, send.body);
  if (send.status !== 200) throw new Error("worker send failed");

  const inDb = psql(
    `SELECT COUNT(*) FROM r_requestupdate WHERE r_request_id=${threadId} AND result='${workerMsg}'`,
  );
  console.log("worker msg in DB", inDb);
  if (inDb !== "1") throw new Error("worker message not in R_RequestUpdate");

  // Officer reply — same shape as SendRosteringReply SQL path
  const sql = `
SET search_path TO adempiere;
INSERT INTO r_requestupdate (
  r_requestupdate_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  r_request_id, result, confidentialtypeentry
) SELECT
  (SELECT COALESCE(MAX(r_requestupdate_id), 0) + 1 FROM r_requestupdate),
  r.ad_client_id, 0, 'Y', NOW(), 100, NOW(), 100,
  r.r_request_id, '${officerMsg}', 'C'
FROM r_request r WHERE r.r_request_id=${threadId};
UPDATE ad_sequence s
SET currentnext = GREATEST(s.currentnext, COALESCE((SELECT MAX(r_requestupdate_id)+s.incrementno FROM r_requestupdate), s.currentnext))
WHERE s.name = 'R_RequestUpdate';
UPDATE r_request SET lastresult='${officerMsg}', ad_role_id=0, aberp_rosteringreply=NULL,
  datelastaction=NOW(), updated=NOW(), updatedby=100
WHERE r_request_id=${threadId};
`;
  require("fs").writeFileSync("/tmp/e2e-officer-reply.sql", sql);
  execSync("sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f /tmp/e2e-officer-reply.sql", {
    stdio: "inherit",
  });

  const chat2 = await request("GET", "/api/requests/chat", null, token);
  const msgs = chat2.body.messages || [];
  const hasWorker = msgs.some((m) => m.body === workerMsg);
  const hasOfficer = msgs.some((m) => m.body === officerMsg && !m.is_mine);
  console.log("msgs", msgs.length, "hasWorker", hasWorker, "hasOfficer", hasOfficer);
  console.log("awaiting", chat2.body.task?.awaiting_reply_from);

  // Updates count for this thread only
  const updCount = psql(`SELECT COUNT(*) FROM r_requestupdate WHERE r_request_id=${threadId}`);
  console.log("updates for thread", updCount);

  if (!hasWorker || !hasOfficer) {
    console.log("FAIL sync", JSON.stringify(msgs.slice(-5), null, 2));
    process.exit(1);
  }
  console.log("PASS app ↔ DB chat sync for thread", threadId);
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
