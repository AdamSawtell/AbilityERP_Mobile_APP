import pg from "pg";
import dotenv from "dotenv";

dotenv.config();

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
});

pool.on("connect", (client) => {
  client.query("SET search_path TO adempiere, public").catch((err) => {
    console.error("[db] Failed to set search_path:", err.message);
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
