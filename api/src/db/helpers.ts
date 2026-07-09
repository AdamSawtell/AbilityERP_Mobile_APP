import { pool } from "./pool";

export async function nextSequenceId(sequenceName: string): Promise<number> {
  const result = await pool.query<{ next_id: string }>(
    `UPDATE ad_sequence
     SET currentnext = currentnext + incrementno
     WHERE name = $1
     RETURNING (currentnext - incrementno) AS next_id`,
    [sequenceName],
  );
  const row = result.rows[0];
  if (!row) {
    throw new Error(`Sequence not found: ${sequenceName}`);
  }
  return Number(row.next_id);
}

export function formatTimestamp(value: unknown): string | null {
  if (!value) return null;
  const date = value instanceof Date ? value : new Date(String(value));
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}
