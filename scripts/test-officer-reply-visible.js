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
  const msgs = chat.body.messages || [];
  const last = msgs[msgs.length - 1];
  console.log("thread", chat.body.task?.id, "awaiting", chat.body.task?.awaiting_reply_from, "msgs", msgs.length);
  console.log("last", last?.author_name, last?.body);
  const hasOfficer = msgs.some((m) => !m.is_mine && String(m.body || "").includes("Officer reply test"));
  console.log(hasOfficer ? "PASS officer reply visible in app API" : "FAIL officer reply not in app");
})();
