-- AbERP Staff Rostering Info — column / criteria cleanup
-- Deactivates join-dependent criteria; keeps User+BP search fields; fixes Show* toggles.
-- Adds display-only On Leave / Overlap flags (subqueries — not in FROM joins).

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

  -- Key column for Search return value
  UPDATE ad_infocolumn SET
    iskey = 'Y',
    isidentifier = 'N',
    isdisplayed = 'Y',
    ishideinfocolumn = 'Y',
    isquerycriteria = 'N',
    selectclause = 'au.AD_User_ID',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '3402dcb1-ec9b-46b3-a8a6-8248b89cc4f4'; -- AD_User_ID

  -- Identifier stays on Name
  UPDATE ad_infocolumn SET
    isidentifier = 'Y',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '79f02750-6838-46a3-bf5c-175b14666699'; -- User Name

  -- Context-only date criteria (SelectClause 0 = context var only, not SELECT/JOIN)
  UPDATE ad_infocolumn SET
    selectclause = '0',
    isquerycriteria = 'Y',
    isdisplayed = 'N',
    ishideinfocolumn = 'N',
    ismultiselectcriteria = 'N',
    queryoperator = '=',
    queryfunction = NULL,
    ad_reference_id = 16,
    defaultvalue = '@SQL=SELECT CASE WHEN ''@+isEmployeeWindowOpenFromShift:N@''=''Y'' THEN ''@StartDate:''''@'' ELSE '''' END AS DefaultValue FROM DUAL',
    isactive = 'Y',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '9ea712d2-845a-4dac-91cc-f4d641ec8072'; -- StartDate

  UPDATE ad_infocolumn SET
    selectclause = '0',
    isquerycriteria = 'Y',
    isdisplayed = 'N',
    ishideinfocolumn = 'N',
    ismultiselectcriteria = 'N',
    queryoperator = '=',
    queryfunction = NULL,
    ad_reference_id = 16,
    defaultvalue = '@SQL=SELECT CASE WHEN ''@+isEmployeeWindowOpenFromShift:N@''=''Y'' THEN ''@EndDate:''''@'' ELSE '''' END AS DefaultValue FROM DUAL',
    isactive = 'Y',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '6a19cf0e-5972-49ae-9f56-bea3f649eb56'; -- EndDate

  -- Context-only current shift id (exclude self from overlap)
  UPDATE ad_infocolumn SET
    selectclause = '0',
    name = 'Current Rostered Shift',
    isquerycriteria = 'Y',
    isdisplayed = 'N',
    ismultiselectcriteria = 'N',
    queryoperator = '=',
    queryfunction = NULL,
    ad_reference_id = 19,
    defaultvalue = '@SQL=SELECT CASE WHEN ''@+isEmployeeWindowOpenFromShift:N@''=''Y'' THEN ''@AbERP_Rostered_Shift_ID:0@'' ELSE '''' END AS DefaultValue FROM DUAL',
    isactive = 'Y',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '40c40fdf-d0a1-4076-951f-f35e3deb463b'; -- was Rostered Shift Needs

  -- Show toggles: context-only Yes-No (default N = exclude leave / exclude overlap)
  UPDATE ad_infocolumn SET
    selectclause = '0',
    name = 'Show staff on leave',
    columnname = 'ShowUnavailabilityLeave',
    isquerycriteria = 'Y',
    isdisplayed = 'N',
    ismultiselectcriteria = 'N',
    queryoperator = '=',
    queryfunction = NULL,
    ad_reference_id = 20,
    ad_reference_value_id = NULL,
    defaultvalue = 'N',
    isactive = 'Y',
    seqnoselection = 200,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = 'a59bcf85-ab30-4e48-bd65-5d75140c706d';

  UPDATE ad_infocolumn SET
    selectclause = '0',
    name = 'Show overlapping shifts',
    columnname = 'ShowOverlappingShifts',
    isquerycriteria = 'Y',
    isdisplayed = 'N',
    ismultiselectcriteria = 'N',
    queryoperator = '=',
    queryfunction = NULL,
    ad_reference_id = 20,
    ad_reference_value_id = NULL,
    defaultvalue = 'N',
    isactive = 'Y',
    seqnoselection = 210,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '228fdff4-c3f0-45c8-a2c1-900d05baf4c3';

  -- Deactivate join-dependent criteria (credentials / needs / BI status / leave status filters)
  UPDATE ad_infocolumn SET
    isactive = 'N',
    isquerycriteria = 'N',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu IN (
      'bf6693b4-56dd-4c1b-836d-3c0f517aad9d', -- Shift Status (rs_v)
      '32efe3e4-4853-4656-bc45-a6e6672890ca', -- Credentials
      '3916bb24-c7be-4f78-96ee-77a711fba800', -- Master Location
      '2e35fde5-6164-4fd7-afc1-7d931d18bf64', -- Unavailability Status
      'c404d78a-5e19-4d8c-bab8-480c86861398', -- Ongoing Unavailability (inactive already)
      'c4ab6130-0d64-4ce0-8be8-e6f7af56a98b', -- Position Needs
      '40d550c2-4088-412d-8774-f2d2b2cd9247', -- Support Receiver Needs
      '492b6870-a7b3-43f8-a9bd-7abf7b9efb49'  -- Support Location Needs
    );

  -- Keep core User/BP criteria active and pointed at au/bp
  UPDATE ad_infocolumn SET selectclause = 'bp.Value', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '92af7d4e-99ea-4939-8b8b-77bbb6599594';
  UPDATE ad_infocolumn SET selectclause = 'au.Name', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '79f02750-6838-46a3-bf5c-175b14666699';
  UPDATE ad_infocolumn SET selectclause = 'bp.Name', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = 'e4372e51-bedd-4cca-bfd6-ddac97def5ba';
  UPDATE ad_infocolumn SET selectclause = 'bp.IsEmployee', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y', defaultvalue = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '3d98756a-2000-48dd-88d6-3a7c93d82fc1';
  UPDATE ad_infocolumn SET selectclause = 'au.AbERP_isagencystaff', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = 'cd17a5c9-3430-4cbf-abba-7675900d4364';
  UPDATE ad_infocolumn SET selectclause = 'bp.AbERP_Gender_ID', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '22426da0-28ec-4047-8eff-0cb186e556b6';
  UPDATE ad_infocolumn SET selectclause = 'bp.C_Job_ID', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y',
    defaultvalue = '@SQL=SELECT CASE WHEN ''@+isEmployeeWindowOpenFromShift:N@''=''Y'' THEN ''@C_Job_ID:null@'' ELSE NULL END AS DefaultValue FROM DUAL',
    updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = 'b70b7e4e-23f7-45e1-92b2-7b40e4e3c908';

  -- Display columns stay on bp/au
  UPDATE ad_infocolumn SET selectclause = 'bp.Supervisor_ID', isactive = 'Y', isquerycriteria = 'N', isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '81496f36-dbc7-4c9d-a88e-a287bc019e0a';
  UPDATE ad_infocolumn SET selectclause = 'bp.EMail', isactive = 'Y', isquerycriteria = 'N', isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = 'f591a844-77ef-4351-a380-35d5e81f7e8f';
  UPDATE ad_infocolumn SET selectclause = 'bp.Phone', isactive = 'Y', isquerycriteria = 'N', isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '9084823c-2ed2-4f9e-b12b-7500fde11905';
  UPDATE ad_infocolumn SET selectclause = 'bp.R_Status_ID', name = 'Status', isactive = 'Y', isquerycriteria = 'N', isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '459a25d1-4e5d-46e7-8532-d0788469d3b9';
  UPDATE ad_infocolumn SET selectclause = 'au.C_BPartner_ID', isactive = 'Y', isquerycriteria = 'N', isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '42578105-dbb8-4f51-9e53-8af7e5073997';
  UPDATE ad_infocolumn SET selectclause = 'au.C_BPartner_Location_ID', isactive = 'Y', isquerycriteria = 'N', isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '904ffc84-b66a-4ec4-9984-5b85f9ad9545';

END $$;

-- Display-only flags (correlated EXISTS — no FROM fan-out; no context vars in SelectClause)
INSERT INTO ad_infocolumn (
  ad_infocolumn_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
  name, description, ad_infowindow_id, entitytype, selectclause, seqno, isdisplayed, isquerycriteria,
  ad_reference_id, ad_infocolumn_uu, columnname, isidentifier, seqnoselection, ismandatory, iskey,
  isreadonly, ishideinfocolumn, ismultiselectcriteria
)
SELECT
  nextid((SELECT ad_sequence_id::integer FROM ad_sequence WHERE name = 'AD_InfoColumn' AND istableid = 'Y' LIMIT 1), 'N'::varchar),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'On Approved Leave', 'Y if any approved leave is current or future',
  iw.ad_infowindow_id, 'Ab_ERP',
  '(SELECT CASE WHEN EXISTS (SELECT 1 FROM AbERP_Unavailability_Leave ul WHERE ul.AbERP_User_Contact_ID=au.AD_User_ID AND ul.IsActive=''Y'' AND UPPER(COALESCE(ul.AbERP_ApproverStatus,''''))=''AP'' AND ul.EndDate >= CURRENT_DATE) THEN ''Y'' ELSE ''N'' END)',
  300, 'Y', 'N',
  20, 'a1b2c3d4-e5f6-7788-9900-aabbccdde001', 'AbERP_OnApprovedLeave', 'N', 0, 'N', 'N',
  'Y', 'N', 'N'
