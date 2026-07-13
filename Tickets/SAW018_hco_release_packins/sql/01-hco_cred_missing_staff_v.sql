-- SAW018: view required by hco_credentials 2Pack (AD_Table hco_cred_missing_staff_v)
-- Idempotent: DROP IF EXISTS then CREATE
-- Source: D:\HCO Release Packins\hco_cred_missing_staff_v.sql (pg_dump style cleaned)

SET search_path TO adempiere;

DROP VIEW IF EXISTS adempiere.hco_cred_missing_staff_v;

CREATE VIEW adempiere.hco_cred_missing_staff_v AS
SELECT
  bp.ad_client_id,
  bp.ad_org_id,
  'Y'::character(1) AS isactive,
  bp.created,
  COALESCE(bp.createdby, (0)::numeric) AS createdby,
  bp.updated,
  COALESCE(bp.updatedby, (0)::numeric) AS updatedby,
  (((cred.aberp_credentials_id)::bigint << 32) + (bp.c_bpartner_id)::bigint) AS hco_cred_missing_staff_v_id,
  cred.aberp_credentials_id,
  bp.c_bpartner_id,
  bp.name
FROM adempiere.aberp_credentials cred
CROSS JOIN adempiere.c_bpartner bp
WHERE COALESCE(bp.isemployee, 'N'::bpchar) = 'Y'::bpchar
  AND COALESCE(bp.isactive, 'Y'::bpchar) = 'Y'::bpchar
  AND bp.ad_client_id = cred.ad_client_id
  AND NOT EXISTS (
    SELECT 1
    FROM adempiere.aberp_credentialassignment ca
    JOIN adempiere.ad_user u
      ON u.ad_user_id = ca.aberp_user_contact_id
     AND COALESCE(u.isactive, 'Y'::bpchar) = 'Y'::bpchar
    WHERE u.c_bpartner_id = bp.c_bpartner_id
      AND ca.aberp_credentials_id = cred.aberp_credentials_id
      AND COALESCE(ca.isactive, 'Y'::bpchar) = 'Y'::bpchar
  );

ALTER TABLE adempiere.hco_cred_missing_staff_v OWNER TO adempiere;

SELECT to_regclass('adempiere.hco_cred_missing_staff_v') AS view_exists;
