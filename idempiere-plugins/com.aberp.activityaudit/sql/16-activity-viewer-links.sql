-- =============================================================================
-- SAW028 — Activity Viewer → Client / Employee / Support Location buttons
-- Zooms named AbilityERP windows only (never Business Partner / User).
-- =============================================================================
SET search_path TO adempiere;

ALTER TABLE c_contactactivity
  ADD COLUMN IF NOT EXISTS aberp_openclient character(1) DEFAULT NULL;
ALTER TABLE c_contactactivity
  ADD COLUMN IF NOT EXISTS aberp_openemployee character(1) DEFAULT NULL;
ALTER TABLE c_contactactivity
  ADD COLUMN IF NOT EXISTS aberp_opensupportlocation character(1) DEFAULT NULL;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_process_id),0)+1 FROM ad_process))
WHERE name='AD_Process' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_fieldgroup_id),0)+1 FROM ad_fieldgroup))
WHERE name='AD_FieldGroup' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw028_process(
  p_uu TEXT, p_value TEXT, p_name TEXT, p_classname TEXT, p_help TEXT
) RETURNS INTEGER AS $$
DECLARE
  v_id INTEGER;
BEGIN
  SELECT ad_process_id INTO v_id FROM ad_process WHERE ad_process_uu = p_uu;
  IF v_id IS NULL THEN
    SELECT ad_process_id INTO v_id FROM ad_process WHERE value = p_value;
  END IF;
  IF v_id IS NULL THEN
    INSERT INTO ad_process (
      ad_process_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      value, name, description, help,
      accesslevel, entitytype, isreport, isdirectprint,
      classname, statistic_count, statistic_seconds,
      isbetafunctionality, isserverprocess, showhelp, ad_process_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_value, p_name, p_name, p_help,
      '3', 'Ab_ERP', 'N', 'N',
      p_classname, 0, 0,
      'N', 'N', 'N', p_uu
    ) RETURNING ad_process_id INTO v_id;
  ELSE
    UPDATE ad_process SET
      name = p_name, value = p_value, classname = p_classname,
      description = p_name, help = p_help,
      isserverprocess = 'N', showhelp = 'N', entitytype = 'Ab_ERP',
      ad_process_uu = COALESCE(ad_process_uu, p_uu), isactive = 'Y', updated = NOW()
    WHERE ad_process_id = v_id;
  END IF;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw028_element(
  p_columnname TEXT, p_name TEXT, p_uu TEXT, p_desc TEXT
) RETURNS INTEGER AS $$
DECLARE
  v_id INTEGER;
BEGIN
  SELECT ad_element_id INTO v_id FROM ad_element WHERE columnname = p_columnname LIMIT 1;
  IF v_id IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, description, help, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_columnname, 'Ab_ERP', p_name, p_name, p_desc, p_desc, p_uu
    ) RETURNING ad_element_id INTO v_id;
  ELSE
    UPDATE ad_element SET
      name = p_name, printname = p_name, description = p_desc,
      ad_element_uu = COALESCE(NULLIF(ad_element_uu, ''), p_uu), updated = NOW()
    WHERE ad_element_id = v_id;
  END IF;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw028_button_col(
  p_table INTEGER, p_columnname TEXT, p_name TEXT, p_uu TEXT,
  p_elem INTEGER, p_process INTEGER, p_help TEXT
) RETURNS INTEGER AS $$
DECLARE
  v_id INTEGER;
BEGIN
  SELECT ad_column_id INTO v_id FROM ad_column
  WHERE ad_table_id = p_table AND columnname = p_columnname;
  IF v_id IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, version, entitytype, columnname, ad_table_id,
      ad_reference_id, fieldlength, iskey, isparent, ismandatory, isupdateable,
      isidentifier, seqno, istranslated, isencrypted, isselectioncolumn,
      ad_element_id, issyncdatabase, isalwaysupdateable, isallowcopy,
      ad_process_id, istoolbarbutton, description, help, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, 0, 'Ab_ERP', p_columnname, p_table,
      28, 1, 'N', 'N', 'N', 'Y',
      'N', 0, 'N', 'N', 'N',
      p_elem, 'N', 'Y', 'N',
      p_process, 'B', p_help, p_help, p_uu
    ) RETURNING ad_column_id INTO v_id;
  ELSE
    UPDATE ad_column SET
      ad_reference_id = 28,
      ad_process_id = p_process,
      columnsql = NULL,
      isupdateable = 'Y',
      isalwaysupdateable = 'Y',
      istoolbarbutton = 'B',
      fieldlength = 1,
      name = p_name,
      description = p_help,
      help = p_help,
      ad_column_uu = COALESCE(NULLIF(ad_column_uu, ''), p_uu),
      updated = NOW()
    WHERE ad_column_id = v_id;
  END IF;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw028_virtual_int_col(
  p_table INTEGER, p_columnname TEXT, p_name TEXT, p_uu TEXT,
  p_elem INTEGER, p_columnsql TEXT
) RETURNS INTEGER AS $$
DECLARE
  v_id INTEGER;
