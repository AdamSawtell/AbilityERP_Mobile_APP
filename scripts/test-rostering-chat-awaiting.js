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
      (res) => { let raw = ""; res.on("data", (c) => (raw += c)); res.on("end", () => resolve({ status: res.statusCode, body: JSON.parse(raw) })); },
    );
    req.on("error", reject);
    if (data) req.write(data);
    req.end();
  });
}
(async () => {
  const login = await request("POST", "/api/auth/login", { username: "ewilliam", password: "flamingo" });
  const chat = await request("GET", "/api/requests/chat", null, login.body.token);
  console.log("thread", chat.body.task?.id, "awaiting", chat.body.task?.awaiting_reply_from, "closed", chat.body.task?.is_closed);
  const send = await request("POST", `/api/requests/${chat.body.task.id}/messages`, { body: "E2E awaiting-reply test" }, login.body.token);
  console.log("send", send.status);
  const chat2 = await request("GET", "/api/requests/chat", null, login.body.token);
  console.log("after send awaiting", chat2.body.task?.awaiting_reply_from);
  console.log("PASS" , chat2.body.task?.awaiting_reply_from === "rostering" ? "worker->rostering queue" : "FAIL");
})();
