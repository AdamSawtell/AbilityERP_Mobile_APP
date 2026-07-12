-- Hotfix: ZK "non-negative only" on Staff Rostering Info ReQuery.
-- Cause: Multi Select InfoColumns (esp. Support Receiver Needs, ColumnName C_BPartner_ID)
-- left active after Related Info grants; empty ChosenMultipleSelection holds -1.
--
-- Do NOT strip all hidden query criteria — Agency Staff is filter-only
-- (isdisplayed=N, isquerycriteria=Y) by design (see 20-hide-clutter-columns.sql).
--
-- Safe to re-run. Log out/in after apply (Cache Reset optional).
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

  -- Deactivate every Multi Select Table column on this Info Window
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

  -- Explicit known offenders by UU (including Support Receiver Needs)
  UPDATE ad_infocolumn SET
    isactive = 'N',
    isquerycriteria = 'N',
    isdisplayed = 'N',
    seqnoselection = 0,
    defaultvalue = NULL,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu IN (
      '40d550c2-4088-412d-8774-f2d2b2cd9247', -- Support Receiver Needs
      'ac0d418c-4aac-44fa-bc50-eb57ff978875', -- Employee Status
      'bf6693b4-56dd-4c1b-836d-3c0f517aad9d', -- Shift Status
      '32efe3e4-4853-4656-bc45-a6e6672890ca', -- Credentials
      '3916bb24-c7be-4f78-96ee-77a711fba800', -- Master Location
      'c4ab6130-0d64-4ce0-8be8-e6f7af56a98b', -- Position Needs
      '40c40fdf-d0a1-4076-951f-f35e3deb463b', -- Rostered Shift Needs
      '492b6870-a7b3-43f8-a9bd-7abf7b9efb49'  -- Support Location Needs
    );

  -- Gender / Position: never query criteria (Table Direct Intbox -1)
  UPDATE ad_infocolumn SET
    isquerycriteria = 'N',
    seqnoselection = 0,
    defaultvalue = NULL,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infocolumn_uu IN (
    '22426da0-28ec-4047-8eff-0cb186e556b6', -- Gender
    'b70b7e4e-23f7-45e1-92b2-7b40e4e3c908'  -- Position
  );

  -- Hidden ID-like query criteria only (Search/Table/TableDir/Integer/ID) —
  -- leave List/YesNo/String filters such as Agency Staff alone.
  UPDATE ad_infocolumn SET
    isquerycriteria = 'N',
    seqnoselection = 0,
    defaultvalue = NULL,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND isquerycriteria = 'Y'
    AND COALESCE(isdisplayed, 'N') = 'N'
    AND ad_reference_id IN (
      11,   -- Integer
      13,   -- ID
      18,   -- Table
      19,   -- Table Direct
      30,   -- Search
      200138, -- Multi Select Table
      200157, -- Multi Select Search
      200161  -- Multi Select List (if present)
    );

  -- Partner Location leftover selection seq (not criteria — avoid editor noise)
  UPDATE ad_infocolumn SET
    seqnoselection = 0,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND columnname = 'C_BPartner_Location_ID'
    AND COALESCE(isquerycriteria, 'N') = 'N';

  -- Restore Agency Staff as filter-only criteria (20-hide-clutter-columns)
  UPDATE ad_infocolumn SET
    isactive = 'Y',
    isquerycriteria = 'Y',
    isdisplayed = 'N',
    seqnoselection = 50,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND columnname = 'AbERP_isagencystaff';

  -- Keep Related Info parent BP + User active (display/key — not Multi Select)
  UPDATE ad_infocolumn SET isactive = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu IN (
      '3402dcb1-ec9b-46b3-a8a6-8248b89cc4f4',
      '42578105-dbb8-4f51-9e53-8af7e5073997'
    );

  RAISE NOTICE 'Non-negative hotfix applied on AD_InfoWindow_ID=%', v_iw;
END $$;

SELECT columnname, name, isactive, isquerycriteria, isdisplayed, ad_reference_id, seqnoselection
FROM ad_infocolumn
WHERE ad_infowindow_id = (
    SELECT ad_infowindow_id FROM ad_infowindow
    WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  )
  AND (
    ad_reference_id = 200138
    OR columnname IN ('AbERP_isagencystaff', 'Name', 'IsEmployee', 'C_BPartner_ID')
    OR isquerycriteria = 'Y'
  )
ORDER BY isquerycriteria DESC, seqnoselection, columnname;
