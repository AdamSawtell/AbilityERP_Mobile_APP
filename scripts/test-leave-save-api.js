const http = require("http");

function request(method, path, body, token) {
  return new Promise((resolve) => {
    const data = body ? JSON.stringify(body) : null;
    const req = http.request(
      {
        hostname: "ec2-54-206-8-250.ap-southeast-2.compute.amazonaws.com",
        path,
        method,
        headers: {
          ...(data
            ? {
                "Content-Type": "application/json",
                "Content-Length": Buffer.byteLength(data),
              }
            : {}),
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
      },
      (res) => {
        let raw = "";
        res.on("data", (c) => (raw += c));
        res.on("end", () => resolve({ status: res.statusCode, body: raw }));
      },
    );
    req.on("error", (e) => resolve({ error: e.message }));
    if (data) req.write(data);
    req.end();
  });
}

(async () => {
  const login = await request("POST", "/api/auth/login", {
    username: "ewilliam",
    password: "flamingo",
  });
  const token = JSON.parse(login.body).token;
  const note = "Browser leave save test " + new Date().toISOString();
  const create = await request(
    "POST",
    "/api/leave",
    {
      startDate: "2026-09-01T09:00",
      endDate: "2026-09-01T17:00",
      note,
    },
    token,
  );
  console.log("CREATE", create.status, create.body);
  const list = await request("GET", "/api/leave", null, token);
  console.log("LIST", list.status, list.body);
})();
