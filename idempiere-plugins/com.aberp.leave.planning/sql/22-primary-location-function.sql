-- =============================================================================
-- SAW016 — Service Location via SQL function (AccessSqlParser-safe)
-- Nested SELECT in InfoColumn.selectclause still breaks AccessSqlParser even
-- without commas (paren/FROM handling). Expose as scalar function instead.
-- =============================================================================
SET search_path TO adempiere;

CREATE OR REPLACE FUNCTION aberp_lp_primary_support_location(p_user_id numeric)
RETURNS character varying
LANGUAGE sql
STABLE
AS $fn$
  SELECT sl.Name
  FROM AbERP_Rostered_ShiftStaff ss
  INNER JOIN AbERP_Rostered_Shift rs
    ON (rs.AbERP_Rostered_Shift_ID = ss.AbERP_Rostered_Shift_ID AND rs.IsActive = 'Y')
  INNER JOIN AbERP_MasterLocation ml
    ON (ml.AbERP_MasterLocation_ID = rs.AbERP_MasterLocation_ID)
  INNER JOIN AbERP_Support_Location sl
    ON (sl.C_BPartner_Location_ID = ml.C_BPartner_Location_ID AND sl.IsActive = 'Y')
  WHERE ss.AbERP_User_Contact_ID = p_user_id
    AND ss.IsActive = 'Y'
  GROUP BY sl.Name
  ORDER BY COUNT(*) DESC
  LIMIT 1
$fn$;

COMMENT ON FUNCTION aberp_lp_primary_support_location(numeric) IS
  'SAW016: primary Support Location name for leave planning Info grid';

DO $$
DECLARE
  v_iw INTEGER;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001';
  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'SAW016: Leave Planning Info Window missing';
  END IF;

  UPDATE ad_infocolumn SET
    description = 'Primary Support Location (most rostered shifts)',
    help = 'Support Location where this employee has the most rostered shifts. Filter still matches any Support Location they work at.',
    selectclause = 'aberp_lp_primary_support_location(u.AD_User_ID)',
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '16a016ic-0010-4f01-8e15-000000000001';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'SAW016: AbERP_LP_ServiceLocation InfoColumn missing';
  END IF;

  RAISE NOTICE 'SAW016: Service Location selectclause → aberp_lp_primary_support_location(u.AD_User_ID)';
END $$;

-- Smoke: Jul 2026 leave staff with a primary support location
SELECT COUNT(*) AS leave_rows_jul2026,
       COUNT(aberp_lp_primary_support_location(u.ad_user_id)) AS with_primary_loc
FROM aberp_unavailability_leave ul
JOIN ad_user u ON u.ad_user_id = ul.aberp_user_contact_id
WHERE ul.isactive = 'Y'
  AND ul.startdate::date <= DATE '2026-07-31'
  AND ul.enddate::date >= DATE '2026-07-01';

SELECT selectclause FROM ad_infocolumn
WHERE ad_infocolumn_uu = '16a016ic-0010-4f01-8e15-000000000001';
