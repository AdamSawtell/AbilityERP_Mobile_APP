-- =============================================================================
-- SAW016 — Service Location display: primary Support Location only
-- Avoids AccessSqlParser comma issues AND slow string_agg over all shifts.
-- Primary = Support Location with most rostered shifts for the employee.
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_iw INTEGER;
  v_display TEXT :=
    '(SELECT sl.Name'
    || ' FROM AbERP_Rostered_ShiftStaff ss'
    || ' INNER JOIN AbERP_Rostered_Shift rs ON (rs.AbERP_Rostered_Shift_ID=ss.AbERP_Rostered_Shift_ID AND rs.IsActive=''Y'')'
    || ' INNER JOIN AbERP_MasterLocation ml ON (ml.AbERP_MasterLocation_ID=rs.AbERP_MasterLocation_ID)'
    || ' INNER JOIN AbERP_Support_Location sl ON (sl.C_BPartner_Location_ID=ml.C_BPartner_Location_ID AND sl.IsActive=''Y'')'
    || ' WHERE ss.AbERP_User_Contact_ID=u.AD_User_ID AND ss.IsActive=''Y'''
    || ' GROUP BY sl.Name'
    || ' ORDER BY COUNT(*) DESC'
    || ' LIMIT 1)';
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
    selectclause = v_display,
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '16a016ic-0010-4f01-8e15-000000000001';

  RAISE NOTICE 'SAW016: Service Location display → primary Support Location (LIMIT 1)';
END $$;

SELECT selectclause FROM ad_infocolumn ic
JOIN ad_infowindow iw ON iw.ad_infowindow_id=ic.ad_infowindow_id
WHERE iw.ad_infowindow_uu='16a016iw-c0d4-4f01-8e15-000000000001'
  AND ic.columnname='AbERP_LP_ServiceLocation';
