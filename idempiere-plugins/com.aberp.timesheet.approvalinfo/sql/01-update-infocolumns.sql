-- SAW010: Timesheet Approval Info Window column cleanup (#901558)
-- AD_InfoWindow_UU = 40d6a2d7-3bbc-431e-940c-ce75829a68e4 (seed ID 1000033)
--
-- 1) Hide result-grid display for: Shift Cost, Name, Employee (IsEmployee), Activity
--    Keep search criteria where they already exist (Activity, Employee).
-- 2) Hide duplicate Business Partner from result grid; keep as search criteria.
--    Retain Employee (User) / Agency Staff as the visible staff column.
-- 3) Add Break Start / Break End display columns after Shift Type (seqno 72 / 74)
--    using existing t.AbERP_Break_Start / t.AbERP_Break_End (Date+Time ref 16).
--
-- Does NOT touch AbERP_TimesheetAndExpenses_ID (InfoProcess bind column).

SET search_path TO adempiere;

DO $$
DECLARE
  v_iw NUMERIC;
  v_el_break_start NUMERIC;
  v_el_break_end NUMERIC;
  v_uu_break_start CONSTANT VARCHAR := 'c4e8a1b2-5d6f-4a7c-9e01-2b3d4f5a6c70';
  v_uu_break_end   CONSTANT VARCHAR := 'd5f9b2c3-6e70-4b8d-a012-3c4e5f6a7b81';
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4';

  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'AD_InfoWindow UU 40d6a2d7-3bbc-431e-940c-ce75829a68e4 not found';
  END IF;

  SELECT ad_element_id INTO v_el_break_start
  FROM ad_element
  WHERE ad_element_uu = '27c45dc9-aaef-40cb-8306-a2f5ebdeae2b'
     OR columnname = 'AbERP_Break_Start'
  ORDER BY CASE WHEN ad_element_uu = '27c45dc9-aaef-40cb-8306-a2f5ebdeae2b' THEN 0 ELSE 1 END
  LIMIT 1;

  SELECT ad_element_id INTO v_el_break_end
  FROM ad_element
  WHERE ad_element_uu = 'ad62182e-9dfb-46e5-9f2b-89a3232276ca'
     OR columnname = 'AbERP_Break_End'
  ORDER BY CASE WHEN ad_element_uu = 'ad62182e-9dfb-46e5-9f2b-89a3232276ca' THEN 0 ELSE 1 END
  LIMIT 1;

  IF v_el_break_start IS NULL OR v_el_break_end IS NULL THEN
    RAISE EXCEPTION
      'AD_Element for AbERP_Break_Start / AbERP_Break_End not found (start=%, end=%).',
      v_el_break_start, v_el_break_end;
  END IF;

  -------------------------------------------------------------------------
  -- Hide display-only / duplicate result columns (keep criteria where set)
  -------------------------------------------------------------------------

  -- Shift Cost (display only — no criteria)
  UPDATE ad_infocolumn SET
    isdisplayed = 'N',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '39fb0ffb-58e5-46e7-8966-48b2fb223b86'
    AND columnname = 'AbERP_Shift_Cost';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Shift Cost InfoColumn UU 39fb0ffb-58e5-46e7-8966-48b2fb223b86 not found on Info Window %', v_iw;
  END IF;

  -- Name (receivers aggregate — display only)
  UPDATE ad_infocolumn SET
    isdisplayed = 'N',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '6f1c18f1-43b5-4cab-8f13-8d5960c602cd'
    AND columnname = 'Name';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Name InfoColumn UU 6f1c18f1-43b5-4cab-8f13-8d5960c602cd not found on Info Window %', v_iw;
  END IF;

  -- Employee (IsEmployee Yes/No) — hide grid; keep as search filter
  UPDATE ad_infocolumn SET
    isdisplayed = 'N',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '750b7e9f-1299-49c6-8477-616de3c4b0de'
    AND columnname = 'IsEmployee';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Employee (IsEmployee) InfoColumn UU 750b7e9f-1299-49c6-8477-616de3c4b0de not found on Info Window %', v_iw;
  END IF;

  -- Activity — hide grid; keep as search filter
  UPDATE ad_infocolumn SET
    isdisplayed = 'N',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '890d8791-326b-4092-beb5-9046587d7556'
    AND columnname = 'C_Activity_ID';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Activity InfoColumn UU 890d8791-326b-4092-beb5-9046587d7556 not found on Info Window %', v_iw;
  END IF;

  -- Business Partner — duplicate of Employee (User)/Agency Staff in grid; keep filter
  UPDATE ad_infocolumn SET
    isdisplayed = 'N',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '61e09e5f-222b-4bb6-bb29-ae8fb785f4e9'
    AND columnname = 'C_BPartner_ID';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Business Partner InfoColumn UU 61e09e5f-222b-4bb6-bb29-ae8fb785f4e9 not found on Info Window %', v_iw;
  END IF;

  -- Ensure preferred staff column stays visible (Employee User / Agency Staff)
  UPDATE ad_infocolumn SET
    isdisplayed = 'Y',
    isquerycriteria = 'Y',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = 'a7d9bd78-d602-4c53-a2ee-11a92f9600b1'
    AND columnname = 'AbERP_User_Contact_ID';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Employee (User)/Agency Staff InfoColumn UU a7d9bd78-d602-4c53-a2ee-11a92f9600b1 not found on Info Window %', v_iw;
  END IF;

  -------------------------------------------------------------------------
  -- Break Start (after Shift Type seqno 70 → 72)
  -------------------------------------------------------------------------
  IF EXISTS (SELECT 1 FROM ad_infocolumn WHERE ad_infocolumn_uu = v_uu_break_start) THEN
    UPDATE ad_infocolumn SET
      name = 'Break Start',
      description = 'Break start date/time from the timesheet',
      help = 'Displays AbERP_TimesheetAndExpenses.AbERP_Break_Start. Blank when no break is recorded.',
      ad_infowindow_id = v_iw,
      entitytype = 'Ab_ERP',
      selectclause = 't.AbERP_Break_Start',
      seqno = 72,
      isdisplayed = 'Y',
      isquerycriteria = 'N',
      ad_element_id = v_el_break_start,
      ad_reference_id = 16, -- Date+Time
      ad_reference_value_id = NULL,
      columnname = 'AbERP_Break_Start',
      queryoperator = NULL,
      queryfunction = NULL,
      isidentifier = 'N',
      seqnoselection = 0,
      defaultvalue = NULL,
      ismandatory = 'N',
      iskey = 'N',
      isreadonly = 'Y',
      ishideinfocolumn = 'N',
      ismultiselectcriteria = 'N',
      isactive = 'Y',
      iscentrallymaintained = 'Y',
      updated = NOW(),
      updatedby = 100
    WHERE ad_infocolumn_uu = v_uu_break_start;
  ELSE
    INSERT INTO ad_infocolumn (
      ad_infocolumn_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, help, ad_infowindow_id, entitytype, selectclause, seqno,
      isdisplayed, isquerycriteria, ad_element_id, ad_reference_id, ad_infocolumn_uu,
      ad_reference_value_id, columnname, queryoperator, isidentifier, seqnoselection,
      defaultvalue, ismandatory, iskey, isreadonly, ishideinfocolumn, ismultiselectcriteria,
      iscentrallymaintained
    ) VALUES (
      nextid((SELECT ad_sequence_id::integer FROM ad_sequence WHERE name = 'AD_InfoColumn' AND istableid = 'Y' LIMIT 1), 'N'::varchar),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Break Start', 'Break start date/time from the timesheet',
      'Displays AbERP_TimesheetAndExpenses.AbERP_Break_Start. Blank when no break is recorded.',
      v_iw, 'Ab_ERP', 't.AbERP_Break_Start', 72,
      'Y', 'N', v_el_break_start, 16, v_uu_break_start,
      NULL, 'AbERP_Break_Start', NULL, 'N', 0,
      NULL, 'N', 'N', 'Y', 'N', 'N',
      'Y'
    );
  END IF;

  -------------------------------------------------------------------------
  -- Break End (after Break Start → seqno 74)
  -------------------------------------------------------------------------
  IF EXISTS (SELECT 1 FROM ad_infocolumn WHERE ad_infocolumn_uu = v_uu_break_end) THEN
    UPDATE ad_infocolumn SET
      name = 'Break End',
      description = 'Break end date/time from the timesheet',
      help = 'Displays AbERP_TimesheetAndExpenses.AbERP_Break_End. Blank when no break is recorded.',
      ad_infowindow_id = v_iw,
      entitytype = 'Ab_ERP',
      selectclause = 't.AbERP_Break_End',
      seqno = 74,
      isdisplayed = 'Y',
      isquerycriteria = 'N',
      ad_element_id = v_el_break_end,
      ad_reference_id = 16, -- Date+Time
      ad_reference_value_id = NULL,
      columnname = 'AbERP_Break_End',
      queryoperator = NULL,
      queryfunction = NULL,
      isidentifier = 'N',
      seqnoselection = 0,
      defaultvalue = NULL,
      ismandatory = 'N',
      iskey = 'N',
      isreadonly = 'Y',
      ishideinfocolumn = 'N',
      ismultiselectcriteria = 'N',
      isactive = 'Y',
      iscentrallymaintained = 'Y',
      updated = NOW(),
      updatedby = 100
    WHERE ad_infocolumn_uu = v_uu_break_end;
  ELSE
    INSERT INTO ad_infocolumn (
      ad_infocolumn_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, help, ad_infowindow_id, entitytype, selectclause, seqno,
      isdisplayed, isquerycriteria, ad_element_id, ad_reference_id, ad_infocolumn_uu,
      ad_reference_value_id, columnname, queryoperator, isidentifier, seqnoselection,
      defaultvalue, ismandatory, iskey, isreadonly, ishideinfocolumn, ismultiselectcriteria,
      iscentrallymaintained
    ) VALUES (
      nextid((SELECT ad_sequence_id::integer FROM ad_sequence WHERE name = 'AD_InfoColumn' AND istableid = 'Y' LIMIT 1), 'N'::varchar),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Break End', 'Break end date/time from the timesheet',
      'Displays AbERP_TimesheetAndExpenses.AbERP_Break_End. Blank when no break is recorded.',
      v_iw, 'Ab_ERP', 't.AbERP_Break_End', 74,
      'Y', 'N', v_el_break_end, 16, v_uu_break_end,
      NULL, 'AbERP_Break_End', NULL, 'N', 0,
      NULL, 'N', 'N', 'Y', 'N', 'N',
      'Y'
    );
  END IF;

  UPDATE ad_infowindow SET
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw;

  RAISE NOTICE 'SAW010 applied: Info Window % — hid Shift Cost/Name/Employee/Activity/Business Partner display; added Break Start/End.', v_iw;
END $$;