FROM ad_infowindow iw
WHERE iw.ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  AND NOT EXISTS (
    SELECT 1 FROM ad_infocolumn c
    WHERE c.ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde001'
  );

INSERT INTO ad_infocolumn (
  ad_infocolumn_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
  name, description, ad_infowindow_id, entitytype, selectclause, seqno, isdisplayed, isquerycriteria,
  ad_reference_id, ad_infocolumn_uu, columnname, isidentifier, seqnoselection, ismandatory, iskey,
  isreadonly, ishideinfocolumn, ismultiselectcriteria
)
SELECT
  nextid((SELECT ad_sequence_id::integer FROM ad_sequence WHERE name = 'AD_InfoColumn' AND istableid = 'Y' LIMIT 1), 'N'::varchar),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'Has Future Shift', 'Y if assigned to a non-template shift starting today or later',
  iw.ad_infowindow_id, 'Ab_ERP',
  '(SELECT CASE WHEN EXISTS (SELECT 1 FROM AbERP_Rostered_ShiftStaff rss INNER JOIN AbERP_Rostered_Shift rs ON (rs.AbERP_Rostered_Shift_ID=rss.AbERP_Rostered_Shift_ID AND rs.IsActive=''Y'' AND COALESCE(rs.AbERP_isShiftRosteredTemplate,''N'')=''N'') WHERE rss.AbERP_User_Contact_ID=au.AD_User_ID AND rss.IsActive=''Y'' AND rs.EndDate >= CURRENT_DATE) THEN ''Y'' ELSE ''N'' END)',
  310, 'Y', 'N',
  20, 'a1b2c3d4-e5f6-7788-9900-aabbccdde002', 'AbERP_HasFutureShift', 'N', 0, 'N', 'N',
  'Y', 'N', 'N'
FROM ad_infowindow iw
WHERE iw.ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  AND NOT EXISTS (
    SELECT 1 FROM ad_infocolumn c
    WHERE c.ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde002'
  );
