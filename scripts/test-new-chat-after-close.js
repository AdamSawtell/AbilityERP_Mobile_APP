const http = require("http");
function request(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const req = http.request(
      { hostname: "127.0.0.1", port: 3001, path, method, headers: {
        "Content-Type": "application/json",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(data ? { "Content-Length": Buffer.byteLength(data) } : {}),
      }},
      (res) => { let raw = ""; res.on("data", (c) => (raw += c)); res.on("end", () => {
        let parsed = {};
        try { parsed = JSON.parse(raw); } catch { parsed = { raw }; }
        resolve({ status: res.statusCode, body: parsed });
      }); },
    );
    req.on("error", reject);
    if (data) req.write(data);
    req.end();
  });
}
(async () => {
  const login = await request("POST", "/api/auth/login", { username: "ewilliam", password: "flamingo" });
  if (!login.body.token) throw new Error("login failed " + JSON.stringify(login.body));
  const token = login.body.token;

  let chat = await request("GET", "/api/requests/chat", null, token);
  console.log("before", chat.body.task?.id, "closed", chat.body.task?.is_closed);

  if (chat.body.task && !chat.body.task.is_closed) {
    const closed = await request("POST", `/api/requests/${chat.body.task.id}/close`, {}, token);
    console.log("close", closed.status, closed.body.task?.id, closed.body.task?.is_closed, closed.body.error);
  }

  const started = await request("POST", "/api/requests/chat", { body: "New chat after close — unique id test" }, token);
  console.log("start", started.status, started.body.task?.id, started.body.error || started.body.task?.is_closed);
  if (started.status !== 200 || !started.body.task?.id) {
    console.log("FAIL start new chat", JSON.stringify(started.body));
    process.exit(1);
  }
  console.log("PASS new chat id", started.body.task.id);
})();
