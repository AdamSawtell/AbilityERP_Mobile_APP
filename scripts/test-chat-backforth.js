/**
 * E2E: Rostering Chat back-and-forth (app worker ↔ officer SQL/triggers)
 * Run on EC2: node ~/test-chat-backforth.js
 */
const http = require("http");

const API = { hostname: "127.0.0.1", port: 3001 };
const WORKER = { username: "ewilliam", password: "flamingo" };

function req(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const headers = { "Content-Type": "application/json" };
    if (token) headers.Authorization = "Bearer " + token;
    if (data) headers["Content-Length"] = Buffer.byteLength(data);
    const r = http.request({ ...API, path, method, headers }, (res) => {
      let x = "";
      res.on("data", (c) => (x += c));
      res.on("end", () => {
        try {
          resolve({ status: res.statusCode, json: x ? JSON.parse(x) : null, raw: x });
        } catch {
          resolve({ status: res.statusCode, json: null, raw: x });
        }
      });
    });
    r.on("error", reject);
    if (data) r.write(data);
    r.end();
  });
}

async function psql(sql) {
  const { execSync } = require("child_process");
  const fs = require("fs");
  const f = "/tmp/e2e-chat.sql";
  fs.writeFileSync(f, "SET search_path TO adempiere, public;\n" + sql);
  return execSync(`sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f ${f}`, {
    encoding: "utf8",
  });
}

function assert(cond, msg) {
  if (!cond) throw new Error("FAIL: " + msg);
  console.log("  PASS:", msg);
}

(async () => {
  console.log("=== Login worker ===");
  const login = await req("POST", "/api/auth/login", WORKER);
  assert(login.status === 200 && login.json?.token, "worker login");
  const token = login.json.token;

  console.log("=== Get / start chat ===");
  let chat = await req("GET", "/api/requests/chat", null, token);
  assert(chat.status === 200, "get chat");
  let task = chat.json?.task;
  if (!task?.id || task.is_closed) {
    const created = await req("POST", "/api/requests/chat", { body: "E2E start " + Date.now() }, token);
    assert(created.status === 200 || created.status === 201, "start chat: " + (created.json?.error || created.status));
    chat = created;
    task = chat.json?.task;
  }
  const id = Number(task.id);
  console.log("thread", id, "awaiting", task.awaiting_reply_from);

  // Ensure open for officer reply tests
  await psql(`UPDATE r_request SET r_status_id=1000000, processed='N', aberp_rosteringreply=NULL WHERE r_request_id=${id};`);

  console.log("=== 1) Worker → officer ===");
  const w1 = "Worker ping " + Date.now();
  const send1 = await req("POST", `/api/requests/${id}/messages`, { body: w1 }, token);
  assert(send1.status === 200 || send1.status === 201, "worker send 1: " + (send1.json?.error || send1.status));

  let out = await psql(`
SELECT ad_role_id, LEFT(lastresult,80) FROM r_request WHERE r_request_id=${id};
SELECT r_requestupdate_id, LEFT(result,80), created
FROM r_requestupdate
WHERE r_request_id=${id} AND isactive='Y' AND COALESCE(confidentialtypeentry,'A')<>'C'
ORDER BY created ASC, r_requestupdate_id ASC;
`);
  assert(out.includes(w1), "worker msg in Updates");
  assert(out.includes("1000012"), "queued to rostering (Response required)");

  chat = await req("GET", "/api/requests/chat", null, token);
  let messages = chat.json.messages || [];
  let bodies = messages.map((m) => m.body);
  assert(bodies.includes(w1), "app shows worker msg");
  assert(chat.json.task.awaiting_reply_from === "rostering", "app awaiting rostering");

  console.log("=== 2) Officer reply via Reply trigger (Send path) ===");
  const o1 = "Officer reply " + Date.now();
  out = await psql(`
UPDATE r_request
SET aberp_rosteringreply = '${o1.replace(/'/g, "''")}',
    updated = NOW(),
    updatedby = 100
WHERE r_request_id = ${id};
SELECT ad_role_id, LEFT(lastresult,80), COALESCE(aberp_rosteringreply,'') FROM r_request WHERE r_request_id=${id};
SELECT LEFT(result,80), created FROM r_requestupdate
WHERE r_request_id=${id} AND isactive='Y' AND COALESCE(confidentialtypeentry,'A')<>'C'
ORDER BY created DESC LIMIT 3;
`);
  assert(out.includes(o1), "officer reply in lastresult/Updates");
  const roleLine = out.split("\n").find((l) => /^\s+\d+\s+\|/.test(l) || l.includes("|"));
  assert(/\|\s*0\s+\|/.test(out) || out.match(/\n\s+0\s+\|/), "ad_role_id=0 awaiting worker");

  chat = await req("GET", "/api/requests/chat", null, token);
  messages = chat.json.messages || [];
  bodies = messages.map((m) => m.body);
  assert(bodies.includes(o1), "app sees officer reply");
  assert(chat.json.task.awaiting_reply_from === "worker", "app awaiting worker");

  const times = messages.map((m) => m.created_at);
  const sorted = [...times].sort();
  assert(JSON.stringify(times) === JSON.stringify(sorted), "app messages in time order");

  console.log("=== 3) Worker again ===");
  const w2 = "Worker again " + Date.now();
  const send2 = await req("POST", `/api/requests/${id}/messages`, { body: w2 }, token);
  assert(send2.status === 200 || send2.status === 201, "worker send 2");
  chat = await req("GET", "/api/requests/chat", null, token);
  bodies = (chat.json.messages || []).map((m) => m.body);
  assert(bodies.includes(w2), "app has worker again");
  assert(chat.json.task.awaiting_reply_from === "rostering", "back to response required");

  console.log("=== 4) Officer second reply ===");
  const o2 = "Officer again " + Date.now();
  await psql(`UPDATE r_request SET aberp_rosteringreply='${o2.replace(/'/g, "''")}', updated=NOW(), updatedby=100 WHERE r_request_id=${id};`);
  chat = await req("GET", "/api/requests/chat", null, token);
  const finalBodies = (chat.json.messages || []).map((m) => m.body);
  assert(finalBodies.includes(o2), "app sees second officer reply");
  assert(chat.json.task.awaiting_reply_from === "worker", "awaiting worker after officer");

  const idx = (s) => finalBodies.indexOf(s);
  assert(idx(w1) >= 0 && idx(o1) > idx(w1) && idx(w2) > idx(o1) && idx(o2) > idx(w2), "full back/forth order w1<o1<w2<o2");

  console.log("\nALL E2E PASS on thread", id);
  console.log("messages:", finalBodies.length);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
