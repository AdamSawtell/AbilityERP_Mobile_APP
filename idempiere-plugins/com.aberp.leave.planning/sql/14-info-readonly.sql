-- =============================================================================
-- SAW016 — Leave Planning Info: result grid display-only
-- When IsReadOnly=N, WInfoWindowListItemRenderer paints editors on the selected row.
-- Criteria stay writable via LeavePlanningInfoWindow.ensureCriteriaEditorsWritable().
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
    isreadonly = 'Y',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND isactive = 'Y'
    AND isdisplayed = 'Y';

  RAISE NOTICE 'SAW016: result grid columns IsReadOnly=Y on InfoWindow %', v_iw;
END $$;

SELECT columnname, isquerycriteria, isdisplayed, isreadonly
FROM ad_infocolumn
WHERE ad_infowindow_id = (
  SELECT ad_infowindow_id FROM ad_infowindow
  WHERE ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001'
)
AND isactive = 'Y'
AND isdisplayed = 'Y'
ORDER BY seqno;
