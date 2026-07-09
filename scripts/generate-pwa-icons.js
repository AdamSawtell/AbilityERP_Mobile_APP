/**
 * Generate PWA icons from organisation logo (iDempiere AD_SysConfig ZK_LOGO_SMALL).
 * Usage: node scripts/generate-pwa-icons.js
 * Override: ORG_LOGO_URL=https://... node scripts/generate-pwa-icons.js
 */
const fs = require("fs");
const path = require("path");
const https = require("https");
const http = require("http");

const DEFAULT_LOGO_URL =
  "https://fllogo.s3.us-east-2.amazonaws.com/abilityERP_logo+Pink+In.png";

const OUT_DIR = path.join(__dirname, "..", "web", "public", "icons");
const SIZES = [
  { name: "icon-192.png", size: 192 },
  { name: "icon-512.png", size: 512 },
  { name: "apple-touch-icon.png", size: 180 },
  { name: "favicon-32.png", size: 32 },
];

function fetchBuffer(url) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith("https") ? https : http;
    client
      .get(url, (res) => {
        if (res.statusCode && res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          fetchBuffer(res.headers.location).then(resolve).catch(reject);
          return;
        }
        if (res.statusCode !== 200) {
          reject(new Error(`Failed to fetch logo: HTTP ${res.statusCode}`));
          return;
        }
        const chunks = [];
        res.on("data", (chunk) => chunks.push(chunk));
        res.on("end", () => resolve(Buffer.concat(chunks)));
      })
      .on("error", reject);
  });
}

async function main() {
  let sharp;
  try {
    sharp = require(path.join(__dirname, "..", "web", "node_modules", "sharp"));
  } catch {
    console.error("Run: cd web && npm install -D sharp");
    process.exit(1);
  }

  const logoUrl = process.env.ORG_LOGO_URL || DEFAULT_LOGO_URL;
  console.log("Source logo:", logoUrl);

  fs.mkdirSync(OUT_DIR, { recursive: true });
  const source = await fetchBuffer(logoUrl);

  for (const { name, size } of SIZES) {
    const outPath = path.join(OUT_DIR, name);
    await sharp(source)
      .resize(size, size, {
        fit: "contain",
        background: { r: 249, g: 250, b: 251, alpha: 1 },
      })
      .png()
      .toFile(outPath);
    console.log("Wrote", outPath);
  }

  console.log("Done. Update manifest.json if needed.");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
