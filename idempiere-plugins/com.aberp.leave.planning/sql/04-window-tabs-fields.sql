-- =============================================================================
-- SAW016 — Leave Planning window, tabs, fields
-- Fixed UUs:
--   Window 16a01602-c0d4-4f01-8e15-000000000001
--   Tab1   16a01603-c0d4-4f01-8e15-000000000001
--   Tab2   16a01604-c0d4-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

CREATE OR REPLACE FUNCTION pg_temp.saw016_upsert_field(
  p_tab_id INTEGER,
  p_uu TEXT,
  p_columnname TEXT,
  p_name TEXT,
  p_seqno INTEGER,
  p_displayed CHAR,
  p_readonly CHAR DEFAULT 'N',
  p_displaylogic TEXT DEFAULT NULL,
  p_sameline CHAR DEFAULT 'N',
  p_gridseq INTEGER DEFAULT NULL,
  p_displayedgrid CHAR DEFAULT NULL
) RETURNS void AS $$
DECLARE
  v_col_id INTEGER;
  v_field_id INTEGER;
  v_table_id INTEGER;
BEGIN
  SELECT ad_table_id INTO v_table_id FROM ad_tab WHERE ad_tab_id = p_tab_id;
  SELECT ad_column_id INTO v_col_id FROM ad_column
  WHERE ad_table_id = v_table_id AND columnname = p_columnname;
  IF v_col_id IS NULL THEN
    RAISE NOTICE 'SAW016 skip field % — column missing on tab %', p_columnname, p_tab_id;
    RETURN;
  END IF;

  SELECT ad_field_id INTO v_field_id FROM ad_field WHERE ad_field_uu = p_uu;
  IF v_field_id IS NULL THEN
    SELECT ad_field_id INTO v_field_id FROM ad_field
    WHERE ad_tab_id = p_tab_id AND ad_column_id = v_col_id;
  END IF;

  IF v_field_id IS NULL THEN
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, iscentrallymaintained,
      ad_tab_id, ad_column_id, ad_fieldgroup_id,
      isdisplayed, displaylogic, displaylength, isreadonly,
      seqno, sortno, issameline, isheading, isfieldonly, isencrypted,
      entitytype, obscuretype, ad_reference_id, ismandatory,
      isdisplayedgrid, seqnogrid, xposition, columnspan, numlines,
      isquickentry, isdefaultfocus, ad_field_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, NULL, 'Y',
      p_tab_id, v_col_id, NULL,
      p_displayed, p_displaylogic, 0, p_readonly,
      p_seqno, NULL, p_sameline, 'N', 'N', 'N',
      'Ab_ERP', NULL, NULL, NULL,
      COALESCE(p_displayedgrid, p_displayed), COALESCE(p_gridseq, p_seqno), 1, 2, 1,
      'N', 'N', p_uu
    );
  ELSE
    UPDATE ad_field SET
      name = p_name,
      isdisplayed = p_displayed,
      isreadonly = p_readonly,
      displaylogic = p_displaylogic,
      seqno = p_seqno,
      issameline = p_sameline,
      isdisplayedgrid = COALESCE(p_displayedgrid, p_displayed),
      seqnogrid = COALESCE(p_gridseq, p_seqno),
      entitytype = 'Ab_ERP',
      ad_field_uu = COALESCE(ad_field_uu, p_uu),
      updated = NOW(),
      updatedby = 100
    WHERE ad_field_id = v_field_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_window_uu CONSTANT TEXT := '16a01602-c0d4-4f01-8e15-000000000001';
  v_tab1_uu   CONSTANT TEXT := '16a01603-c0d4-4f01-8e15-000000000001';
  v_tab2_uu   CONSTANT TEXT := '16a01604-c0d4-4f01-8e15-000000000001';
  v_window_id INTEGER;
  v_tab1_id INTEGER;
  v_tab2_id INTEGER;
  v_plan_table INTEGER;
  v_leave_table INTEGER;
  v_where TEXT;
  v_ref_ut INTEGER;
