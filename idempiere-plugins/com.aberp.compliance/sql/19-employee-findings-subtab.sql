-- =============================================================================
-- SAW024 — Nest Open Findings under Employee + Open & Fix source button
-- Physical parent FK + TabLevel 2 + Included_Tab_ID + AbERP_Compliance_OpenSource
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_process_id),0)+1 FROM ad_process))
WHERE name='AD_Process' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';

-- 1) Physical parent link column (virtual ColumnSQL cannot be used in parent joins)
ALTER TABLE aberp_complianceresult
  ADD COLUMN IF NOT EXISTS aberp_compliancedashboard_id NUMERIC(10);

UPDATE aberp_complianceresult
SET aberp_compliancedashboard_id = ad_client_id
WHERE aberp_compliancedashboard_id IS NULL;

DO $$
DECLARE
  v_result_table INTEGER;
  v_dash_table INTEGER;
  v_dash_pk INTEGER;
  v_link_col INTEGER;
  v_emp_tab INTEGER;
  v_find_tab INTEGER;
  v_window_id INTEGER;
  v_process_id INTEGER;
  v_element_id INTEGER;
  v_btn_col INTEGER;
  v_field_id INTEGER;
  v_ref_button INTEGER;
BEGIN
  SELECT ad_table_id INTO v_result_table FROM ad_table WHERE tablename = 'AbERP_ComplianceResult';
  SELECT ad_table_id INTO v_dash_table FROM ad_table WHERE tablename = 'AbERP_ComplianceDashboard';
  SELECT ad_column_id INTO v_dash_pk FROM ad_column
  WHERE ad_table_id = v_dash_table AND columnname = 'AbERP_ComplianceDashboard_ID';
  IF v_result_table IS NULL OR v_dash_pk IS NULL THEN
    RAISE EXCEPTION 'SAW024: dashboard/result tables missing';
  END IF;

  SELECT ad_window_id INTO v_window_id
  FROM ad_window
  WHERE ad_window_uu = '23a02305-c0d4-4f01-8e15-000000000001'
     OR name = 'NDIS Audit Tool'
  LIMIT 1;

  SELECT ad_tab_id INTO v_emp_tab
  FROM ad_tab
  WHERE ad_tab_uu = '23a02311-c0d4-4f01-8e15-000000000001'
     OR (ad_window_id = v_window_id AND name = 'Employee')
  LIMIT 1;

  SELECT ad_tab_id INTO v_find_tab
  FROM ad_tab WHERE ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001';
  IF v_emp_tab IS NULL OR v_find_tab IS NULL THEN
    RAISE EXCEPTION 'SAW024: Employee / Open Findings tabs missing — run 18 first';
  END IF;

  -- Convert virtual dashboard link column to physical
  SELECT ad_column_id INTO v_link_col
  FROM ad_column
  WHERE ad_table_id = v_result_table AND columnname = 'AbERP_ComplianceDashboard_ID'
  LIMIT 1;

  IF v_link_col IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, version, entitytype,
      columnname, ad_table_id, ad_reference_id, fieldlength,
      iskey, isparent, ismandatory, isupdateable, isidentifier,
      seqno, istranslated, isencrypted, isselectioncolumn,
      isautocomplete, isalwaysupdateable, isallowcopy, issyncdatabase,
      ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Compliance Dashboard', 'Parent Organisation Audit / Employee row',
      'Equals AD_Client_ID (dashboard PK). Links Open Findings under Employee.',
      0, 'Ab_ERP',
      'AbERP_ComplianceDashboard_ID', v_result_table, 13, 10,
      'N', 'Y', 'N', 'N', 'N',
      85, 'N', 'N', 'N',
      'N', 'N', 'N', 'Y',
      '24a02402-c001-4f01-8e15-000000000001'
    ) RETURNING ad_column_id INTO v_link_col;
  ELSE
    UPDATE ad_column SET
      columnsql = NULL,
      isparent = 'Y',
      isupdateable = 'N',
      ismandatory = 'N',
      ad_reference_id = 13,
      issyncdatabase = 'Y',
      entitytype = 'Ab_ERP',
      ad_column_uu = COALESCE(ad_column_uu, '24a02402-c001-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_column_id = v_link_col;
  END IF;

  -- Nest Open Findings under Employee
  UPDATE ad_tab SET
    tablevel = 2,
    seqno = 25,
    issinglerow = 'N',
    isreadonly = 'N',
    isinsertrecord = 'N',
    ad_column_id = v_link_col,
    parent_column_id = v_dash_pk,
    whereclause = 'AbERP_ComplianceRule_ID IN (SELECT AbERP_ComplianceRule_ID FROM AbERP_ComplianceRule WHERE ComplianceCategory=''W'') AND IsResolved=''N'' AND IsActive=''Y''',
    orderbyclause = 'Severity, DueDate, AbERP_ComplianceResult_ID',
    description = 'Employee issues under the Employee KPIs — why, resolve, open source',
    help = 'Sub-tab of Employee. Each row is one open workforce finding. Read Why and What to resolve, then click Open & Fix to open the Credential Assignment and update it. After fixing, run Refresh Compliance.',
    updated = NOW()
  WHERE ad_tab_id = v_find_tab;

  UPDATE ad_tab SET
    included_tab_id = v_find_tab,
    description = 'Employee (workforce) compliance KPIs — Open Findings listed underneath',
    help = 'KPIs for workforce rules. The Open Findings sub-tab lists each issue. Use Open & Fix to jump to the Credential Assignment and take action, then Refresh Compliance.',
    updated = NOW()
  WHERE ad_tab_id = v_emp_tab;

  -- Open & Fix process
  SELECT ad_process_id INTO v_process_id
  FROM ad_process
  WHERE value = 'AbERP_Compliance_OpenSource'
     OR ad_process_uu = '24a02430-c0d4-4f01-8e15-000000000001'
  LIMIT 1;

  IF v_process_id IS NULL THEN
    INSERT INTO ad_process (
      ad_process_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      value, name, description, help,
      accesslevel, entitytype, isreport, isdirectprint,
      classname, statistic_count, statistic_seconds,
      isbetafunctionality, isserverprocess, showhelp,
      ad_process_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_Compliance_OpenSource', 'Open & Fix Source',
      'Open the source record for this compliance finding',
      'Zooms to the Credential Assignment (or other source) so you can renew/update and clear the finding on next Refresh.',
      '3', 'Ab_ERP', 'N', 'N',
      'com.aberp.compliance.OpenComplianceSource', 0, 0,
      'N', 'N', 'N',
      '24a02430-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_process_id INTO v_process_id;
  ELSE
    UPDATE ad_process SET
      value = 'AbERP_Compliance_OpenSource',
      name = 'Open & Fix Source',
      classname = 'com.aberp.compliance.OpenComplianceSource',
      entitytype = 'Ab_ERP',
      isactive = 'Y',
      ad_process_uu = COALESCE(ad_process_uu, '24a02430-c0d4-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_process_id = v_process_id;
  END IF;

  -- Process access by role name
  INSERT INTO ad_process_access (
    ad_process_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, isreadwrite
  )
  SELECT v_process_id, r.ad_role_id, 0, 0, 'Y',
         NOW(), 100, NOW(), 100, 'Y'
  FROM ad_role r
  WHERE r.name IN ('Admin', 'AbilityERP Admin', 'System Administrator')
    AND r.isactive = 'Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_process_access a
      WHERE a.ad_process_id = v_process_id AND a.ad_role_id = r.ad_role_id
    );

  SELECT ad_reference_id INTO v_ref_button FROM ad_reference WHERE name = '_Button' LIMIT 1;
  IF v_ref_button IS NULL THEN
    v_ref_button := 28;
  END IF;

  SELECT ad_element_id INTO v_element_id FROM ad_element WHERE columnname = 'AbERP_OpenSource' LIMIT 1;
  IF v_element_id IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, description, help, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_OpenSource', 'Ab_ERP', 'Open & Fix', 'Open & Fix',
      'Open the source record for this finding',
      'Opens Credential Assignment (Employee findings) so you can renew/update expiry.',
      '24a02431-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_element_id INTO v_element_id;
  END IF;

  SELECT ad_column_id INTO v_btn_col
  FROM ad_column
  WHERE ad_column_uu = '24a02402-c004-4f01-8e15-000000000001'
     OR (ad_table_id = v_result_table AND columnname = 'AbERP_OpenSource')
  LIMIT 1;

  IF v_btn_col IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, version, entitytype,
      columnname, ad_table_id, ad_reference_id, fieldlength,
      iskey, isparent, ismandatory, isupdateable, isidentifier,
      seqno, istranslated, isencrypted, isselectioncolumn,
      columnsql, ad_element_id, ad_process_id,
      isalwaysupdateable, istoolbarbutton, isallowcopy, issyncdatabase,
      ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Open & Fix', 'Open source record to take action',
      'Zooms to the Credential Assignment for this finding.',
      0, 'Ab_ERP',
      'AbERP_OpenSource', v_result_table, v_ref_button, 1,
      'N', 'N', 'N', 'Y', 'N',
      5, 'N', 'N', 'N',
      'NULL::bpchar', v_element_id, v_process_id,
      'Y', 'B', 'N', 'N',
      '24a02402-c004-4f01-8e15-000000000001'
    ) RETURNING ad_column_id INTO v_btn_col;
  ELSE
    UPDATE ad_column SET
      name = 'Open & Fix',
      ad_reference_id = v_ref_button,
      ad_process_id = v_process_id,
      columnsql = 'NULL::bpchar',
      isupdateable = 'Y',
      isalwaysupdateable = 'Y',
      istoolbarbutton = 'B',
      ad_element_id = v_element_id,
      entitytype = 'Ab_ERP',
      ad_column_uu = COALESCE(ad_column_uu, '24a02402-c004-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_column_id = v_btn_col;
  END IF;

  SELECT ad_field_id INTO v_field_id FROM ad_field WHERE ad_field_uu = '24a02410-f022-4f01-8e15-000000000001';
  IF v_field_id IS NULL THEN
    SELECT ad_field_id INTO v_field_id
    FROM ad_field WHERE ad_tab_id = v_find_tab AND ad_column_id = v_btn_col;
  END IF;

  IF v_field_id IS NULL THEN
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, iscentrallymaintained,
      ad_tab_id, ad_column_id,
      isdisplayed, displaylength, isreadonly, seqno, issameline,
      isheading, isfieldonly, isencrypted, entitytype,
      isdisplayedgrid, seqnogrid, xposition, columnspan, numlines,
      istoolbarbutton, ad_field_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Open & Fix', 'Open source record to take action',
      'Opens the Credential Assignment for this finding so you can renew or update expiry, then Refresh Compliance.',
      'N', v_find_tab, v_btn_col,
      'Y', 1, 'N', 5, 'N',
      'N', 'N', 'N', 'Ab_ERP',
      'Y', 5, 5, 2, 1,
      'B', '24a02410-f022-4f01-8e15-000000000001'
    );
  ELSE
    UPDATE ad_field SET
      name = 'Open & Fix',
      isdisplayed = 'Y',
      isdisplayedgrid = 'Y',
      isreadonly = 'N',
      seqno = 5,
      seqnogrid = 5,
      istoolbarbutton = 'B',
      ad_field_uu = COALESCE(ad_field_uu, '24a02410-f022-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_field_id = v_field_id;
  END IF;

  -- Keep Open Assignment zoomable lookup visible for action
  UPDATE ad_field SET
    isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    seqno = 85,
    seqnogrid = 85,
    name = 'Open Assignment',
    help = 'Lookup/zoom to the Credential Assignment. Prefer Open & Fix for one-click open.',
    updated = NOW()
  WHERE ad_tab_id = v_find_tab
    AND ad_column_id = (
      SELECT ad_column_id FROM ad_column
      WHERE ad_table_id = v_result_table AND columnname = 'AbERP_OpenAssignment_ID'
    );

  RAISE NOTICE 'SAW024 nested Open Findings under Employee; Open&Fix process=% linkCol=%',
    v_process_id, v_link_col;
END $$;

SELECT t.seqno, t.name, t.tablevel,
       (SELECT name FROM ad_tab x WHERE x.ad_tab_id = t.included_tab_id) AS includes,
       (SELECT columnname FROM ad_column c WHERE c.ad_column_id = t.ad_column_id) AS link,
       (SELECT columnname FROM ad_column c WHERE c.ad_column_id = t.parent_column_id) AS parent_col
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.ad_window_uu = '23a02305-c0d4-4f01-8e15-000000000001'
ORDER BY t.seqno;

SELECT value, name, classname FROM ad_process WHERE value = 'AbERP_Compliance_OpenSource';
SELECT COUNT(*) AS backfilled FROM aberp_complianceresult WHERE aberp_compliancedashboard_id IS NOT NULL;
