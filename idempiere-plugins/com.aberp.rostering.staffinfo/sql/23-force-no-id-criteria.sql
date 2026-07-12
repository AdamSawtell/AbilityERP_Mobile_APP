-- Match seed fix order after 20: Agency Staff may stay filter-only (List),
-- but NO ID/Search/Integer/Table/MultiSelect may be query criteria.
-- Also force AD_User_ID key off Integer Intbox path by keeping it key+hidden
-- and never query criteria; clear any leftover ID criteria.
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

  -- Absolute: no ID-like query criteria (refs that build Intbox / Chosen -1)
  UPDATE ad_infocolumn SET
    isquerycriteria = 'N',
    seqnoselection = 0,
    defaultvalue = NULL,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND isquerycriteria = 'Y'
    AND ad_reference_id IN (
      11, 13, 18, 19, 21, 30, 31, 200138, 200157, 200161, 200162
    );

  -- Show Unmatched must never be AD criteria (Java checkbox only)
  UPDATE ad_infocolumn SET
    isquerycriteria = 'N',
    isdisplayed = 'N',
    ishideinfocolumn = 'Y',
    seqnoselection = 0,
    defaultvalue = NULL,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde003';

  -- Multi Select always off
  UPDATE ad_infocolumn SET
    isactive = 'N',
    isquerycriteria = 'N',
    isdisplayed = 'N',
    seqnoselection = 0,
    defaultvalue = NULL,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_reference_id = 200138;

  -- Business Partner stays in SELECT for Related Info but must not be Search editor
  -- in the criteria pane: keep Search ref but never query criteria / selection seq.
  UPDATE ad_infocolumn SET
    isquerycriteria = 'N',
    seqnoselection = 0,
    defaultvalue = NULL,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND columnname = 'C_BPartner_ID'
    AND ad_reference_id = 30;

  -- Agency Staff: keep as List criteria. Make displayed=Y so it is a normal
  -- visible criterion (not "hidden criteria" path that seed scripts killed).
  -- Grid hide is separate — use isidentifier/isdisplayed carefully:
  -- For InfoWindow, isdisplayed=Y puts it in RESULT grid. User wanted it off grid.
  -- Keep isdisplayed=N + isquerycriteria=Y for List only (safe — not Intbox).
  UPDATE ad_infocolumn SET
    isactive = 'Y',
    isquerycriteria = 'Y',
    isdisplayed = 'N',
    ad_reference_id = 17,
    seqnoselection = 50,
    defaultvalue = NULL,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND columnname = 'AbERP_isagencystaff';

  RAISE NOTICE '23-force-no-id-criteria applied on %', v_iw;
END $$;

SELECT columnname, name, isquerycriteria, isdisplayed, ad_reference_id
FROM ad_infocolumn
WHERE ad_infowindow_id = (
  SELECT ad_infowindow_id FROM ad_infowindow
  WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
)
AND isquerycriteria = 'Y'
ORDER BY seqnoselection;