BEGIN
  SELECT ad_table_id INTO v_plan_table FROM ad_table WHERE tablename = 'AbERP_Leave_Planning';
  SELECT ad_table_id INTO v_leave_table FROM ad_table WHERE tablename = 'AbERP_Unavailability_Leave';
  IF v_plan_table IS NULL OR v_leave_table IS NULL THEN
    RAISE EXCEPTION 'SAW016: planning or leave table missing in AD';
  END IF;

  -- Fix Filter Leave Type to Table reference (column name is not TableDirect-friendly)
  SELECT ad_reference_id INTO v_ref_ut FROM ad_reference
  WHERE name = 'AbERP_Unavailability_Type' OR name ILIKE '%Unavailability Type%'
  LIMIT 1;
  IF v_ref_ut IS NULL THEN
    INSERT INTO ad_reference (
      ad_reference_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, validationtype, vformat, entitytype, ad_reference_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Reference' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP Leave Planning Unavailability Type',
      'Table ref AbERP_Unavailability_Type', NULL, 'T', NULL, 'Ab_ERP',
      '16a01607-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_reference_id INTO v_ref_ut;

    INSERT INTO ad_ref_table (
      ad_reference_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      ad_table_id, ad_key, ad_display, isvaluedisplayed, entitytype, whereclause, orderbyclause
    ) VALUES (
      v_ref_ut, 0, 0, 'Y', NOW(), 100, NOW(), 100,
      (SELECT ad_table_id FROM ad_table WHERE tablename='AbERP_Unavailability_Type'),
      (SELECT ad_column_id FROM ad_column c JOIN ad_table t ON t.ad_table_id=c.ad_table_id
        WHERE t.tablename='AbERP_Unavailability_Type' AND c.columnname='AbERP_Unavailability_Type_ID'),
      (SELECT ad_column_id FROM ad_column c JOIN ad_table t ON t.ad_table_id=c.ad_table_id
        WHERE t.tablename='AbERP_Unavailability_Type' AND c.columnname='Name'),
      'N', 'Ab_ERP', 'IsActive=''Y''', 'Name'
    );
  END IF;

  UPDATE ad_column SET
    ad_reference_id = 18,
    ad_reference_value_id = v_ref_ut,
    updated = NOW(),
    updatedby = 100
  WHERE ad_table_id = v_plan_table
    AND columnname = 'AbERP_FilterUnavailability_Type_ID';

  -- Default All Locations = N
  UPDATE ad_column SET defaultvalue = 'N', updated = NOW()
  WHERE ad_table_id = v_plan_table AND columnname = 'IsAllLocations';

  -- Window
  SELECT ad_window_id INTO v_window_id FROM ad_window WHERE ad_window_uu = v_window_uu;
  IF v_window_id IS NULL THEN
    SELECT ad_window_id INTO v_window_id FROM ad_window WHERE name = 'Leave Planning' AND entitytype = 'Ab_ERP';
  END IF;

  IF v_window_id IS NULL THEN
    INSERT INTO ad_window (
      ad_window_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, windowtype, issotrx,
      entitytype, processing, isdefault, isbetafunctionality,
      ad_window_uu, titlelogic
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Window' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Leave Planning',
      'Plan and review employee leave overlapping a date range and service locations',
      'Set Start/End dates and service locations (or All Locations). Leave Records shows overlapping AbERP_Unavailability_Leave rows. Use Filter Approver Status / Leave Type to narrow the detail tab. Open a leave row to submit or set Approver Status using existing controls.',
      'M', 'Y',
      'Ab_ERP', 'N', 'N', 'N',
      v_window_uu, NULL
    ) RETURNING ad_window_id INTO v_window_id;
  ELSE
    UPDATE ad_window SET
      name = 'Leave Planning',
      description = 'Plan and review employee leave overlapping a date range and service locations',
      entitytype = 'Ab_ERP',
      ad_window_uu = COALESCE(ad_window_uu, v_window_uu),
      updated = NOW(),
      updatedby = 100
    WHERE ad_window_id = v_window_id;
  END IF;

  UPDATE ad_table SET ad_window_id = v_window_id, updated = NOW()
  WHERE ad_table_id = v_plan_table;

  -- Tab 1: Planning criteria
  SELECT ad_tab_id INTO v_tab1_id FROM ad_tab WHERE ad_tab_uu = v_tab1_uu;
  IF v_tab1_id IS NULL THEN
    SELECT ad_tab_id INTO v_tab1_id FROM ad_tab
    WHERE ad_window_id = v_window_id AND ad_table_id = v_plan_table AND seqno = 10;
  END IF;

  IF v_tab1_id IS NULL THEN
    INSERT INTO ad_tab (
      ad_tab_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, ad_table_id, ad_window_id, seqno,
      tablevel, issinglerow, isinfotab, istranslationtab, isreadonly,
      hastree, processing, ad_process_id, issorttab, entitytype,
      isinsertrecord, isadvancedtab, ad_tab_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Tab' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Leave Planning', 'Planning criteria and summaries', NULL,
      v_plan_table, v_window_id, 10,
      0, 'Y', 'N', 'N', 'N',
      'N', 'N', NULL, 'N', 'Ab_ERP',
      'Y', 'N', v_tab1_uu
    ) RETURNING ad_tab_id INTO v_tab1_id;
  ELSE
    UPDATE ad_tab SET
      name = 'Leave Planning',
      ad_window_id = v_window_id,
      ad_table_id = v_plan_table,
      entitytype = 'Ab_ERP',
      ad_tab_uu = COALESCE(ad_tab_uu, v_tab1_uu),
      updated = NOW()
    WHERE ad_tab_id = v_tab1_id;
  END IF;

  -- Tab 2: Leave records (real leave table, filtered by parent context)
  v_where :=
    'AbERP_Unavailability_Leave.IsActive=''Y'''
    || ' AND TRUNC(AbERP_Unavailability_Leave.StartDate) <= ''@EndDate@'''
    || ' AND TRUNC(AbERP_Unavailability_Leave.EndDate) >= ''@StartDate@'''
    || ' AND ('
    || ' ''@IsAllLocations@''=''Y'''
    || ' OR ('
    || ' COALESCE(''@C_BPartner_Location_IDs@'','''') <> '''''
    || ' AND EXISTS (SELECT 1 FROM AD_User u WHERE u.AD_User_ID=AbERP_Unavailability_Leave.AbERP_User_Contact_ID'
    || ' AND u.C_BPartner_Location_ID IN (@C_BPartner_Location_IDs@))'
    || ' )'
    || ' )'
    || ' AND (COALESCE(''@AbERP_FilterApproverStatus@'','''')='''''
    || ' OR AbERP_Unavailability_Leave.AbERP_ApproverStatus=''@AbERP_FilterApproverStatus@'')'
    || ' AND (@AbERP_FilterUnavailability_Type_ID@=0'
    || ' OR AbERP_Unavailability_Leave.AbERP_Unavailability_Type_ID=@AbERP_FilterUnavailability_Type_ID@)';

  SELECT ad_tab_id INTO v_tab2_id FROM ad_tab WHERE ad_tab_uu = v_tab2_uu;
  IF v_tab2_id IS NULL THEN
    SELECT ad_tab_id INTO v_tab2_id FROM ad_tab
    WHERE ad_window_id = v_window_id AND ad_table_id = v_leave_table AND seqno = 20;
  END IF;

  IF v_tab2_id IS NULL THEN
    INSERT INTO ad_tab (
      ad_tab_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, ad_table_id, ad_window_id, seqno,
      tablevel, issinglerow, isinfotab, istranslationtab, isreadonly,
      hastree, whereclause, orderbyclause,
      processing, issorttab, entitytype,
      isinsertrecord, isadvancedtab, ad_tab_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Tab' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Leave Records',
      'Leave overlapping the planning period and locations',
      'Same AbERP_Unavailability_Leave records as Unavailability & Leave. Submit Leave and Approver Status use existing logic. No duplicate leave rows are created.',
      v_leave_table, v_window_id, 20,
      0, 'N', 'N', 'N', 'N',
      'N', v_where, 'AbERP_ApproverStatus, StartDate, AbERP_User_Contact_ID',
      'N', 'N', 'Ab_ERP',
      'N', 'N', v_tab2_uu
    ) RETURNING ad_tab_id INTO v_tab2_id;
  ELSE
    UPDATE ad_tab SET
      name = 'Leave Records',
      whereclause = v_where,
      orderbyclause = 'AbERP_ApproverStatus, StartDate, AbERP_User_Contact_ID',
      isinsertrecord = 'N',
      entitytype = 'Ab_ERP',
      ad_tab_uu = COALESCE(ad_tab_uu, v_tab2_uu),
      updated = NOW()
    WHERE ad_tab_id = v_tab2_id;
  END IF;

  -- Header fields
  PERFORM pg_temp.saw016_upsert_field(v_tab1_id,'16a016f1-0001-4f01-8e15-000000000001','AD_Client_ID','Client',10,'Y','Y',NULL,'N',NULL,'N');
  PERFORM pg_temp.saw016_upsert_field(v_tab1_id,'16a016f1-0002-4f01-8e15-000000000001','AD_Org_ID','Organization',20,'Y','N',NULL,'Y',NULL,'N');
  PERFORM pg_temp.saw016_upsert_field(v_tab1_id,'16a016f1-0003-4f01-8e15-000000000001','Name','Name',30,'Y','N',NULL,'N',10,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab1_id,'16a016f1-0004-4f01-8e15-000000000001','StartDate','Start Date',40,'Y','N',NULL,'N',20,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab1_id,'16a016f1-0005-4f01-8e15-000000000001','EndDate','End Date',50,'Y','N',NULL,'Y',30,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab1_id,'16a016f1-0006-4f01-8e15-000000000001','IsAllLocations','All Locations',60,'Y','N',NULL,'N',40,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab1_id,'16a016f1-0007-4f01-8e15-000000000001','C_BPartner_Location_IDs','Service Locations',70,'Y','N','@IsAllLocations@=''N''','N',50,'N');
  PERFORM pg_temp.saw016_upsert_field(v_tab1_id,'16a016f1-0008-4f01-8e15-000000000001','AbERP_FilterApproverStatus','Filter Approver Status',80,'Y','N',NULL,'N',60,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab1_id,'16a016f1-0009-4f01-8e15-000000000001','AbERP_FilterUnavailability_Type_ID','Filter Leave Type',90,'Y','N',NULL,'Y',70,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab1_id,'16a016f1-0010-4f01-8e15-000000000001','AbERP_SummaryByStatus','Summary by Approver Status',100,'Y','Y',NULL,'N',NULL,'N');
  PERFORM pg_temp.saw016_upsert_field(v_tab1_id,'16a016f1-0011-4f01-8e15-000000000001','AbERP_SummaryByType','Summary by Status + Leave Type',110,'Y','Y',NULL,'N',NULL,'N');
  PERFORM pg_temp.saw016_upsert_field(v_tab1_id,'16a016f1-0012-4f01-8e15-000000000001','IsActive','Active',120,'Y','N',NULL,'N',NULL,'N');
  PERFORM pg_temp.saw016_upsert_field(v_tab1_id,'16a016f1-0013-4f01-8e15-000000000001','AbERP_Leave_Planning_ID','Leave Planning',0,'N','Y',NULL,'N',NULL,'N');
  PERFORM pg_temp.saw016_upsert_field(v_tab1_id,'16a016f1-0014-4f01-8e15-000000000001','AbERP_Leave_Planning_UU','UU',0,'N','Y',NULL,'N',NULL,'N');

  -- Leave Records fields (grid-focused)
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0001-4f01-8e15-000000000001','AbERP_User_Contact_ID','Employee',10,'Y','N',NULL,'N',10,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0002-4f01-8e15-000000000001','AbERP_LP_EmployeeNumber','Employee Number',20,'Y','Y',NULL,'Y',20,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0003-4f01-8e15-000000000001','AbERP_LP_ServiceLocation','Service Location',30,'Y','Y',NULL,'N',30,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0004-4f01-8e15-000000000001','AbERP_CurrentSupervisor','Current Supervisor',40,'Y','Y',NULL,'Y',40,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0005-4f01-8e15-000000000001','AbERP_Unavailability_Type_ID','Unavailability Type',50,'Y','N',NULL,'N',50,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0006-4f01-8e15-000000000001','StartDate','Start Date',60,'Y','N',NULL,'N',60,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0007-4f01-8e15-000000000001','EndDate','End Date',70,'Y','N',NULL,'Y',70,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0008-4f01-8e15-000000000001','AbERP_LP_CalendarDays','Calendar Days',80,'Y','Y',NULL,'N',80,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0009-4f01-8e15-000000000001','AbERP_ApproverStatus','Approver Status',90,'Y','N',NULL,'N',90,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0010-4f01-8e15-000000000001','AbERP_SubmitterStatus','Submitter Status',100,'Y','Y',NULL,'Y',100,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0011-4f01-8e15-000000000001','Note','Note',110,'Y','N',NULL,'N',110,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0012-4f01-8e15-000000000001','AbERP_SubmitLeave','Submit Leave',120,'Y','N',NULL,'N',NULL,'N');
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0013-4f01-8e15-000000000001','Created','Created',130,'Y','Y',NULL,'N',120,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0014-4f01-8e15-000000000001','Updated','Updated',140,'Y','Y',NULL,'Y',130,'Y');
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0015-4f01-8e15-000000000001','AD_Org_ID','Organization',150,'Y','N',NULL,'N',NULL,'N');
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0016-4f01-8e15-000000000001','AD_Client_ID','Client',5,'N','Y',NULL,'N',NULL,'N');
  PERFORM pg_temp.saw016_upsert_field(v_tab2_id,'16a016f2-0017-4f01-8e15-000000000001','AbERP_Unavailability_Leave_ID','Leave',0,'N','Y',NULL,'N',NULL,'N');

  -- Hide new LP columns on existing leave windows (display off)
  UPDATE ad_field f SET isdisplayed = 'N', isdisplayedgrid = 'N', updated = NOW()
  FROM ad_column c, ad_tab t, ad_window w
  WHERE f.ad_column_id = c.ad_column_id
    AND f.ad_tab_id = t.ad_tab_id
    AND t.ad_window_id = w.ad_window_id
    AND c.columnname IN ('AbERP_LP_EmployeeNumber','AbERP_LP_ServiceLocation','AbERP_LP_CalendarDays')
    AND w.ad_window_uu <> v_window_uu;

  RAISE NOTICE 'SAW016 window=% tab1=% tab2=%', v_window_id, v_tab1_id, v_tab2_id;
END $$;
