import { pool } from "./pool";

/**
 * Allocate the next iDempiere table ID.
 * Keeps AD_Sequence ahead of the live MAX(id) so manual/SQL inserts cannot cause duplicate keys.
 */
export async function nextSequenceId(sequenceName: string, tableName?: string, idColumn?: string): Promise<number> {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    if (tableName && idColumn) {
      await client.query(
        `UPDATE ad_sequence s
         SET currentnext = GREATEST(
           s.currentnext,
           COALESCE((SELECT MAX(${idColumn}) + s.incrementno FROM ${tableName}), s.currentnext)
         )
         WHERE s.name = $1`,
        [sequenceName],
      );
    }

    const result = await client.query<{ next_id: string }>(
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

    await client.query("COMMIT");
    return Number(row.next_id);
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

export function formatTimestamp(value: unknown): string | null {
  if (!value) return null;
  const date = value instanceof Date ? value : new Date(String(value));
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}
