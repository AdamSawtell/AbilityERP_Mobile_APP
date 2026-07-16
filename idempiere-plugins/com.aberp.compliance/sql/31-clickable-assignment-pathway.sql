-- SAW024-31 — Clickable pathway to Credential Assignment from Open Findings
-- Issues fixed:
--  1) Form/grid Open & Fix disabled because parent Employee tab IsReadOnly=Y
--  2) Assignment shown as string Value only (no Zoom) — restore Search field on PK
--  3) Hide dead grid Button column; keep form + toolbar + Process → Open & Fix
SET search_path TO adempiere;

DO $$
DECLARE
  v_win INTEGER;
  v_emp_tab INTEGER;
  v_find_tab INTEGER;
  v_result_table INTEGER;
  v_cred_table INTEGER;
  v_ref_id INTEGER;
  v_process_id INTEGER;
  v_src_col INTEGER;
  v_btn_col INTEGER;
  v_lbl_col INTEGER;
BEGIN
  SELECT ad_window_id INTO v_win FROM ad_window
  WHERE ad_window_uu = '23a02305-c0d4-4f01-8e15-000000000001'
     OR name = 'NDIS Audit Tool'
  LIMIT 1;

  SELECT ad_tab_id INTO v_emp_tab FROM ad_tab
  WHERE ad_window_id = v_win AND name = 'Employee' LIMIT 1;

  SELECT ad_tab_id INTO v_find_tab FROM ad_tab
  WHERE ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001'
     OR (ad_window_id = v_win AND name = 'Open Findings')
  LIMIT 1;

  SELECT ad_table_id INTO v_result_table FROM ad_table WHERE tablename = 'AbERP_ComplianceResult';
  SELECT ad_table_id INTO v_cred_table FROM ad_table WHERE tablename = 'AbERP_CredentialAssignment';
  SELECT ad_reference_id INTO v_ref_id FROM ad_reference
  WHERE name = 'AbERP_CredentialAssignment' LIMIT 1;
  SELECT ad_process_id INTO v_process_id FROM ad_process
  WHERE value = 'AbERP_Compliance_OpenSource' LIMIT 1;

  IF v_find_tab IS NULL OR v_result_table IS NULL OR v_ref_id IS NULL THEN
    RAISE EXCEPTION 'SAW024-31: Open Findings / result table / CA reference missing';
  END IF;

  -- Parent Employee was locking child Open & Fix buttons
  IF v_emp_tab IS NOT NULL THEN
    UPDATE ad_tab SET
      isreadonly = 'N',
      updated = NOW()
    WHERE ad_tab_id = v_emp_tab;

    UPDATE ad_field SET
      isreadonly = 'Y',
      updated = NOW()
    WHERE ad_tab_id = v_emp_tab;
  END IF;

  UPDATE ad_tab SET
    isreadonly = 'N',
    updated = NOW()
  WHERE ad_tab_id = v_find_tab;

  -- Ensure CA Table reference key/display
  UPDATE ad_ref_table SET
    ad_table_id = v_cred_table,
    ad_key = (SELECT ad_column_id FROM ad_column
              WHERE ad_table_id = v_cred_table AND columnname = 'AbERP_CredentialAssignment_ID'),
    ad_display = (SELECT ad_column_id FROM ad_column
                  WHERE ad_table_id = v_cred_table AND columnname = 'Value'),
    isvaluedisplayed = 'N',
    updated = NOW()
  WHERE ad_reference_id = v_ref_id;

  SELECT ad_column_id INTO v_src_col FROM ad_column
  WHERE ad_table_id = v_result_table AND columnname = 'AbERP_SourceAssignment_ID';
  SELECT ad_column_id INTO v_btn_col FROM ad_column
  WHERE ad_table_id = v_result_table AND columnname = 'AbERP_OpenSource';
  SELECT ad_column_id INTO v_lbl_col FROM ad_column
  WHERE ad_table_id = v_result_table AND columnname = 'AbERP_AssignmentLabel';

  -- Assignment = Search lookup on physical CA id (Zoom works)
  UPDATE ad_column SET
    ad_reference_id = 30,
    ad_reference_value_id = v_ref_id,
    isupdateable = 'N',
    isalwaysupdateable = 'N',
    name = 'Assignment',
    description = 'Credential Assignment — Zoom to open the record',
    help = 'Right-click / field menu → Zoom, or click Open & Fix.',
    updated = NOW()
  WHERE ad_column_id = v_src_col;

  UPDATE ad_field SET
    name = 'Assignment',
    description = 'Credential Assignment linked to this finding',
    help = 'Field menu → Zoom opens this Credential Assignment. Or use Open & Fix / Process → Open & Fix.',
    isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    isreadonly = 'Y',
    seqno = 8,
    seqnogrid = 8,
    ad_reference_id = NULL,
    ad_reference_value_id = NULL,
    updated = NOW()
  WHERE ad_tab_id = v_find_tab AND ad_column_id = v_src_col;

  -- Hide string label (duplicate of Search display)
  IF v_lbl_col IS NOT NULL THEN
    UPDATE ad_field SET
      isdisplayed = 'N',
      isdisplayedgrid = 'N',
      updated = NOW()
    WHERE ad_tab_id = v_find_tab AND ad_column_id = v_lbl_col;
  END IF;

  -- Open & Fix: form only (grid buttons stay dead on included tabs)
  IF v_btn_col IS NOT NULL AND v_process_id IS NOT NULL THEN
    UPDATE ad_column SET
      ad_reference_id = 28,
      ad_process_id = v_process_id,
      isupdateable = 'Y',
      isalwaysupdateable = 'Y',
      name = 'Open & Fix',
      updated = NOW()
    WHERE ad_column_id = v_btn_col;

    UPDATE ad_field SET
      name = 'Open & Fix',
      description = 'Open Credential Assignment for this finding',
      help = 'Opens the linked Credential Assignment so you can renew/update it.',
      isdisplayed = 'Y',
      isdisplayedgrid = 'N',
      isreadonly = 'N',
      seqno = 5,
      seqnogrid = 5,
      updated = NOW()
    WHERE ad_tab_id = v_find_tab AND ad_column_id = v_btn_col;
  END IF;

  -- Toolbar Open & Fix (same process)
  IF v_process_id IS NOT NULL THEN
    UPDATE ad_process SET
      name = 'Open & Fix',
      description = 'Open Credential Assignment for the selected Open Findings row',
      help = 'Select an Open Findings row, then run Open & Fix to jump to the Credential Assignment.',
      updated = NOW()
    WHERE ad_process_id = v_process_id;

    UPDATE ad_toolbarbutton SET
      isactive = 'Y',
      name = 'Open & Fix',
      componentname = 'Open & Fix',
      action = 'W',
      seqno = 10,
      updated = NOW()
    WHERE ad_tab_id = v_find_tab AND ad_process_id = v_process_id;
  END IF;

  -- Keep data fields readonly on Open Findings
  UPDATE ad_field SET
    isreadonly = 'Y',
    updated = NOW()
  WHERE ad_tab_id = v_find_tab
    AND ad_column_id <> v_btn_col;

  UPDATE ad_field SET
    isreadonly = 'N',
    updated = NOW()
  WHERE ad_tab_id = v_find_tab AND ad_column_id = v_btn_col;

  RAISE NOTICE 'SAW024-31 clickable Assignment + Open & Fix ready find_tab=% emp_tab=%',
    v_find_tab, v_emp_tab;
END $$;

SELECT f.seqno, f.name, c.columnname, f.isdisplayed, f.isdisplayedgrid, f.isreadonly,
       c.ad_reference_id, c.ad_reference_value_id, c.ad_process_id
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE f.ad_tab_id = (SELECT ad_tab_id FROM ad_tab WHERE ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001')
  AND c.columnname IN ('AbERP_OpenSource','AbERP_SourceAssignment_ID','AbERP_AssignmentLabel')
ORDER BY f.seqno;

SELECT name, isreadonly FROM ad_tab
WHERE name IN ('Employee','Open Findings')
  AND ad_window_id = (SELECT ad_window_id FROM ad_window WHERE name = 'NDIS Audit Tool' LIMIT 1);
