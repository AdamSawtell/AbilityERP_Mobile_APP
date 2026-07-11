-- AbERP Staff Rostering Info — hotfix after browser smoke test
-- Root causes found in WebUI + server log:
-- 1) CAST('' AS TIMESTAMP) fails at plan time → use NULLIF (superseded: no dates in Where)
-- 2) SelectClause '0' → StringIndexOutOfBounds begin 0, end -1 → deactivate those columns
-- 3) keyView must be integer → AD_User_ID AD_Reference_ID=13
-- 4) Duplicate ColumnName Name → rename BP column to BP_Name
-- 5) Complex WhereClause with @StartDate@ → InfoWindow.loadInfoDefinition
--    "Cannot parse context" → ListModelTable field at 0,-1
--    FIX: WhereClause must stay simple/static (no @ctx@ tokens)
-- 6) Nested @SQL= defaults with @+isEmployeeWindowOpenFromShift@ hang the
--    Search field spinner when opened from Shift Employee tab
--    FIX: clear those DefaultValue strings

SET search_path TO adempiere;

DO $$
DECLARE
  v_iw NUMERIC;
  v_from TEXT;
  v_where TEXT;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf';

  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'AD_InfoWindow UU 2b4ab146-0809-47c6-96f3-8b841d60a6bf not found';
  END IF;

  v_from :=
    'AD_User au'
    || E'\nINNER JOIN C_BPartner bp ON (bp.C_BPartner_ID = au.C_BPartner_ID AND bp.IsActive = ''Y'')'
    || E'\nLEFT JOIN C_Job jb ON (jb.C_Job_ID = bp.C_Job_ID AND jb.IsActive = ''Y'')';

  -- MUST remain free of @Context@ tokens — iDempiere context parser cannot handle them
  -- inside complex WHERE (see log: InfoWindow.loadInfoDefinition Cannot parse context).
  v_where := 'au.IsActive = ''Y''';

  UPDATE ad_infowindow SET
    description = 'Fast staff picker for Shift Employee fill (lean User+BP query).',
    help = 'Search employees/agency staff to assign on Shift (Rostered) Employee tab. Criteria: Name, Search Key, Employee, Agency, Gender, Position.',
    fromclause = v_from,
    whereclause = v_where,
    orderbyclause = 'au.Name',
    otherclause = NULL,
    isdistinct = 'N',
    isvalid = 'Y',
    maxqueryrecords = 500,
    isloadpagenum = 'N',
    pagingsize = 50,
    pagesize = 50,
    isshowindashboard = 'N',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw;

  UPDATE ad_infocolumn SET
    iskey = 'Y',
    isidentifier = 'N',
    isdisplayed = 'Y',
    ishideinfocolumn = 'Y',
    isquerycriteria = 'N',
    ad_reference_id = 11,
    selectclause = 'au.AD_User_ID',
    queryfunction = NULL,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infocolumn_uu = '3402dcb1-ec9b-46b3-a8a6-8248b89cc4f4';

  UPDATE ad_infocolumn SET isidentifier = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '79f02750-6838-46a3-bf5c-175b14666699';

  UPDATE ad_infocolumn SET
    columnname = 'BP_Name',
    selectclause = 'bp.Name',
    isactive = 'Y',
    isquerycriteria = 'Y',
    isdisplayed = 'Y',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infocolumn_uu = 'e4372e51-bedd-4cca-bfd6-ddac97def5ba';

  -- Disable SelectClause 0 / join-based / expression flag columns
  UPDATE ad_infocolumn SET
    isactive = 'N',
    isquerycriteria = 'N',
    isdisplayed = 'N',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND (
      selectclause = '0'
      OR ad_infocolumn_uu IN (
        'bf6693b4-56dd-4c1b-836d-3c0f517aad9d',
        '32efe3e4-4853-4656-bc45-a6e6672890ca',
        '3916bb24-c7be-4f78-96ee-77a711fba800',
        '2e35fde5-6164-4fd7-afc1-7d931d18bf64',
        'c404d78a-5e19-4d8c-bab8-480c86861398',
        'c4ab6130-0d64-4ce0-8be8-e6f7af56a98b',
        '40d550c2-4088-412d-8774-f2d2b2cd9247',
        '492b6870-a7b3-43f8-a9bd-7abf7b9efb49',
        '9ea712d2-845a-4dac-91cc-f4d641ec8072',
        '6a19cf0e-5972-49ae-9f56-bea3f649eb56',
        '40c40fdf-d0a1-4076-951f-f35e3deb463b',
        'a59bcf85-ab30-4e48-bd65-5d75140c706d',
        '228fdff4-c3f0-45c8-a2c1-900d05baf4c3',
        'a1b2c3d4-e5f6-7788-9900-aabbccdde001',
        'a1b2c3d4-e5f6-7788-9900-aabbccdde002'
      )
    );

  -- Core criteria / display
  UPDATE ad_infocolumn SET selectclause = 'bp.Value', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '92af7d4e-99ea-4939-8b8b-77bbb6599594';
  UPDATE ad_infocolumn SET selectclause = 'au.Name', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '79f02750-6838-46a3-bf5c-175b14666699';
  UPDATE ad_infocolumn SET selectclause = 'bp.IsEmployee', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y', defaultvalue = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '3d98756a-2000-48dd-88d6-3a7c93d82fc1';
  UPDATE ad_infocolumn SET selectclause = 'au.AbERP_isagencystaff', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = 'cd17a5c9-3430-4cbf-abba-7675900d4364';
  UPDATE ad_infocolumn SET selectclause = 'bp.AbERP_Gender_ID', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '22426da0-28ec-4047-8eff-0cb186e556b6';
  UPDATE ad_infocolumn SET selectclause = 'bp.C_Job_ID', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y',
    defaultvalue = NULL, updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = 'b70b7e4e-23f7-45e1-92b2-7b40e4e3c908';

  -- Clear nested @SQL defaults that hang WSearchEditor when opened from Shift
  UPDATE ad_infocolumn SET defaultvalue = NULL, updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND defaultvalue LIKE '%isEmployeeWindowOpenFromShift%';

  UPDATE ad_infocolumn SET isactive = 'Y', isquerycriteria = 'N', isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu IN (
    'f591a844-77ef-4351-a380-35d5e81f7e8f',
    '9084823c-2ed2-4f9e-b12b-7500fde11905',
    '459a25d1-4e5d-46e7-8532-d0788469d3b9',
    '42578105-dbb8-4f51-9e53-8af7e5073997'
  );

  UPDATE ad_infocolumn SET isactive = 'Y', isquerycriteria = 'N', isdisplayed = 'N', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu IN (
    '81496f36-dbc7-4c9d-a88e-a287bc019e0a',
    '904ffc84-b66a-4ec4-9984-5b85f9ad9545'
  );

  -- Related Info re-enabled in 08-enable-related-info.sql

  RAISE NOTICE 'Hotfix applied AD_InfoWindow_ID=% where=%', v_iw, v_where;
END $$;
