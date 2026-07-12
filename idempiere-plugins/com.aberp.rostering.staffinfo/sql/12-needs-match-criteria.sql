-- Show Unmatched Staff tickbox + help for Related Rostering Needs matching.
-- The Yes/No criterion is a UI flag only. SelectClause is constant 'N' so a failed
-- clear still yields 'N'='N' (true). Java clears the editor + strips 'N'='Y' when ticked.
-- Do not use au.IsActive (default N → au.IsActive='N' → 0 rows) or bare 0.
-- StaffRosteringInfoWindow applies EXISTS match in Java against AbERP_Related_Rostering_Needs_V.

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

  IF EXISTS (
    SELECT 1 FROM ad_infocolumn WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde003'
  ) THEN
    UPDATE ad_infocolumn SET
      name = 'Show Unmatched Staff',
      description = 'When N (default), only staff matching Related Rostering Needs are shown. Credentials must be active and valid for the shift Start/End (not just today). Set Y to include unmatched staff.',
      help = 'Related needs come from the shift Related Rostering Needs tab (location, support receiver, shift rules). Default hides staff missing required credentials (must cover the shift dates), gender mismatch, and restricted employees. Tick Y to list everyone (still applies leave/overlap filters).',
      selectclause = '''N''',
      columnname = 'AbERP_ShowUnmatchedStaff',
      isactive = 'Y',
      isdisplayed = 'N',
      isquerycriteria = 'Y',
      ishideinfocolumn = 'Y',
      ismultiselectcriteria = 'N',
      isreadonly = 'N',
      iskey = 'N',
      isidentifier = 'N',
      ad_reference_id = 20,
      ad_reference_value_id = NULL,
      defaultvalue = 'N',
      queryoperator = '=',
      queryfunction = NULL,
      seqno = 320,
      seqnoselection = 90,
      updated = NOW(),
      updatedby = 100
    WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde003';
  ELSE
    INSERT INTO ad_infocolumn (
      ad_infocolumn_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, help, ad_infowindow_id, entitytype, selectclause, seqno, isdisplayed, isquerycriteria,
      ad_reference_id, ad_infocolumn_uu, columnname, isidentifier, seqnoselection, ismandatory, iskey,
      isreadonly, ishideinfocolumn, ismultiselectcriteria, defaultvalue, queryoperator
    ) VALUES (
      nextid((SELECT ad_sequence_id::integer FROM ad_sequence WHERE name = 'AD_InfoColumn' AND istableid = 'Y' LIMIT 1), 'N'::varchar),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Show Unmatched Staff',
      'When N (default), only staff matching Related Rostering Needs are shown. Credentials must be active and valid for the shift Start/End (not just today). Set Y to include unmatched staff.',
      'Related needs come from the shift Related Rostering Needs tab (location, support receiver, shift rules). Default hides staff missing required credentials (must cover the shift dates), gender mismatch, and restricted employees. Tick Y to list everyone (still applies leave/overlap filters).',
      v_iw, 'Ab_ERP', '''N''', 320, 'N', 'Y',
      20, 'a1b2c3d4-e5f6-7788-9900-aabbccdde003', 'AbERP_ShowUnmatchedStaff', 'N', 90, 'N', 'N',
      'N', 'Y', 'N', 'N', '='
    );
  END IF;

  UPDATE ad_infowindow SET
    description = 'Fast staff picker for Shift Employee fill. Matches Related Rostering Needs by default; credentials valid for shift dates; leave/overlap by shift window.',
    help = 'Find by User Name (wildcards auto-added). From Shift Employee: hides approved leave / overlapping roster for the shift window; shows only staff matching Related Rostering Needs (credentials must be active and cover the shift Start/End, plus gender / restricted employee) unless Show Unmatched Staff is Y. Leave/overlap for the parent shift is filtered in Java. Banner shows shift times and needs summary.',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw;

  RAISE NOTICE 'Show Unmatched Staff criterion enabled on AD_InfoWindow_ID=%', v_iw;
END $$;