BEGIN
  SELECT ad_column_id INTO v_id FROM ad_column
  WHERE ad_table_id = p_table AND columnname = p_columnname;
  IF v_id IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, version, entitytype, columnname, ad_table_id,
      ad_reference_id, fieldlength, iskey, isparent, ismandatory, isupdateable,
      isidentifier, seqno, istranslated, isencrypted, isselectioncolumn,
      ad_element_id, issyncdatabase, isalwaysupdateable, isallowcopy,
      columnsql, description, help, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, 0, 'Ab_ERP', p_columnname, p_table,
      11, 10, 'N', 'N', 'N', 'N',
      'N', 0, 'N', 'N', 'N',
      p_elem, 'N', 'N', 'N',
      p_columnsql, 'DisplayLogic helper — not shown', 'Virtual link ID for button DisplayLogic', p_uu
    ) RETURNING ad_column_id INTO v_id;
  ELSE
    UPDATE ad_column SET
      ad_reference_id = 11,
      columnsql = p_columnsql,
      isupdateable = 'N',
      name = p_name,
      ad_column_uu = COALESCE(NULLIF(ad_column_uu, ''), p_uu),
      updated = NOW()
    WHERE ad_column_id = v_id;
  END IF;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw028_field(
  p_tab INTEGER, p_col INTEGER, p_uu TEXT, p_name TEXT,
  p_seq INTEGER, p_displayed CHAR, p_displaylogic TEXT,
  p_fg INTEGER, p_sameline CHAR, p_xposition INTEGER, p_columnspan INTEGER
) RETURNS void AS $$
DECLARE
  v_id INTEGER;
BEGIN
  SELECT ad_field_id INTO v_id FROM ad_field WHERE ad_field_uu = p_uu;
  IF v_id IS NULL THEN
    SELECT ad_field_id INTO v_id FROM ad_field
    WHERE ad_tab_id = p_tab AND ad_column_id = p_col;
  END IF;
  IF v_id IS NULL THEN
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, iscentrallymaintained, ad_tab_id, ad_column_id,
      isdisplayed, displaylength, isreadonly, seqno, issameline,
      isheading, isfieldonly, isencrypted, entitytype,
      isdisplayedgrid, seqnogrid, xposition, columnspan, numlines,
      displaylogic, ad_fieldgroup_id, istoolbarbutton, ad_field_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, p_name, 'N', p_tab, p_col,
      p_displayed, 0, CASE WHEN p_displayed = 'Y' THEN 'N' ELSE 'Y' END, p_seq, p_sameline,
      'N', 'N', 'N', 'Ab_ERP',
      'N', p_seq, p_xposition, p_columnspan, 1,
      p_displaylogic, p_fg,
      CASE WHEN p_displayed = 'Y' THEN 'B' ELSE NULL END,
      p_uu
    );
  ELSE
    UPDATE ad_field SET
      name = p_name,
      isdisplayed = p_displayed,
      isdisplayedgrid = 'N',
      isreadonly = CASE WHEN p_displayed = 'Y' THEN 'N' ELSE 'Y' END,
      seqno = p_seq,
      seqnogrid = p_seq,
      issameline = p_sameline,
      xposition = p_xposition,
      columnspan = p_columnspan,
      displaylogic = p_displaylogic,
      ad_fieldgroup_id = p_fg,
      istoolbarbutton = CASE WHEN p_displayed = 'Y' THEN 'B' ELSE istoolbarbutton END,
      ad_field_uu = COALESCE(NULLIF(ad_field_uu, ''), p_uu),
      updated = NOW()
    WHERE ad_field_id = v_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_tab INTEGER;
  v_table INTEGER;
  v_fg INTEGER;
  v_win_client INTEGER;
  v_win_emp INTEGER;
  v_win_loc INTEGER;
  v_proc_client INTEGER;
  v_proc_emp INTEGER;
  v_proc_loc INTEGER;
  v_has_receiver BOOLEAN;
  v_has_user_bp BOOLEAN;
  v_client_sql TEXT;
  v_emp_sql TEXT;
  v_col INTEGER;
  v_elem INTEGER;
