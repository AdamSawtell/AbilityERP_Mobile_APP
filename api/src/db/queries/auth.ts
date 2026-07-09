import type { AdUserRow } from "../../types";
import { pool } from "../pool";

export const SUPPORT_WORKER_ROLE = "Support Worker";

export async function findAdUserByEmail(
  email: string,
): Promise<AdUserRow | null> {
  const result = await pool.query<AdUserRow>(
    `SELECT ad_user_id, ad_client_id, c_bpartner_id, name, email, password, isactive, islocked
     FROM ad_user
     WHERE LOWER(email) = LOWER($1)
       AND isactive = 'Y'
     LIMIT 1`,
    [email],
  );
  return result.rows[0] ?? null;
}

export async function findAdUserByLogin(login: string): Promise<AdUserRow | null> {
  const result = await pool.query<AdUserRow>(
    `SELECT ad_user_id, ad_client_id, c_bpartner_id, name, email, password, isactive, islocked
     FROM ad_user
     WHERE (LOWER(name) = LOWER($1) OR LOWER(email) = LOWER($1) OR LOWER(value) = LOWER($1))
       AND isactive = 'Y'
     LIMIT 1`,
    [login],
  );
  return result.rows[0] ?? null;
}

export async function userHasSupportWorkerRole(adUserId: number): Promise<boolean> {
  const result = await pool.query<{ has_role: boolean }>(
    `SELECT EXISTS (
       SELECT 1
       FROM ad_user_roles ur
       JOIN ad_role r ON r.ad_role_id = ur.ad_role_id
       WHERE ur.ad_user_id = $1
         AND ur.isactive = 'Y'
         AND r.isactive = 'Y'
         AND r.name = $2
     ) AS has_role`,
    [adUserId, SUPPORT_WORKER_ROLE],
  );
  return result.rows[0]?.has_role === true;
}

export async function getUserRoles(adUserId: number): Promise<string[]> {
  const result = await pool.query<{ name: string }>(
    `SELECT r.name
     FROM ad_user_roles ur
     JOIN ad_role r ON r.ad_role_id = ur.ad_role_id
     WHERE ur.ad_user_id = $1
       AND ur.isactive = 'Y'
       AND r.isactive = 'Y'
     ORDER BY r.name`,
    [adUserId],
  );
  return result.rows.map((row) => row.name);
}
