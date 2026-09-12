-- SAW032 / SAW003 follow-up — Related Info "BP User Alerts" parent link.
--
-- iDempiere InfoWindow includes columns when IsDisplayed=Y OR IsHideInfoColumn=Y.
-- Related Info reads the parent link value from the selected-row model by column index.
--
-- AD_User_ID (other Related tabs) uses: IsDisplayed=Y + IsHideInfoColumn=Y + Integer (11).
-- C_BPartner_ID (Alerts only) was IsDisplayed=N after sql/20 — Alerts got no BP id.
--
-- CRITICAL: do NOT use Search/Table (30/18/19) for this parent link column.
-- Lookup layout expands to KeyNamePair (extra display SQL) and skews Related Info
-- column indexes so EVERY Related tab refreshes empty. Use Integer (11) like AD_User_ID.
--
-- Also restore AD_InfoRelated Parent/Related columns to C_BPartner_ID → C_BPartner_ID
-- (manual edits sometimes retarget to Name / BP_Name).

SET search_path TO adempiere;

DO $$
DECLARE
  v_iw NUMERIC;
  n INT;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf';

  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'Find & Fill Info Window UU 2b4ab146-0809-47c6-96f3-8b841d60a6bf not found';
  END IF;

  -- Parent key style (User) — keep Integer, not Search
  UPDATE ad_infocolumn SET
    isactive = 'Y',
    isdisplayed = 'Y',
    ishideinfocolumn = 'Y',
    isquerycriteria = 'N',
    ad_reference_id = 11,
    ad_reference_value_id = NULL,
    selectclause = 'au.AD_User_ID',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '3402dcb1-ec9b-46b3-a8a6-8248b89cc4f4';

  -- Parent BP link for Alerts — Integer + hide in grid (NOT Search)
  UPDATE ad_infocolumn SET
    isactive = 'Y',
    isdisplayed = 'Y',
    ishideinfocolumn = 'Y',
    isquerycriteria = 'N',
    seqnoselection = 0,
    defaultvalue = NULL,
    ad_reference_id = 11,
    ad_reference_value_id = NULL,
    selectclause = 'au.C_BPartner_ID',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '42578105-dbb8-4f51-9e53-8af7e5073997';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n = 0 THEN
    RAISE EXCEPTION 'Parent C_BPartner_ID InfoColumn UU 42578105-dbb8-4f51-9e53-8af7e5073997 not found on Find & Fill';
  END IF;

  UPDATE ad_inforelated SET
    isactive = 'Y',
    parentrelatedcolumn_id = (
      SELECT c.ad_infocolumn_id FROM ad_infocolumn c
      WHERE c.ad_infowindow_id = v_iw
        AND c.ad_infocolumn_uu = '42578105-dbb8-4f51-9e53-8af7e5073997'
    ),
    relatedcolumn_id = (
      SELECT c.ad_infocolumn_id
      FROM ad_infocolumn c
      JOIN ad_infowindow child ON child.ad_infowindow_id = c.ad_infowindow_id
      WHERE child.ad_infowindow_uu = 'b8e1fa06-f0c1-4e74-9708-133024446d85'
        AND c.columnname = 'C_BPartner_ID'
        AND c.selectclause = 'a.C_BPartner_ID'
      LIMIT 1
    ),
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND (
      ad_inforelated_uu = 'a0a79770-93ff-4f44-9d0f-4c7125895fd3'
      OR name = 'BP User Alerts'
    );

  RAISE NOTICE 'Related Info Alerts parent BP link fixed on AD_InfoWindow_ID=%', v_iw;
END $$;

-- Same fix on SMS clone if present (own column ids; match by ColumnName + SelectClause)
DO $$
DECLARE
  v_sms NUMERIC;
  n INT;
BEGIN
  SELECT ad_infowindow_id INTO v_sms
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11';
  IF v_sms IS NULL THEN
    RAISE NOTICE 'SMS Info Window not present — skip';
    RETURN;
  END IF;

  UPDATE ad_infocolumn SET
    isactive = 'Y',
    isdisplayed = 'Y',
    ishideinfocolumn = 'Y',
    isquerycriteria = 'N',
    seqnoselection = 0,
    defaultvalue = NULL,
    ad_reference_id = 11,
    ad_reference_value_id = NULL,
    selectclause = 'au.AD_User_ID',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_sms
    AND columnname = 'AD_User_ID'
    AND selectclause = 'au.AD_User_ID';

  UPDATE ad_infocolumn SET
    isactive = 'Y',
    isdisplayed = 'Y',
    ishideinfocolumn = 'Y',
    isquerycriteria = 'N',
    seqnoselection = 0,
    defaultvalue = NULL,
    ad_reference_id = 11,
    ad_reference_value_id = NULL,
    selectclause = 'au.C_BPartner_ID',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_sms
    AND columnname = 'C_BPartner_ID'
    AND selectclause = 'au.C_BPartner_ID';
  GET DIAGNOSTICS n = ROW_COUNT;
  RAISE NOTICE 'SMS clone C_BPartner_ID parent columns updated: %', n;
END $$;

SELECT iw.name, c.columnname, c.isdisplayed, c.ishideinfocolumn, c.iskey, c.isactive,
       c.ad_reference_id, c.selectclause
FROM ad_infocolumn c
JOIN ad_infowindow iw ON iw.ad_infowindow_id = c.ad_infowindow_id
WHERE iw.ad_infowindow_uu IN (
  '2b4ab146-0809-47c6-96f3-8b841d60a6bf',
  '7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11'
)
AND c.columnname IN ('AD_User_ID', 'C_BPartner_ID')
AND COALESCE(c.selectclause, '') LIKE 'au.%'
ORDER BY iw.name, c.columnname;
