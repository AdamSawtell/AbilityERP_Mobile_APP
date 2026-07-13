-- =============================================================================
-- SAW016 — Fix Service Location ColumnSQL for AccessSqlParser
-- InfoWindow AccessSqlParser splits SELECT lists on commas, so
-- string_agg(..., ', ') throws IllegalArgumentException on Search.
-- Use ' | ' separator (no comma characters in the selectclause).
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_iw INTEGER;
  v_display TEXT :=
    '(SELECT string_agg(DISTINCT sl.Name, '' | '' ORDER BY sl.Name)'
    || ' FROM AbERP_Rostered_ShiftStaff ss'
    || ' INNER JOIN AbERP_Rostered_Shift rs ON (rs.AbERP_Rostered_Shift_ID=ss.AbERP_Rostered_Shift_ID AND rs.IsActive=''Y'')'
    || ' INNER JOIN AbERP_MasterLocation ml ON (ml.AbERP_MasterLocation_ID=rs.AbERP_MasterLocation_ID)'
    || ' INNER JOIN AbERP_Support_Location sl ON (sl.C_BPartner_Location_ID=ml.C_BPartner_Location_ID AND sl.IsActive=''Y'')'
    || ' WHERE ss.AbERP_User_Contact_ID=u.AD_User_ID AND ss.IsActive=''Y'')';
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001';
  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'SAW016: Leave Planning Info Window missing';
  END IF;

  UPDATE ad_infocolumn SET
    selectclause = v_display,
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '16a016ic-0010-4f01-8e15-000000000001';

  RAISE NOTICE 'SAW016: Service Location selectclause uses | separator (AccessSqlParser-safe)';
END $$;

SELECT selectclause
FROM ad_infocolumn ic
JOIN ad_infowindow iw ON iw.ad_infowindow_id = ic.ad_infowindow_id
WHERE iw.ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001'
  AND ic.columnname = 'AbERP_LP_ServiceLocation';
