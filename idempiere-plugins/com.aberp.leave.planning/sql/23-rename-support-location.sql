-- =============================================================================
-- SAW016 — Rename Service Location → Support Location + clarify help
-- Criteria + grid labels only (columnname/UUs unchanged for portability).
-- =============================================================================
SET search_path TO adempiere;

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
    name = 'Support Location',
    description = 'Optional Support Location filter (blank = all)',
    help = 'Active Support Locations only. Blank = all sites. Filter matches staff rostered at this Support Location (via MasterLocation), not the employee home address.',
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '16a016ic-0003-4f01-8e15-000000000001';

  UPDATE ad_infocolumn SET
    name = 'Support Location',
    description = 'Primary Support Location (most rostered shifts)',
    help = 'Support Location where this employee has the most rostered shifts.',
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '16a016ic-0010-4f01-8e15-000000000001';

  UPDATE ad_infowindow SET
    description = 'Query leave overlapping a planning period and optional Support Location',
    help = 'Set Planning Start/End, optional Support Location (blank = all), then Search. '
      || 'Support Location filter uses rostered shifts at that site — not the employee home address. '
      || 'Zoom a leave row to submit or set Approver Status.',
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw;

  UPDATE ad_menu SET
    description = 'Query leave overlapping a planning period and optional Support Location',
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND action = 'I';

  RAISE NOTICE 'SAW016: renamed Service Location → Support Location on Info Window %', v_iw;
END $$;

SELECT ic.columnname, ic.name, ic.isquerycriteria, ic.isdisplayed
FROM ad_infocolumn ic
JOIN ad_infowindow iw ON iw.ad_infowindow_id = ic.ad_infowindow_id
WHERE iw.ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001'
  AND ic.columnname IN ('C_BPartner_Location_ID', 'AbERP_LP_ServiceLocation');
