import { pool } from "../pool";

export interface ProfileRow {
  ad_user_id: number;
  name: string;
  email: string | null;
  phone: string | null;
  login_value: string | null;
  c_bpartner_id: number;
  employee_no: string | null;
  first_name: string | null;
  last_name: string | null;
  preferred_name: string | null;
  bp_phone: string | null;
  bp_email: string | null;
  address1: string | null;
  city: string | null;
  postal: string | null;
  region: string | null;
}

export async function getProfile(adUserId: number): Promise<ProfileRow | null> {
  const result = await pool.query<ProfileRow>(
    `SELECT
       u.ad_user_id,
       u.name,
       u.email,
       u.phone,
       u.value AS login_value,
       bp.c_bpartner_id,
       bp.value AS employee_no,
       bp.aberp_first_name AS first_name,
       bp.aberp_last_name AS last_name,
       bp.aberp_preferred_name AS preferred_name,
       bp.phone AS bp_phone,
       bp.email AS bp_email,
       loc.address1,
       loc.city,
       loc.postal,
       loc.regionname AS region
     FROM ad_user u
     JOIN c_bpartner bp ON bp.c_bpartner_id = u.c_bpartner_id
     LEFT JOIN c_bpartner_location bpl
       ON bpl.c_bpartner_id = bp.c_bpartner_id AND bpl.isactive = 'Y'
     LEFT JOIN c_location loc ON loc.c_location_id = bpl.c_location_id
     WHERE u.ad_user_id = $1 AND u.isactive = 'Y'
     ORDER BY bpl.isbillto DESC NULLS LAST
     LIMIT 1`,
    [adUserId],
  );
  return result.rows[0] ?? null;
}

export async function updateProfile(
  adUserId: number,
  cBPartnerId: number,
  data: { phone?: string; email?: string },
): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    if (data.phone !== undefined) {
      await client.query(
        `UPDATE c_bpartner SET phone = $1, updated = NOW() WHERE c_bpartner_id = $2`,
        [data.phone, cBPartnerId],
      );
      await client.query(
        `UPDATE ad_user SET phone = $1, updated = NOW() WHERE ad_user_id = $2`,
        [data.phone, adUserId],
      );
    }
    if (data.email !== undefined) {
      await client.query(
        `UPDATE c_bpartner SET email = $1, updated = NOW() WHERE c_bpartner_id = $2`,
        [data.email, cBPartnerId],
      );
      await client.query(
        `UPDATE ad_user SET email = $1, updated = NOW() WHERE ad_user_id = $2`,
        [data.email, adUserId],
      );
    }
    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}
