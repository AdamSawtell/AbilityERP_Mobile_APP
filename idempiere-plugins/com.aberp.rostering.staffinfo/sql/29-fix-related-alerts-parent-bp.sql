-- SAW032 / SAW003 follow-up — Related Info "BP User Alerts" needs parent C_BPartner_ID
-- in the Find & Fill result model.
--
-- iDempiere InfoWindow builds SELECT / list model only from IsDisplayed=Y columns
-- (plus IsKey). ParentRelatedColumn replaces the key for Related Info linking, but
-- that parent column must still be in the selected-row model / TAB_INFO context.
--
-- AD_User_ID already uses: IsDisplayed=Y + IsHideInfoColumn=Y (correct).
-- C_BPartner_ID (UU 42578105-...) was left IsDisplayed=N by sql/20-hide-clutter —
-- so Alerts (link: parent C_BPartner_ID → child a.C_BPartner_ID) gets no BP id.
-- Other Related tabs (Leave / Credentials / Shifts) link on AD_User_ID and still work.
--
-- Fix: same pattern as the key column — display in query, hide in grid.
-- Idempotent. Find & Fill UU only (SMS clone remapped its own parent column ids).

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

  UPDATE ad_infocolumn SET
    isactive = 'Y',
    isdisplayed = 'Y',
    ishideinfocolumn = 'Y',
    isquerycriteria = 'N',
    seqnoselection = 0,
    defaultvalue = NULL,
    selectclause = 'au.C_BPartner_ID',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '42578105-dbb8-4f51-9e53-8af7e5073997';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n = 0 THEN
    RAISE EXCEPTION 'Parent C_BPartner_ID InfoColumn UU 42578105-dbb8-4f51-9e53-8af7e5073997 not found on Find & Fill';
  END IF;

  -- Keep Related Info row active AND restore BP→BP link
  -- (manual edits sometimes retarget Parent/Related to Name / BP_Name)
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

  RAISE NOTICE 'Related Info parent C_BPartner_ID fixed for Alerts on AD_InfoWindow_ID=%', v_iw;
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
    selectclause = 'au.C_BPartner_ID',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_sms
    AND columnname = 'C_BPartner_ID'
    AND selectclause = 'au.C_BPartner_ID'
    AND ad_reference_id = 30;
  GET DIAGNOSTICS n = ROW_COUNT;
  RAISE NOTICE 'SMS clone C_BPartner_ID parent columns updated: %', n;
END $$;

SELECT iw.name, c.columnname, c.isdisplayed, c.ishideinfocolumn, c.iskey, c.isactive, c.selectclause
FROM ad_infocolumn c
JOIN ad_infowindow iw ON iw.ad_infowindow_id = c.ad_infowindow_id
WHERE iw.ad_infowindow_uu IN (
  '2b4ab146-0809-47c6-96f3-8b841d60a6bf',
  '7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11'
)
AND c.columnname IN ('AD_User_ID', 'C_BPartner_ID')
AND COALESCE(c.selectclause, '') LIKE 'au.%'
ORDER BY iw.name, c.columnname;
