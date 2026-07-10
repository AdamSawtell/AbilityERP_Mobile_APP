import pg from "pg";
import path from "path";
import fs from "fs";
import dotenv from "dotenv";

const envCandidates = [
  path.resolve(process.cwd(), ".env"),
  path.resolve(process.cwd(), "../.env"),
  path.resolve(__dirname, "../.env"),
  path.resolve(__dirname, "../../.env"),
  path.resolve(__dirname, "../../../.env"),
];

for (const envPath of envCandidates) {
  if (fs.existsSync(envPath)) {
    dotenv.config({ path: envPath });
    break;
  }
}

const { Pool } = pg;

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.warn(
    "[db] DATABASE_URL is not set — API will fail on database routes until configured.",
  );
}

export const pool = new Pool({
  connectionString,
  max: 10,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
  // Match iDempiere WebUI so timestamp-without-tz chat Created values sort correctly
  options: "-c search_path=adempiere,public -c TimeZone=Australia/Adelaide",
});

pool.on("connect", (client) => {
  client
    .query("SET search_path TO adempiere, public; SET TIME ZONE 'Australia/Adelaide'")
    .catch((err) => {
      console.error("[db] Failed to set search_path/timezone:", err.message);
    });
});

export async function checkDbConnection(): Promise<boolean> {
  if (!connectionString) return false;
  try {
    const result = await pool.query("SELECT 1 AS ok");
    return result.rows[0]?.ok === 1;
  } catch {
    return false;
  }
}
