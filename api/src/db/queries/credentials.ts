import { pool } from "../pool";
import { formatTimestamp } from "../helpers";

export interface CredentialRow {
  id: number;
  name: string;
  type_name: string | null;
  category_name: string | null;
  expiry_date: string | null;
  status: string;
}

export async function getCredentials(cBPartnerStaffId: number): Promise<CredentialRow[]> {
  const result = await pool.query<{
    id: number;
    name: string;
    type_name: string | null;
    category_name: string | null;
    expiry_date: Date | null;
    status: string;
  }>(
    `SELECT
       ca.aberp_credentialassignment_id AS id,
       COALESCE(c.name, ca.name) AS name,
       ct.name AS type_name,
       cc.name AS category_name,
       ca.aberp_expirydate AS expiry_date,
       CASE
         WHEN ca.aberp_expirydate IS NOT NULL AND ca.aberp_expirydate < NOW() THEN 'expired'
         ELSE 'active'
       END AS status
     FROM aberp_credentialassignment ca
     JOIN aberp_credentials c ON c.aberp_credentials_id = ca.aberp_credentials_id
     LEFT JOIN aberp_credentialstype ct ON ct.aberp_credentialstype_id = ca.aberp_credentialstype_id
     LEFT JOIN aberp_credentialscategory cc ON cc.aberp_credentialscategory_id = ca.aberp_credentialscategory_id
     WHERE ca.c_bpartner_staff_id = $1 AND ca.isactive = 'Y'
     ORDER BY ca.aberp_expirydate ASC NULLS LAST, c.name ASC`,
    [cBPartnerStaffId],
  );

  return result.rows.map((row) => ({
    ...row,
    expiry_date: formatTimestamp(row.expiry_date),
  }));
}

export async function getCredentialCount(cBPartnerStaffId: number): Promise<number> {
  const result = await pool.query<{ count: string }>(
    `SELECT COUNT(*)::text AS count
     FROM aberp_credentialassignment
     WHERE c_bpartner_staff_id = $1 AND isactive = 'Y'`,
    [cBPartnerStaffId],
  );
  return Number(result.rows[0]?.count ?? 0);
}
