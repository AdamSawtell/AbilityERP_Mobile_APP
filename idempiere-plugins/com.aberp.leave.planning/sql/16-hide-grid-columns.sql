-- =============================================================================
-- SAW016 — Hide clutter columns from Leave Planning Info result grid
-- Employee Number, Employee Name, Submitter Status (criteria Employee stays)
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
    RAISE EXCEPTION 'SAW016: Leave Planning Info Window UU 16a016iw-… missing';
  END IF;

  UPDATE ad_infocolumn SET
    isdisplayed = 'N',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu IN (
      '16a016ic-0008-4f01-8e15-000000000001', -- Value / Employee Number
      '16a016ic-0009-4f01-8e15-000000000001', -- Name / Employee Name
      '16a016ic-0015-4f01-8e15-000000000001', -- AbERP_SubmitterStatus
      '16a016ic-0018-4f01-8e15-000000000001'  -- Updated
    );

  -- Name fallback if UU missing on older installs
  UPDATE ad_infocolumn SET
    isdisplayed = 'N',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND columnname IN ('Value', 'Name', 'AbERP_SubmitterStatus', 'Updated')
    AND isquerycriteria = 'N';

  RAISE NOTICE 'SAW016: hid Value/Name/Submitter Status/Updated on InfoWindow %', v_iw;
END $$;

SELECT seqno, columnname, name, isdisplayed, isquerycriteria
FROM ad_infocolumn
WHERE ad_infowindow_id = (
  SELECT ad_infowindow_id FROM ad_infowindow
  WHERE ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001'
)
AND columnname IN ('Value', 'Name', 'AbERP_SubmitterStatus', 'AbERP_User_Contact_ID', 'Updated')
ORDER BY seqno;
