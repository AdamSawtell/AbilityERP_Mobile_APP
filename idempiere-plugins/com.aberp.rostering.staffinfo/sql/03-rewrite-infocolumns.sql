-- AbERP Staff Rostering Info — column / criteria cleanup
-- Keeps lean User+BP search fields. Does NOT enable SelectClause='0' context
-- columns or nested @SQL= defaults (those hang WSearchEditor from Shift).

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

  -- Key column for Search return value (Integer/ID for ZK keyView)
  UPDATE ad_infocolumn SET
    iskey = 'Y',
    isidentifier = 'N',
    isdisplayed = 'Y',
    ishideinfocolumn = 'Y',
    isquerycriteria = 'N',
    ad_reference_id = 11,
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

  -- Deactivate SelectClause 0 / join-dependent / nested-context criteria
  -- (SelectClause '0' → StringIndexOutOfBounds; nested @SQL= → Search spinner hang)
  UPDATE ad_infocolumn SET
    isactive = 'N',
    isquerycriteria = 'N',
    isdisplayed = 'N',
    defaultvalue = NULL,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND (
      selectclause = '0'
      OR defaultvalue LIKE '%isEmployeeWindowOpenFromShift%'
      OR ad_infocolumn_uu IN (
        'bf6693b4-56dd-4c1b-836d-3c0f517aad9d', -- Shift Status (rs_v)
        '32efe3e4-4853-4656-bc45-a6e6672890ca', -- Credentials
        '3916bb24-c7be-4f78-96ee-77a711fba800', -- Master Location
        '2e35fde5-6164-4fd7-afc1-7d931d18bf64', -- Unavailability Status
        'c404d78a-5e19-4d8c-bab8-480c86861398', -- Ongoing Unavailability
        'c4ab6130-0d64-4ce0-8be8-e6f7af56a98b', -- Position Needs
        '40d550c2-4088-412d-8774-f2d2b2cd9247', -- Support Receiver Needs
        '492b6870-a7b3-43f8-a9bd-7abf7b9efb49', -- Support Location Needs
        '9ea712d2-845a-4dac-91cc-f4d641ec8072', -- StartDate
        '6a19cf0e-5972-49ae-9f56-bea3f649eb56', -- EndDate
        '40c40fdf-d0a1-4076-951f-f35e3deb463b', -- Current Rostered Shift
        'a59bcf85-ab30-4e48-bd65-5d75140c706d', -- Show leave
        '228fdff4-c3f0-45c8-a2c1-900d05baf4c3'  -- Show overlap
      )
    );

  -- Core User/BP criteria
  UPDATE ad_infocolumn SET selectclause = 'bp.Value', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y',
    defaultvalue = NULL, updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '92af7d4e-99ea-4939-8b8b-77bbb6599594';
  UPDATE ad_infocolumn SET selectclause = 'au.Name', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y',
    defaultvalue = NULL, updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '79f02750-6838-46a3-bf5c-175b14666699';
  UPDATE ad_infocolumn SET selectclause = 'bp.Name', columnname = 'BP_Name', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y',
    defaultvalue = NULL, updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = 'e4372e51-bedd-4cca-bfd6-ddac97def5ba';
  UPDATE ad_infocolumn SET selectclause = 'bp.IsEmployee', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y',
    defaultvalue = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '3d98756a-2000-48dd-88d6-3a7c93d82fc1';
  UPDATE ad_infocolumn SET selectclause = 'au.AbERP_isagencystaff', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y',
    defaultvalue = NULL, updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = 'cd17a5c9-3430-4cbf-abba-7675900d4364';
  UPDATE ad_infocolumn SET selectclause = 'bp.AbERP_Gender_ID', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y',
    defaultvalue = NULL, updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '22426da0-28ec-4047-8eff-0cb186e556b6';
  UPDATE ad_infocolumn SET selectclause = 'bp.C_Job_ID', isactive = 'Y', isquerycriteria = 'Y', isdisplayed = 'Y',
    defaultvalue = NULL, updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = 'b70b7e4e-23f7-45e1-92b2-7b40e4e3c908';

  -- Display columns
  UPDATE ad_infocolumn SET selectclause = 'bp.Supervisor_ID', isactive = 'Y', isquerycriteria = 'N', isdisplayed = 'N',
    updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '81496f36-dbc7-4c9d-a88e-a287bc019e0a';
  UPDATE ad_infocolumn SET selectclause = 'bp.EMail', isactive = 'Y', isquerycriteria = 'N', isdisplayed = 'Y',
    updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = 'f591a844-77ef-4351-a380-35d5e81f7e8f';
  UPDATE ad_infocolumn SET selectclause = 'bp.Phone', isactive = 'Y', isquerycriteria = 'N', isdisplayed = 'Y',
    updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '9084823c-2ed2-4f9e-b12b-7500fde11905';
  UPDATE ad_infocolumn SET selectclause = 'bp.R_Status_ID', name = 'Status', isactive = 'Y', isquerycriteria = 'N', isdisplayed = 'Y',
    updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '459a25d1-4e5d-46e7-8532-d0788469d3b9';
  UPDATE ad_infocolumn SET selectclause = 'au.C_BPartner_ID', isactive = 'Y', isquerycriteria = 'N', isdisplayed = 'Y',
    updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '42578105-dbb8-4f51-9e53-8af7e5073997';
  UPDATE ad_infocolumn SET selectclause = 'au.C_BPartner_Location_ID', isactive = 'Y', isquerycriteria = 'N', isdisplayed = 'N',
    updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_uu = '904ffc84-b66a-4ec4-9984-5b85f9ad9545';

  -- Clear any remaining nested shift-context defaults
  UPDATE ad_infocolumn SET defaultvalue = NULL, updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND defaultvalue LIKE '%isEmployeeWindowOpenFromShift%';

  -- Related Info re-enabled in 08-enable-related-info.sql (do not deactivate here)

END $$;
