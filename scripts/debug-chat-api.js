const http = require("http");
function req(m, p, b, t) {
  return new Promise((res, rej) => {
    const d = b ? JSON.stringify(b) : null;
    const h = { "Content-Type": "application/json", ...(t ? { Authorization: "Bearer " + t } : {}) };
    if (d) h["Content-Length"] = Buffer.byteLength(d);
    const q = http.request({ hostname: "127.0.0.1", port: 3001, path: p, method: m, headers: h }, (s) => {
      let x = "";
      s.on("data", (c) => (x += c));
      s.on("end", () => res({ status: s.statusCode, body: x }));
    });
    q.on("error", rej);
    if (d) q.write(d);
    q.end();
  });
}
(async () => {
  const login = await req("POST", "/api/auth/login", { username: "ewilliam", password: "flamingo" });
  console.log("login", login.status);
  const token = JSON.parse(login.body).token;
  const chat = await req("GET", "/api/requests/chat", null, token);
  console.log("GET chat", chat.status, chat.body.slice(0, 800));
  const created = await req("POST", "/api/requests/chat", { message: "debug start " + Date.now() }, token);
  console.log("POST chat", created.status, created.body.slice(0, 800));
})();
