const http = require("http");
const { execSync } = require("child_process");

function req(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const headers = { "Content-Type": "application/json" };
    if (token) headers.Authorization = "Bearer " + token;
    if (data) headers["Content-Length"] = Buffer.byteLength(data);
    const r = http.request(
      { hostname: "127.0.0.1", port: 3001, path, method, headers },
      (res) => {
        let raw = "";
        res.on("data", (c) => (raw += c));
        res.on("end", () => {
          try {
            resolve({ status: res.statusCode, body: JSON.parse(raw) });
          } catch (e) {
            resolve({ status: res.statusCode, body: { raw } });
          }
        });
      },
    );
    r.on("error", reject);
    if (data) r.write(data);
    r.end();
  });
}

function sql(q) {
  return execSync(
    `sudo -u postgres psql -d idempiere -At -F '|' -c "SET search_path TO adempiere; ${q.replace(/"/g, '\\"')}"`,
    { encoding: "utf8" },
  ).trim();
}

(async () => {
  const login = await req("POST", "/api/auth/login", {
    username: "ewilliam",
    password: "flamingo",
  });
  if (login.status !== 200 || !login.body.token) {
    console.error("LOGIN_FAIL", login);
    process.exit(1);
  }
  const token = login.body.token;

  const before = sql(
    "SELECT lastresult || '~~' || ad_role_id || '~~' || updated FROM r_request WHERE r_request_id = 1000098",
  );
  const updatedBefore = before.split("~~")[2];
  console.log("BEFORE", before);

  const msg = "Worker after TZ fix " + Date.now();
  const send = await req("POST", "/api/requests/1000098/messages", { body: msg }, token);
  console.log("SEND", send.status, send.body?.id || send.body);

  const after = sql(
    "SELECT lastresult || '~~' || ad_role_id || '~~' || updated FROM r_request WHERE r_request_id = 1000098",
  );
  const parts = after.split("~~");
  console.log("AFTER", after);

  const chat = await req("GET", "/api/requests/chat", null, token);
  const messages = chat.body.messages || [];
  const last = messages[messages.length - 1];
  const bodies = messages.map((m) => (m.body || "").slice(0, 40));

  const updatedUnchanged = updatedBefore === parts[2];
  const lastresultOk = String(parts[0] || "").includes("Worker after TZ fix");
  const roleOk = Number(parts[1]) === 1000012;
  const timelineOk = last && String(last.body || "").includes("Worker after TZ fix");

  console.log("BODIES", bodies);
  console.log("LAST", last);
  console.log(
    JSON.stringify({
      updatedUnchanged,
      lastresultOk,
      roleOk,
      timelineOk,
      pass: updatedUnchanged && lastresultOk && roleOk && timelineOk,
    }),
  );
  process.exit(updatedUnchanged && lastresultOk && roleOk && timelineOk ? 0 : 1);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
