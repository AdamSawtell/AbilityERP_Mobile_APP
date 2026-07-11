-- Phase 2 eligibility without @StartDate@ / @ctx@ tokens.
-- Uses CURRENT_DATE-based EXISTS expressions as InfoColumns:
--   On Approved Leave  → query criteria, default N (hide people on approved leave)
--   Has Future Shift   → display only (officer visibility)
-- Safe: no context parse; no SelectClause '0'.

SET search_path TO adempiere;

DO $$
DECLARE
  v_iw NUMERIC;
  v_leave_sql TEXT;
  v_shift_sql TEXT;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf';

  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'AD_InfoWindow UU 2b4ab146-0809-47c6-96f3-8b841d60a6bf not found';
  END IF;

  v_leave_sql :=
    '(SELECT CASE WHEN EXISTS ('
    || 'SELECT 1 FROM AbERP_Unavailability_Leave ul '
    || 'WHERE ul.AbERP_User_Contact_ID=au.AD_User_ID AND ul.IsActive=''Y'' '
    || 'AND UPPER(COALESCE(ul.AbERP_ApproverStatus,''''))=''AP'' '
    || 'AND ul.EndDate >= CURRENT_DATE'
    || ') THEN ''Y'' ELSE ''N'' END)';

  v_shift_sql :=
    '(SELECT CASE WHEN EXISTS ('
    || 'SELECT 1 FROM AbERP_Rostered_ShiftStaff rss '
    || 'INNER JOIN AbERP_Rostered_Shift rs ON ('
    || 'rs.AbERP_Rostered_Shift_ID=rss.AbERP_Rostered_Shift_ID '
    || 'AND rs.IsActive=''Y'' AND COALESCE(rs.AbERP_isShiftRosteredTemplate,''N'')=''N'') '
    || 'WHERE rss.AbERP_User_Contact_ID=au.AD_User_ID AND rss.IsActive=''Y'' '
    || 'AND rs.EndDate >= CURRENT_DATE'
    || ') THEN ''Y'' ELSE ''N'' END)';

  -- Ensure / refresh On Approved Leave
  IF EXISTS (
    SELECT 1 FROM ad_infocolumn WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde001'
  ) THEN
    UPDATE ad_infocolumn SET
      name = 'On Approved Leave',
      description = 'Y if approved leave ends today or later (CURRENT_DATE). Default filter N hides these staff.',
      selectclause = v_leave_sql,
      columnname = 'AbERP_OnApprovedLeave',
      isactive = 'Y',
      isdisplayed = 'Y',
      isquerycriteria = 'Y',
      ishideinfocolumn = 'N',
      ismultiselectcriteria = 'N',
      isreadonly = 'N',
      iskey = 'N',
      isidentifier = 'N',
      ad_reference_id = 20,
      ad_reference_value_id = NULL,
      defaultvalue = 'N',
      queryoperator = '=',
      queryfunction = NULL,
      seqno = 300,
      seqnoselection = 80,
      updated = NOW(),
      updatedby = 100
    WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde001';
  ELSE
    INSERT INTO ad_infocolumn (
      ad_infocolumn_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, ad_infowindow_id, entitytype, selectclause, seqno, isdisplayed, isquerycriteria,
      ad_reference_id, ad_infocolumn_uu, columnname, isidentifier, seqnoselection, ismandatory, iskey,
      isreadonly, ishideinfocolumn, ismultiselectcriteria, defaultvalue, queryoperator
    ) VALUES (
      nextid((SELECT ad_sequence_id::integer FROM ad_sequence WHERE name = 'AD_InfoColumn' AND istableid = 'Y' LIMIT 1), 'N'::varchar),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'On Approved Leave', 'Y if approved leave ends today or later (CURRENT_DATE). Default filter N hides these staff.',
      v_iw, 'Ab_ERP', v_leave_sql, 300, 'Y', 'Y',
      20, 'a1b2c3d4-e5f6-7788-9900-aabbccdde001', 'AbERP_OnApprovedLeave', 'N', 80, 'N', 'N',
      'N', 'N', 'N', 'N', '='
    );
  END IF;

  -- Ensure / refresh Has Future Shift (display only)
  IF EXISTS (
    SELECT 1 FROM ad_infocolumn WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde002'
  ) THEN
    UPDATE ad_infocolumn SET
      name = 'Has Future Shift',
      description = 'Y if assigned to a non-template shift ending today or later.',
      selectclause = v_shift_sql,
      columnname = 'AbERP_HasFutureShift',
      isactive = 'Y',
      isdisplayed = 'Y',
      isquerycriteria = 'N',
      ishideinfocolumn = 'N',
      isreadonly = 'Y',
      iskey = 'N',
      isidentifier = 'N',
      ad_reference_id = 20,
      defaultvalue = NULL,
      seqno = 310,
      seqnoselection = 0,
      updated = NOW(),
      updatedby = 100
    WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde002';
  ELSE
    INSERT INTO ad_infocolumn (
      ad_infocolumn_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, ad_infowindow_id, entitytype, selectclause, seqno, isdisplayed, isquerycriteria,
      ad_reference_id, ad_infocolumn_uu, columnname, isidentifier, seqnoselection, ismandatory, iskey,
      isreadonly, ishideinfocolumn, ismultiselectcriteria
    ) VALUES (
      nextid((SELECT ad_sequence_id::integer FROM ad_sequence WHERE name = 'AD_InfoColumn' AND istableid = 'Y' LIMIT 1), 'N'::varchar),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Has Future Shift', 'Y if assigned to a non-template shift ending today or later.',
      v_iw, 'Ab_ERP', v_shift_sql, 310, 'Y', 'N',
      20, 'a1b2c3d4-e5f6-7788-9900-aabbccdde002', 'AbERP_HasFutureShift', 'N', 0, 'N', 'N',
      'Y', 'N', 'N'
    );
  END IF;

  -- Keep Show* SelectClause-0 toggles inactive (they break ZK)
  UPDATE ad_infocolumn SET isactive = 'N', isquerycriteria = 'N', isdisplayed = 'N', updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND columnname IN ('ShowUnavailabilityLeave', 'ShowOverlappingShifts');

  UPDATE ad_infowindow SET
    description = 'Fast staff picker for Shift Employee fill (lean User+BP). Default hides staff on approved leave.',
    help = 'Search employees/agency staff for Shift (Rostered) Employee. On Approved Leave defaults to N (hide). Set to blank/Y to include. Has Future Shift is informational. Related Info: Rostered Shift, Credentials, Alerts.',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw;

  RAISE NOTICE 'Eligibility criteria enabled on AD_InfoWindow_ID=%', v_iw;
END $$;
