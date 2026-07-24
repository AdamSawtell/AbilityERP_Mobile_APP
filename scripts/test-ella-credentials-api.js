const http = require("http");
const https = require("https");

function request(url, opts = {}, body) {
  return new Promise((resolve) => {
    const u = new URL(url);
    const lib = u.protocol === "https:" ? https : http;
    const data = body ? JSON.stringify(body) : null;
    const req = lib.request(
      {
        hostname: u.hostname,
        port: u.port || (u.protocol === "https:" ? 443 : 80),
        path: u.pathname + u.search,
        method: opts.method || "GET",
        headers: {
          ...(data
            ? {
                "Content-Type": "application/json",
                "Content-Length": Buffer.byteLength(data),
              }
            : {}),
          ...(opts.headers || {}),
        },
        rejectUnauthorized: false,
      },
      (res) => {
        let raw = "";
        res.on("data", (c) => (raw += c));
        res.on("end", () =>
          resolve({ status: res.statusCode, headers: res.headers, body: raw }),
        );
      },
    );
    req.on("error", (e) => resolve({ error: e.message }));
    if (data) req.write(data);
    req.end();
  });
}

(async () => {
  const base = "http://ec2-54-206-8-250.ap-southeast-2.compute.amazonaws.com";
  const login = await request(`${base}/api/auth/login`, { method: "POST" }, {
    username: "ewilliam",
    password: "flamingo",
  });
  console.log("LOGIN", login.status, login.body.slice(0, 300));
  if (login.error || login.status >= 400) process.exit(1);

  const token = JSON.parse(login.body).token || JSON.parse(login.body).accessToken;
  const authHeader = token
    ? { Authorization: `Bearer ${token}` }
    : { Cookie: login.headers["set-cookie"]?.join("; ") || "" };

  const creds = await request(`${base}/api/credentials`, { headers: authHeader });
  console.log("CREDS_STATUS", creds.status);
  const parsed = JSON.parse(creds.body);
  console.log("CREDS_COUNT", parsed.items?.length);
  console.log(
    "CREDS_NAMES",
    (parsed.items || []).map((i) => `${i.name} [${i.status}]`).slice(0, 20),
  );

  const idCard = await request(`${base}/api/credentials/id-card`, { headers: authHeader });
  console.log("ID_CARD", idCard.body);
})();