BEGIN
  SELECT ad_tab_id INTO v_tab FROM ad_tab WHERE ad_tab_uu = '86e6abdc-cd6e-4003-bbcb-860df46ed682';
  IF v_tab IS NULL THEN
    SELECT t.ad_tab_id INTO v_tab
    FROM ad_tab t
    JOIN ad_window w ON w.ad_window_id = t.ad_window_id
    WHERE w.ad_window_uu = 'e5e62a4b-bd38-49d6-b2e7-e5a44e194b0e'
       OR w.name = 'Activity Viewer'
    ORDER BY t.seqno
    LIMIT 1;
  END IF;
  SELECT ad_table_id INTO v_table FROM ad_table WHERE tablename = 'C_ContactActivity';
  IF v_tab IS NULL OR v_table IS NULL THEN
    RAISE EXCEPTION 'SAW028: Activity Viewer tab / C_ContactActivity missing';
  END IF;

  SELECT ad_window_id INTO v_win_client FROM ad_window
  WHERE ad_window_uu = 'f1c9a83a-6589-49b8-a797-458f45e1b8e2' OR name = 'Client' LIMIT 1;
  SELECT ad_window_id INTO v_win_emp FROM ad_window
  WHERE ad_window_uu = 'a826f1f8-3097-4d96-a83a-0bd9e1bb48ae' OR name = 'Employee' LIMIT 1;
  SELECT ad_window_id INTO v_win_loc FROM ad_window
  WHERE ad_window_uu = '6ef3c558-3ec8-4f0c-be40-89f35d8acebf' OR name = 'Support Location' LIMIT 1;
  IF v_win_client IS NULL OR v_win_emp IS NULL OR v_win_loc IS NULL THEN
    RAISE EXCEPTION 'SAW028: Client / Employee / Support Location window missing';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM ad_column c
    JOIN ad_table t ON t.ad_table_id = c.ad_table_id
    WHERE t.tablename = 'C_BPartner' AND c.columnname = 'AbERP_IsSupport_Receiver'
  ) INTO v_has_receiver;
  SELECT EXISTS (
    SELECT 1 FROM ad_column c
    WHERE c.ad_table_id = v_table AND c.columnname = 'AbERP_User_BP_ID'
  ) INTO v_has_user_bp;

  IF v_has_receiver THEN
    v_client_sql :=
      '(SELECT CASE WHEN bp.AbERP_IsSupport_Receiver=''Y'' THEN bp.C_BPartner_ID ELSE NULL END'
      || ' FROM C_BPartner bp WHERE bp.C_BPartner_ID=C_ContactActivity.C_BPartner_ID AND bp.IsActive=''Y'')';
  ELSE
    v_client_sql :=
      '(SELECT CASE WHEN bp.IsCustomer=''Y'' AND COALESCE(bp.IsEmployee,''N'')=''N'' THEN bp.C_BPartner_ID ELSE NULL END'
      || ' FROM C_BPartner bp WHERE bp.C_BPartner_ID=C_ContactActivity.C_BPartner_ID AND bp.IsActive=''Y'')';
  END IF;

  v_emp_sql :=
    'COALESCE('
    || '(SELECT C_ContactActivity.C_BPartner_Staff_ID FROM C_BPartner bp'
    || ' WHERE bp.C_BPartner_ID=C_ContactActivity.C_BPartner_Staff_ID'
    || ' AND bp.IsEmployee=''Y'' AND bp.IsActive=''Y'' AND COALESCE(C_ContactActivity.C_BPartner_Staff_ID,0)>0),'
    || '(SELECT u.C_BPartner_ID FROM AD_User u'
    || ' INNER JOIN C_BPartner bp ON bp.C_BPartner_ID=u.C_BPartner_ID'
    || ' WHERE u.AD_User_ID=C_ContactActivity.AD_User_ID'
    || ' AND bp.IsEmployee=''Y'' AND bp.IsActive=''Y'' AND u.IsActive=''Y'''
    || ' AND COALESCE(C_ContactActivity.AD_User_ID,0)>0)';
  IF v_has_user_bp THEN
    v_emp_sql := v_emp_sql
      || ',(SELECT C_ContactActivity.AbERP_User_BP_ID FROM C_BPartner bp'
      || ' WHERE bp.C_BPartner_ID=C_ContactActivity.AbERP_User_BP_ID'
      || ' AND bp.IsEmployee=''Y'' AND bp.IsActive=''Y'''
      || ' AND COALESCE(C_ContactActivity.AbERP_User_BP_ID,0)>0)';
  END IF;
  v_emp_sql := v_emp_sql || ')';

  -- Field group
  SELECT ad_fieldgroup_id INTO v_fg FROM ad_fieldgroup
  WHERE ad_fieldgroup_uu = '28a028fg-0001-4f01-8e15-000000000001';
  IF v_fg IS NULL THEN
    SELECT ad_fieldgroup_id INTO v_fg FROM ad_fieldgroup
    WHERE name = 'Activity Links' AND entitytype = 'Ab_ERP' LIMIT 1;
  END IF;
  IF v_fg IS NULL THEN
    INSERT INTO ad_fieldgroup (
      ad_fieldgroup_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, entitytype, fieldgrouptype, iscollapsedbydefault, ad_fieldgroup_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_FieldGroup' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Activity Links', 'Ab_ERP', 'C', 'N', '28a028fg-0001-4f01-8e15-000000000001'
    ) RETURNING ad_fieldgroup_id INTO v_fg;
  ELSE
    UPDATE ad_fieldgroup SET
      name = 'Activity Links', entitytype = 'Ab_ERP', fieldgrouptype = 'C',
      iscollapsedbydefault = 'N',
      ad_fieldgroup_uu = COALESCE(NULLIF(ad_fieldgroup_uu, ''), '28a028fg-0001-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_fieldgroup_id = v_fg;
  END IF;

  v_proc_client := pg_temp.saw028_process(
    '28a02870-c0d4-4f01-8e15-000000000001',
    'AbERP_ActivityViewer_OpenClient',
    'Open Client',
    'com.aberp.activityaudit.process.OpenActivityClient',
    'Open the Client window for the Client linked on this Activity (not Business Partner).');
  v_proc_emp := pg_temp.saw028_process(
    '28a02871-c0d4-4f01-8e15-000000000001',
    'AbERP_ActivityViewer_OpenEmployee',
    'Open Employee',
    'com.aberp.activityaudit.process.OpenActivityEmployee',
    'Open the Employee window for the employee linked on this Activity (not User/Contact).');
  v_proc_loc := pg_temp.saw028_process(
    '28a02872-c0d4-4f01-8e15-000000000001',
    'AbERP_ActivityViewer_OpenSupportLocation',
    'Open Support Location',
    'com.aberp.activityaudit.process.OpenActivitySupportLocation',
    'Open the Support Location window for the location linked on this Activity.');

  -- Hidden virtual IDs for DisplayLogic
  v_elem := pg_temp.saw028_element('AbERP_LinkClient_ID', 'Link Client ID',
    '28a028e1-c001-4f01-8e15-000000000001', 'Resolved Client BP for DisplayLogic');
  v_col := pg_temp.saw028_virtual_int_col(v_table, 'AbERP_LinkClient_ID', 'Link Client ID',
    '28a02804-c001-4f01-8e15-000000000001', v_elem, v_client_sql);
  -- Helpers: displayed with 1=2 so ColumnSQL enters WebUI context for DisplayLogic
  PERFORM pg_temp.saw028_field(v_tab, v_col, '28a02851-f001-4f01-8e15-000000000001',
    'Link Client ID', 992, 'Y', '1=2', NULL, 'N', 1, 2);

  v_elem := pg_temp.saw028_element('AbERP_LinkEmployee_ID', 'Link Employee ID',
    '28a028e1-c002-4f01-8e15-000000000001', 'Resolved Employee BP for DisplayLogic');
  v_col := pg_temp.saw028_virtual_int_col(v_table, 'AbERP_LinkEmployee_ID', 'Link Employee ID',
    '28a02804-c002-4f01-8e15-000000000001', v_elem, v_emp_sql);
  PERFORM pg_temp.saw028_field(v_tab, v_col, '28a02851-f002-4f01-8e15-000000000001',
    'Link Employee ID', 993, 'Y', '1=2', NULL, 'N', 1, 2);

  -- Buttons (DisplayLogic uses resolved link IDs — process zooms named windows only)
  v_elem := pg_temp.saw028_element('AbERP_OpenClient', 'Client',
    '28a028e1-b001-4f01-8e15-000000000001', 'Open Client window');
  v_col := pg_temp.saw028_button_col(v_table, 'AbERP_OpenClient', 'Client',
    '28a02804-b001-4f01-8e15-000000000001', v_elem, v_proc_client,
    'Open Client window for the linked Client');
  PERFORM pg_temp.saw028_field(v_tab, v_col, '28a02851-b001-4f01-8e15-000000000001',
    'Client', 112, 'Y', '@AbERP_LinkClient_ID@>0', v_fg, 'N', 1, 2);

  v_elem := pg_temp.saw028_element('AbERP_OpenEmployee', 'Employee',
    '28a028e1-b002-4f01-8e15-000000000001', 'Open Employee window');
  v_col := pg_temp.saw028_button_col(v_table, 'AbERP_OpenEmployee', 'Employee',
    '28a02804-b002-4f01-8e15-000000000001', v_elem, v_proc_emp,
    'Open Employee window for the linked Employee');
  PERFORM pg_temp.saw028_field(v_tab, v_col, '28a02851-b002-4f01-8e15-000000000001',
    'Employee', 114, 'Y',
    '@AbERP_LinkEmployee_ID@>0 | @AbERP_User_BP_ID@>0 | @C_BPartner_Staff_ID@>0',
    v_fg, 'Y', 4, 2);

  v_elem := pg_temp.saw028_element('AbERP_OpenSupportLocation', 'Support Location',
    '28a028e1-b003-4f01-8e15-000000000001', 'Open Support Location window');
  v_col := pg_temp.saw028_button_col(v_table, 'AbERP_OpenSupportLocation', 'Support Location',
    '28a02804-b003-4f01-8e15-000000000001', v_elem, v_proc_loc,
    'Open Support Location window for the linked location');
  PERFORM pg_temp.saw028_field(v_tab, v_col, '28a02851-b003-4f01-8e15-000000000001',
    'Support Location', 116, 'Y', '@AbERP_Support_Location_ID@>0', v_fg, 'Y', 7, 2);

  UPDATE ad_tab SET isreadonly = 'N', updated = NOW() WHERE ad_tab_id = v_tab;

  -- Process access
  INSERT INTO ad_process_access (
    ad_process_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, isreadwrite
  )
  SELECT p.ad_process_id, r.ad_role_id, r.ad_client_id, 0, 'Y',
         NOW(), 100, NOW(), 100, 'Y'
  FROM ad_role r
  CROSS JOIN (VALUES (v_proc_client), (v_proc_emp), (v_proc_loc)) AS p(ad_process_id)
  WHERE r.name IN ('AbilityERP Admin', 'Admin', 'System Administrator')
    AND NOT EXISTS (
      SELECT 1 FROM ad_process_access x
      WHERE x.ad_process_id = p.ad_process_id AND x.ad_role_id = r.ad_role_id
    );

  -- Window access so zoom targets open
  INSERT INTO ad_window_access (
    ad_window_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, isreadwrite
  )
  SELECT w.ad_window_id, r.ad_role_id, r.ad_client_id, 0, 'Y',
         NOW(), 100, NOW(), 100, 'Y'
  FROM ad_role r
  CROSS JOIN (VALUES (v_win_client), (v_win_emp), (v_win_loc)) AS w(ad_window_id)
  WHERE r.name IN ('AbilityERP Admin', 'Admin', 'System Administrator')
    AND NOT EXISTS (
      SELECT 1 FROM ad_window_access x
      WHERE x.ad_window_id = w.ad_window_id AND x.ad_role_id = r.ad_role_id
    );

  RAISE NOTICE 'SAW028 Activity Viewer links ready (tab=%, clientReceiver=%, userBp=%)',
    v_tab, v_has_receiver, v_has_user_bp;
END $$;
