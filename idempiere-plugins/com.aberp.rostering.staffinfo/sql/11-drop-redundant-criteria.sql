-- Drop Search Key + BP Name as Info query criteria (keep as result columns optional).
-- Officers find by User Name (and filters); BP name / Value are redundant for fill.

SET search_path TO adempiere;

DO $$
DECLARE
  v_iw NUMERIC;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf';

  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'AD_InfoWindow UU 2b4ab146-0809-47c6-96f3-8b841d60a6bf not found';
  END IF;

  -- Search Key (Value): not a query criterion; hide from result grid noise
  UPDATE ad_infocolumn SET
    isquerycriteria = 'N',
    isdisplayed = 'N',
    seqnoselection = 0,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND columnname = 'Value'
    AND isactive = 'Y';

  -- BP Name: not a query criterion; keep visible in results (useful context)
  UPDATE ad_infocolumn SET
    isquerycriteria = 'N',
    seqnoselection = 0,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND columnname = 'BP_Name'
    AND isactive = 'Y';

  -- User Name stays first criterion
  UPDATE ad_infocolumn SET
    seqnoselection = 10,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND columnname = 'Name'
    AND isactive = 'Y';

  UPDATE ad_infowindow SET
    help = 'Find by User Name (wildcards auto-added). From Shift Employee, staff on approved leave overlapping the shift Start/End and staff already on an overlapping shift are hidden. Employee defaults Yes; On Approved Leave defaults N. Business Partner stamps from contact on pick/save.',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw;

  RAISE NOTICE 'Removed Search Key + BP Name criteria on AD_InfoWindow_ID=%', v_iw;
END $$;
