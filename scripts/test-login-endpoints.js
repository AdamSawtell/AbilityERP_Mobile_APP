const http = require("http");
const https = require("https");

function post(url, body) {
  return new Promise((resolve) => {
    const u = new URL(url);
    const lib = u.protocol === "https:" ? https : http;
    const data = JSON.stringify(body);
    const req = lib.request(
      {
        hostname: u.hostname,
        port: u.port || (u.protocol === "https:" ? 443 : 80),
        path: u.pathname,
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(data),
        },
        rejectUnauthorized: false,
      },
      (res) => {
        let raw = "";
        res.on("data", (c) => (raw += c));
        res.on("end", () =>
          resolve({ status: res.statusCode, body: raw.slice(0, 500) }),
        );
      },
    );
    req.on("error", (e) => resolve({ error: e.message }));
    req.write(data);
    req.end();
  });
}

(async () => {
  const body = { username: "ewilliam", password: "flamingo" };
  console.log(
    "EC2",
    await post(
      "http://ec2-54-206-8-250.ap-southeast-2.compute.amazonaws.com/api/auth/login",
      body,
    ),
  );
  console.log("APP", await post("https://app.abilityvua.com/api/auth/login", body));
  console.log(
    "APP2",
    await post("https://app.abilityvua.com/api/auth/login", {
      username: "Ella Williams",
      password: "flamingo",
    }),
  );
})();
