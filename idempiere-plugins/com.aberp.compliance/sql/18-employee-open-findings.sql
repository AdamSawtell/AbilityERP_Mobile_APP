-- =============================================================================
-- SAW024 — Employee Open Findings POC (under NDIS Audit Tool → Employee)
-- TabLevel 2 grid: why / resolve hint / Zoom Across to Credential Assignment
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_tab_id),0)+1 FROM ad_tab))
WHERE name='AD_Tab' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';

DO $$
DECLARE
  v_window_id INTEGER;
  v_emp_tab INTEGER;
  v_result_table INTEGER;
  v_dash_table INTEGER;
  v_dash_pk_col INTEGER;
  v_link_col INTEGER;
  v_resolve_col INTEGER;
  v_cred_table INTEGER;
  v_cred_window INTEGER;
  v_tab_id INTEGER;
  v_col_id INTEGER;
  v_field_id INTEGER;
  r RECORD;
BEGIN
  -- Window
  SELECT ad_window_id INTO v_window_id
  FROM ad_window
  WHERE ad_window_uu = '23a02305-c0d4-4f01-8e15-000000000001'
     OR name = 'NDIS Audit Tool'
  LIMIT 1;
  IF v_window_id IS NULL THEN
    RAISE EXCEPTION 'SAW024: NDIS Audit Tool window missing';
  END IF;

  SELECT ad_tab_id INTO v_emp_tab
  FROM ad_tab
  WHERE ad_tab_uu = '23a02311-c0d4-4f01-8e15-000000000001'
     OR (ad_window_id = v_window_id AND name = 'Employee')
  LIMIT 1;
  IF v_emp_tab IS NULL THEN
    RAISE EXCEPTION 'SAW024: Employee tab missing';
  END IF;

  SELECT ad_table_id INTO v_result_table
  FROM ad_table WHERE tablename = 'AbERP_ComplianceResult';
  IF v_result_table IS NULL THEN
    RAISE EXCEPTION 'SAW024: AbERP_ComplianceResult table missing';
  END IF;

  SELECT ad_table_id INTO v_dash_table
  FROM ad_table WHERE tablename = 'AbERP_ComplianceDashboard';
  IF v_dash_table IS NULL THEN
    RAISE EXCEPTION 'SAW024: AbERP_ComplianceDashboard table missing';
  END IF;

  SELECT ad_column_id INTO v_dash_pk_col
  FROM ad_column
  WHERE ad_table_id = v_dash_table AND columnname = 'AbERP_ComplianceDashboard_ID';
  IF v_dash_pk_col IS NULL THEN
    RAISE EXCEPTION 'SAW024: dashboard PK column missing';
  END IF;

  -- Ensure Credential Assignment zooms from AD_Table_ID + Record_ID
  SELECT ad_table_id INTO v_cred_table
  FROM ad_table WHERE tablename = 'AbERP_CredentialAssignment' LIMIT 1;
  IF v_cred_table IS NULL THEN
    RAISE EXCEPTION 'SAW024: AbERP_CredentialAssignment AD table missing';
  END IF;

  SELECT ad_window_id INTO v_cred_window
  FROM ad_window
  WHERE name = 'Credential Assignment' AND isactive = 'Y'
  ORDER BY ad_window_id
  LIMIT 1;
  IF v_cred_window IS NULL THEN
    RAISE EXCEPTION 'SAW024: Credential Assignment window missing';
  END IF;

  UPDATE ad_table SET
    ad_window_id = v_cred_window,
    updated = NOW(),
    updatedby = 100
  WHERE ad_table_id = v_cred_table
    AND (ad_window_id IS DISTINCT FROM v_cred_window);

  -- Action-oriented resolve text on Employee rules (shown via ResolveHint ColumnSQL)
  UPDATE aberp_compliancerule SET
    description = CASE aberp_compliancerule_uu
      WHEN '23a02350-c0d4-4f01-8e15-000000000001' THEN
        'Renew or update Expiry Date on this Credential Assignment, then run Refresh Compliance.'
      WHEN '23a02351-c0d4-4f01-8e15-000000000001' THEN
        'Renew before expiry (or update Expiry Date) on this Credential Assignment, then Refresh Compliance.'
      WHEN '23a02352-c0d4-4f01-8e15-000000000001' THEN
        'Renew Worker Screening / WWCC on this Credential Assignment, then Refresh Compliance.'
      ELSE description
    END,
    ad_window_id = COALESCE(ad_window_id, v_cred_window),
    updated = NOW(),
    updatedby = 100
  WHERE aberp_compliancerule_uu IN (
    '23a02350-c0d4-4f01-8e15-000000000001',
    '23a02351-c0d4-4f01-8e15-000000000001',
    '23a02352-c0d4-4f01-8e15-000000000001'
  );

  -- Link Open Findings to Organisation Audit via AD_Client_ID == dashboard PK
  -- (virtual AbERP_ComplianceDashboard_ID ColumnSQL is not usable in parent join SQL)
  SELECT ad_column_id INTO v_link_col
  FROM ad_column
  WHERE ad_table_id = v_result_table AND columnname = 'AD_Client_ID';
  IF v_link_col IS NULL THEN
    RAISE EXCEPTION 'SAW024: AD_Client_ID missing on AbERP_ComplianceResult';
  END IF;

  UPDATE ad_column SET
    isparent = 'Y',
    updated = NOW()
  WHERE ad_column_id = v_link_col AND isparent = 'N';

  -- Keep virtual dashboard column for display/context only (not used as tab link)
  SELECT ad_column_id INTO v_col_id
  FROM ad_column
  WHERE ad_column_uu = '24a02402-c001-4f01-8e15-000000000001'
     OR (ad_table_id = v_result_table AND columnname = 'AbERP_ComplianceDashboard_ID')
  LIMIT 1;

  IF v_col_id IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, version, entitytype,
      columnname, ad_table_id, ad_reference_id, fieldlength,
      iskey, isparent, ismandatory, isupdateable, isidentifier,
      seqno, istranslated, isencrypted, isselectioncolumn,
      columnsql, isautocomplete, isalwaysupdateable,
      isallowcopy, issyncdatabase, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Compliance Dashboard', 'Same value as AD_Client_ID (dashboard PK)',
      'Virtual alias for readability only — tab parent link uses AD_Client_ID + Parent_Column_ID.',
      1, 'Ab_ERP',
      'AbERP_ComplianceDashboard_ID', v_result_table, 13, 10,
      'N', 'N', 'N', 'N', 'N',
      85, 'N', 'N', 'N',
      'AD_Client_ID', 'N', 'N',
      'N', 'N', '24a02402-c001-4f01-8e15-000000000001'
    );
  ELSE
    UPDATE ad_column SET
      name = 'Compliance Dashboard',
      columnsql = 'AD_Client_ID',
      isparent = 'N',
      isupdateable = 'N',
      ismandatory = 'N',
      ad_reference_id = 13,
      entitytype = 'Ab_ERP',
      ad_column_uu = COALESCE(ad_column_uu, '24a02402-c001-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_column_id = v_col_id;
  END IF;

  -- Resolve hint from rule Description
  SELECT ad_column_id INTO v_resolve_col
  FROM ad_column
  WHERE ad_column_uu = '24a02402-c002-4f01-8e15-000000000001'
     OR (ad_table_id = v_result_table AND columnname = 'AbERP_ResolveHint')
  LIMIT 1;

  IF v_resolve_col IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, version, entitytype,
      columnname, ad_table_id, ad_reference_id, fieldlength,
      iskey, isparent, ismandatory, isupdateable, isidentifier,
      seqno, istranslated, isencrypted, isselectioncolumn,
      columnsql, isautocomplete, isalwaysupdateable,
      isallowcopy, issyncdatabase, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'What to resolve', 'Action required to clear this finding',
      'Pulled from the Compliance Rule Description. After fixing the source record, run Refresh Compliance.',
      1, 'Ab_ERP',
      'AbERP_ResolveHint', v_result_table, 14, 500,
      'N', 'N', 'N', 'N', 'N',
      205, 'N', 'N', 'N',
      '(SELECT r.Description FROM AbERP_ComplianceRule r WHERE r.AbERP_ComplianceRule_ID=AbERP_ComplianceResult.AbERP_ComplianceRule_ID)',
      'N', 'N',
      'N', 'N', '24a02402-c002-4f01-8e15-000000000001'
    ) RETURNING ad_column_id INTO v_resolve_col;
  ELSE
    UPDATE ad_column SET
      name = 'What to resolve',
      columnsql = '(SELECT r.Description FROM AbERP_ComplianceRule r WHERE r.AbERP_ComplianceRule_ID=AbERP_ComplianceResult.AbERP_ComplianceRule_ID)',
      ad_reference_id = 14,
      fieldlength = 500,
      isupdateable = 'N',
      entitytype = 'Ab_ERP',
      ad_column_uu = COALESCE(ad_column_uu, '24a02402-c002-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_column_id = v_resolve_col;
  END IF;

  -- Open Findings tab (TabLevel 1 sibling after Employee)
  SELECT ad_tab_id INTO v_tab_id
  FROM ad_tab WHERE ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001';
  IF v_tab_id IS NULL THEN
    SELECT ad_tab_id INTO v_tab_id
    FROM ad_tab
    WHERE ad_window_id = v_window_id AND name = 'Open Findings';
  END IF;

  IF v_tab_id IS NULL THEN
    INSERT INTO ad_tab (
      ad_tab_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help,
      ad_table_id, ad_window_id, seqno, tablevel,
      issinglerow, isinfotab, istranslationtab, isreadonly,
      hastree, processing, issorttab, entitytype,
      isinsertrecord, isadvancedtab,
      whereclause, orderbyclause,
      ad_column_id, parent_column_id, ad_tab_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Tab' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Open Findings',
      'Employee compliance issues — why, what to fix, open source record',
      'Each row is one open Employee finding from the last Refresh Compliance. Why = Result Message. What to resolve = rule action. Select a row and use Zoom Across (toolbar) to open the Credential Assignment and fix it, then Refresh Compliance. Open this tab after reviewing Employee KPIs.',
      v_result_table, v_window_id, 25, 1,
      'N', 'N', 'N', 'Y',
      'N', 'N', 'N', 'Ab_ERP',
      'N', 'N',
      'AbERP_ComplianceRule_ID IN (SELECT AbERP_ComplianceRule_ID FROM AbERP_ComplianceRule WHERE ComplianceCategory=''W'') AND IsResolved=''N'' AND IsActive=''Y''',
      'Severity, DueDate, AbERP_ComplianceResult_ID',
      v_link_col, v_dash_pk_col, '24a02410-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_tab_id INTO v_tab_id;
  ELSE
    UPDATE ad_tab SET
      name = 'Open Findings',
      description = 'Employee compliance issues — why, what to fix, open source record',
      help = 'Each row is one open Employee finding from the last Refresh Compliance. Why = Result Message. What to resolve = rule action. Select a row and use Zoom Across (toolbar) to open the Credential Assignment and fix it, then Refresh Compliance. Open this tab after reviewing Employee KPIs.',
      ad_table_id = v_result_table,
      seqno = 25,
      tablevel = 1,
      issinglerow = 'N',
      isreadonly = 'Y',
      isinsertrecord = 'N',
      whereclause = 'AbERP_ComplianceRule_ID IN (SELECT AbERP_ComplianceRule_ID FROM AbERP_ComplianceRule WHERE ComplianceCategory=''W'') AND IsResolved=''N'' AND IsActive=''Y''',
      orderbyclause = 'Severity, DueDate, AbERP_ComplianceResult_ID',
      ad_column_id = v_link_col,
      parent_column_id = v_dash_pk_col,
      entitytype = 'Ab_ERP',
      ad_tab_uu = COALESCE(ad_tab_uu, '24a02410-c0d4-4f01-8e15-000000000001'),
      isactive = 'Y',
      updated = NOW()
    WHERE ad_tab_id = v_tab_id;
  END IF;

  -- Employee tab help
  UPDATE ad_tab SET
    help = 'Employee (workforce) KPIs from the latest Refresh. Switch to the Open Findings tab for each issue: why it failed, what to resolve, and Zoom Across to the Credential Assignment.',
    description = 'Employee (workforce) compliance KPIs — see Open Findings tab for issue list',
    updated = NOW()
  WHERE ad_tab_id = v_emp_tab;

  -- Fields helper
  FOR r IN
    SELECT * FROM (VALUES
      ('24a02410-f001-4f01-8e15-000000000001', 'AbERP_ComplianceResult_ID', 'Compliance Result', 0, 'N', 'N', 0),
      ('24a02410-f002-4f01-8e15-000000000001', 'AbERP_ComplianceDashboard_ID', 'Compliance Dashboard', 5, 'N', 'N', 0),
      ('24a02410-f003-4f01-8e15-000000000001', 'AD_Client_ID', 'Client', 8, 'N', 'N', 0),
      ('24a02410-f010-4f01-8e15-000000000001', 'AbERP_ComplianceRule_ID', 'Rule', 10, 'Y', 'Y', 10),
      ('24a02410-f011-4f01-8e15-000000000001', 'Severity', 'Severity', 20, 'Y', 'Y', 20),
      ('24a02410-f012-4f01-8e15-000000000001', 'ComplianceStatus', 'Status', 30, 'Y', 'Y', 30),
      ('24a02410-f013-4f01-8e15-000000000001', 'ResultMessage', 'Why', 40, 'Y', 'Y', 40),
      ('24a02410-f014-4f01-8e15-000000000001', 'AbERP_ResolveHint', 'What to resolve', 50, 'Y', 'Y', 50),
      ('24a02410-f015-4f01-8e15-000000000001', 'AD_User_ID', 'Employee', 60, 'Y', 'Y', 60),
      ('24a02410-f016-4f01-8e15-000000000001', 'DueDate', 'Due / Expiry', 70, 'Y', 'Y', 70),
      ('24a02410-f017-4f01-8e15-000000000001', 'AD_Table_ID', 'Source Table', 80, 'Y', 'N', 80),
      ('24a02410-f018-4f01-8e15-000000000001', 'Record_ID', 'Source Record', 90, 'Y', 'Y', 90),
      ('24a02410-f019-4f01-8e15-000000000001', 'DateDetected', 'Detected', 100, 'Y', 'N', 100),
      ('24a02410-f020-4f01-8e15-000000000001', 'IsResolved', 'Resolved', 110, 'N', 'N', 0)
    ) AS t(uu, col, fname, seq, disp, grid, gseq)
  LOOP
    SELECT ad_column_id INTO v_col_id
    FROM ad_column
    WHERE ad_table_id = v_result_table AND columnname = r.col;
    IF v_col_id IS NULL THEN
      RAISE NOTICE 'SAW024 skip field % — column missing', r.col;
      CONTINUE;
    END IF;

    SELECT ad_field_id INTO v_field_id FROM ad_field WHERE ad_field_uu = r.uu;
    IF v_field_id IS NULL THEN
      SELECT ad_field_id INTO v_field_id
      FROM ad_field WHERE ad_tab_id = v_tab_id AND ad_column_id = v_col_id;
    END IF;

    IF v_field_id IS NULL THEN
      INSERT INTO ad_field (
        ad_field_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby,
        name, description, help, iscentrallymaintained,
        ad_tab_id, ad_column_id,
        isdisplayed, displaylength, isreadonly, seqno, issameline,
        isheading, isfieldonly, isencrypted, entitytype,
        isdisplayedgrid, seqnogrid, xposition, columnspan, numlines, ad_field_uu
      ) VALUES (
        nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
        0, 0, 'Y', NOW(), 100, NOW(), 100,
        r.fname,
        CASE r.col
          WHEN 'ResultMessage' THEN 'Why this finding was raised'
          WHEN 'AbERP_ResolveHint' THEN 'What to do to clear it'
          WHEN 'Record_ID' THEN 'Source record key — use Zoom Across to open'
          WHEN 'AD_Table_ID' THEN 'Source table for Zoom Across'
          ELSE r.fname
        END,
        CASE r.col
          WHEN 'ResultMessage' THEN 'Explains the failed check (credential name and expiry).'
          WHEN 'AbERP_ResolveHint' THEN 'Short resolve action from the Compliance Rule. After fixing the source, run Refresh Compliance.'
          WHEN 'Record_ID' THEN 'Select this row, then toolbar Zoom Across to open Credential Assignment and fix the assignment.'
          WHEN 'AD_Table_ID' THEN 'Must stay AbERP_CredentialAssignment for Employee findings so Zoom Across opens the right window.'
          WHEN 'AbERP_ComplianceRule_ID' THEN 'Which Employee rule failed.'
          ELSE NULL
        END,
        'N', v_tab_id, v_col_id,
        r.disp, 0, 'Y', r.seq, 'N',
        'N', 'N', 'N', 'Ab_ERP',
        r.grid, r.gseq, 1, CASE WHEN r.col IN ('ResultMessage','AbERP_ResolveHint') THEN 5 ELSE 2 END,
        CASE WHEN r.col IN ('ResultMessage','AbERP_ResolveHint') THEN 2 ELSE 1 END,
        r.uu
      );
    ELSE
      UPDATE ad_field SET
        name = r.fname,
        isdisplayed = r.disp,
        isdisplayedgrid = r.grid,
        seqno = r.seq,
        seqnogrid = r.gseq,
        isreadonly = 'Y',
        ad_field_uu = COALESCE(ad_field_uu, r.uu),
        updated = NOW()
      WHERE ad_field_id = v_field_id;
    END IF;
  END LOOP;

  -- Tab translation (en_US) if present
  INSERT INTO ad_tab_trl (ad_tab_id, ad_language, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, name, description, help, istranslated)
  SELECT v_tab_id, l.ad_language, 0, 0, 'Y',
    NOW(), 100, NOW(), 100,
    'Open Findings',
    'Employee compliance issues — why, what to fix, open source record',
    'Each row is one open Employee finding from the last Refresh Compliance.',
    'N'
  FROM ad_language l
  WHERE l.issystemlanguage = 'Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_tab_trl t WHERE t.ad_tab_id = v_tab_id AND t.ad_language = l.ad_language
    );

  RAISE NOTICE 'SAW024 Open Findings tab=% window=% linkCol=% parentCol=% credWindow=%',
    v_tab_id, v_window_id, v_link_col, v_dash_pk_col, v_cred_window;
END $$;

-- Zoomable Open Assignment (Table reference on Record_ID) for one-click open
DO $$
DECLARE
  v_result_table INTEGER;
  v_cred_table INTEGER;
  v_key_col INTEGER;
  v_disp_col INTEGER;
  v_ref_id INTEGER;
  v_col_id INTEGER;
  v_tab_id INTEGER;
  v_field_id INTEGER;
BEGIN
  SELECT ad_table_id INTO v_result_table FROM ad_table WHERE tablename = 'AbERP_ComplianceResult';
  SELECT ad_table_id INTO v_cred_table FROM ad_table WHERE tablename = 'AbERP_CredentialAssignment';
  SELECT ad_column_id INTO v_key_col FROM ad_column
  WHERE ad_table_id = v_cred_table AND columnname = 'AbERP_CredentialAssignment_ID';
  SELECT ad_column_id INTO v_disp_col FROM ad_column
  WHERE ad_table_id = v_cred_table AND columnname = 'Name';
  IF v_result_table IS NULL OR v_cred_table IS NULL OR v_key_col IS NULL OR v_disp_col IS NULL THEN
    RAISE EXCEPTION 'SAW024: missing tables/columns for Open Assignment reference';
  END IF;

  SELECT ad_reference_id INTO v_ref_id
  FROM ad_reference WHERE ad_reference_uu = '24a02420-c0d4-4f01-8e15-000000000001';
  IF v_ref_id IS NULL THEN
    SELECT ad_reference_id INTO v_ref_id FROM ad_reference WHERE name = 'AbERP_CredentialAssignment' AND validationtype = 'T';
  END IF;

  IF v_ref_id IS NULL THEN
    INSERT INTO ad_reference (
      ad_reference_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, validationtype, vformat, entitytype, ad_reference_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Reference' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_CredentialAssignment', 'Credential Assignment table', 'SAW024 Open Findings zoom',
      'T', NULL, 'Ab_ERP', '24a02420-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_reference_id INTO v_ref_id;

    INSERT INTO ad_ref_table (
      ad_reference_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      ad_table_id, ad_key, ad_display, isvaluedisplayed, entitytype, whereclause, orderbyclause
    ) VALUES (
      v_ref_id, 0, 0, 'Y', NOW(), 100, NOW(), 100,
      v_cred_table, v_key_col, v_disp_col, 'N', 'Ab_ERP', NULL, NULL
    );
  ELSE
    UPDATE ad_reference SET
      name = 'AbERP_CredentialAssignment',
      validationtype = 'T',
      entitytype = 'Ab_ERP',
      ad_reference_uu = COALESCE(ad_reference_uu, '24a02420-c0d4-4f01-8e15-000000000001'),
      isactive = 'Y',
      updated = NOW()
    WHERE ad_reference_id = v_ref_id;

    IF NOT EXISTS (SELECT 1 FROM ad_ref_table WHERE ad_reference_id = v_ref_id) THEN
      INSERT INTO ad_ref_table (
        ad_reference_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby,
        ad_table_id, ad_key, ad_display, isvaluedisplayed, entitytype
      ) VALUES (
        v_ref_id, 0, 0, 'Y', NOW(), 100, NOW(), 100,
        v_cred_table, v_key_col, v_disp_col, 'N', 'Ab_ERP'
      );
    ELSE
      UPDATE ad_ref_table SET
        ad_table_id = v_cred_table,
        ad_key = v_key_col,
        ad_display = v_disp_col,
        updated = NOW()
      WHERE ad_reference_id = v_ref_id;
    END IF;
  END IF;

  SELECT ad_column_id INTO v_col_id
  FROM ad_column
  WHERE ad_column_uu = '24a02402-c003-4f01-8e15-000000000001'
     OR (ad_table_id = v_result_table AND columnname = 'AbERP_OpenAssignment_ID')
  LIMIT 1;

  IF v_col_id IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, version, entitytype,
      columnname, ad_table_id, ad_reference_id, ad_reference_value_id, fieldlength,
      iskey, isparent, ismandatory, isupdateable, isidentifier,
      seqno, istranslated, isencrypted, isselectioncolumn,
      columnsql, isautocomplete, isalwaysupdateable,
      isallowcopy, issyncdatabase, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Open Assignment', 'Credential Assignment to fix',
      'Click the zoom icon to open the Credential Assignment. Employee findings only.',
      1, 'Ab_ERP',
      'AbERP_OpenAssignment_ID', v_result_table, 18, v_ref_id, 10,
      'N', 'N', 'N', 'N', 'N',
      95, 'N', 'N', 'N',
      'Record_ID', 'N', 'N',
      'N', 'N', '24a02402-c003-4f01-8e15-000000000001'
    ) RETURNING ad_column_id INTO v_col_id;
  ELSE
    UPDATE ad_column SET
      name = 'Open Assignment',
      columnsql = 'Record_ID',
      ad_reference_id = 18,
      ad_reference_value_id = v_ref_id,
      isupdateable = 'N',
      entitytype = 'Ab_ERP',
      ad_column_uu = COALESCE(ad_column_uu, '24a02402-c003-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_column_id = v_col_id;
  END IF;

  SELECT ad_tab_id INTO v_tab_id FROM ad_tab WHERE ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001';
  IF v_tab_id IS NULL THEN
    RAISE EXCEPTION 'SAW024: Open Findings tab missing before Open Assignment field';
  END IF;

  SELECT ad_field_id INTO v_field_id FROM ad_field WHERE ad_field_uu = '24a02410-f021-4f01-8e15-000000000001';
  IF v_field_id IS NULL THEN
    SELECT ad_field_id INTO v_field_id FROM ad_field WHERE ad_tab_id = v_tab_id AND ad_column_id = v_col_id;
  END IF;

  IF v_field_id IS NULL THEN
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, iscentrallymaintained,
      ad_tab_id, ad_column_id,
      isdisplayed, displaylength, isreadonly, seqno, issameline,
      isheading, isfieldonly, isencrypted, entitytype,
      isdisplayedgrid, seqnogrid, xposition, columnspan, numlines, ad_field_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Open Assignment', 'Open the Credential Assignment to fix',
      'Use the field zoom (right of the value) to open the assignment. Then renew/update Expiry Date and Refresh Compliance.',
      'N', v_tab_id, v_col_id,
      'Y', 0, 'Y', 85, 'N',
      'N', 'N', 'N', 'Ab_ERP',
      'Y', 85, 1, 2, 1, '24a02410-f021-4f01-8e15-000000000001'
    );
  ELSE
    UPDATE ad_field SET
      name = 'Open Assignment',
      isdisplayed = 'Y',
      isdisplayedgrid = 'Y',
      seqno = 85,
      seqnogrid = 85,
      isreadonly = 'Y',
      ad_field_uu = COALESCE(ad_field_uu, '24a02410-f021-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_field_id = v_field_id;
  END IF;

  -- Prefer Open Assignment over raw Source Record in grid
  UPDATE ad_field SET isdisplayedgrid = 'N', updated = NOW()
  WHERE ad_tab_id = v_tab_id
    AND ad_column_id = (SELECT ad_column_id FROM ad_column WHERE ad_table_id = v_result_table AND columnname = 'Record_ID');

  RAISE NOTICE 'SAW024 Open Assignment ref=% col=%', v_ref_id, v_col_id;
END $$;

-- Verify
SELECT t.seqno, t.name, t.tablevel,
       (SELECT columnname FROM ad_column c WHERE c.ad_column_id = t.ad_column_id) AS child_link,
       (SELECT columnname FROM ad_column c WHERE c.ad_column_id = t.parent_column_id) AS parent_col
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.ad_window_uu = '23a02305-c0d4-4f01-8e15-000000000001'
ORDER BY t.seqno;

SELECT f.seqno, f.name, c.columnname, f.isdisplayed, f.isdisplayedgrid
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
WHERE t.ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001'
ORDER BY f.seqno;
