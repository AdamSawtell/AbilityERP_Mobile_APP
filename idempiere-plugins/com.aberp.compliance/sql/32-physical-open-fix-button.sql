-- SAW024-32 — Real Open & Fix pathway (physical button + readable Assignment Value)
-- Root causes:
--  1) AbERP_OpenSource was virtual (ColumnSQL NULL::bpchar) → button always disabled
--  2) Search Assignment on included tab renders as -1 → use string Value label instead
SET search_path TO adempiere;

-- Physical button flag column
ALTER TABLE aberp_complianceresult
  ADD COLUMN IF NOT EXISTS aberp_opensource CHAR(1) DEFAULT NULL;

DO $$
DECLARE
  v_find_tab INTEGER;
  v_result_table INTEGER;
  v_process_id INTEGER;
  v_btn_col INTEGER;
  v_src_col INTEGER;
  v_lbl_col INTEGER;
  v_emp_tab INTEGER;
BEGIN
  SELECT ad_tab_id INTO v_find_tab FROM ad_tab
  WHERE ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001';
  SELECT ad_table_id INTO v_result_table FROM ad_table WHERE tablename = 'AbERP_ComplianceResult';
  SELECT ad_process_id INTO v_process_id FROM ad_process WHERE value = 'AbERP_Compliance_OpenSource';
  SELECT ad_tab_id INTO v_emp_tab FROM ad_tab
  WHERE name = 'Employee'
    AND ad_window_id = (SELECT ad_window_id FROM ad_window WHERE name = 'NDIS Audit Tool' LIMIT 1);

  IF v_find_tab IS NULL OR v_result_table IS NULL OR v_process_id IS NULL THEN
    RAISE EXCEPTION 'SAW024-32: Open Findings / process missing';
  END IF;

  -- Parent must not be readonly or child buttons stay dead
  IF v_emp_tab IS NOT NULL THEN
    UPDATE ad_tab SET isreadonly = 'N', updated = NOW() WHERE ad_tab_id = v_emp_tab;
    UPDATE ad_field SET isreadonly = 'Y', updated = NOW() WHERE ad_tab_id = v_emp_tab;
  END IF;
  UPDATE ad_tab SET isreadonly = 'N', updated = NOW() WHERE ad_tab_id = v_find_tab;

  SELECT ad_column_id INTO v_btn_col FROM ad_column
  WHERE ad_table_id = v_result_table AND columnname = 'AbERP_OpenSource';
  SELECT ad_column_id INTO v_src_col FROM ad_column
  WHERE ad_table_id = v_result_table AND columnname = 'AbERP_SourceAssignment_ID';
  SELECT ad_column_id INTO v_lbl_col FROM ad_column
  WHERE ad_table_id = v_result_table AND columnname = 'AbERP_AssignmentLabel';

  -- Make Open & Fix a real Button column (no ColumnSQL)
  UPDATE ad_column SET
    ad_reference_id = 28,
    ad_process_id = v_process_id,
    columnsql = NULL,
    isupdateable = 'Y',
    isalwaysupdateable = 'Y',
    ismandatory = 'N',
    fieldlength = 1,
    name = 'Open & Fix',
    description = 'Open Credential Assignment for this finding',
    help = 'Opens the linked Credential Assignment so you can renew/update and clear the finding.',
    updated = NOW()
  WHERE ad_column_id = v_btn_col;

  UPDATE ad_field SET
    name = 'Open & Fix',
    description = 'Open Credential Assignment for this finding',
    help = 'Click to open the Credential Assignment linked to this finding.',
    isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    isreadonly = 'N',
    seqno = 5,
    seqnogrid = 5,
    updated = NOW()
  WHERE ad_tab_id = v_find_tab AND ad_column_id = v_btn_col;

  -- Assignment Value label (always resolves; Search shows -1 on this included tab)
  IF v_lbl_col IS NOT NULL THEN
    UPDATE ad_column SET
      name = 'Assignment',
      description = 'Credential Assignment Value',
      columnsql = '(SELECT ca.Value FROM AbERP_CredentialAssignment ca WHERE ca.AbERP_CredentialAssignment_ID=COALESCE(AbERP_ComplianceResult.AbERP_SourceAssignment_ID, AbERP_ComplianceResult.AbERP_OpenAssignment_ID, AbERP_ComplianceResult.Record_ID))',
      ad_reference_id = 10,
      isupdateable = 'N',
      updated = NOW()
    WHERE ad_column_id = v_lbl_col;

    UPDATE ad_field SET
      name = 'Assignment',
      description = 'Credential Assignment Value',
      help = 'Click Open & Fix (or Process → Open & Fix) to open this Credential Assignment.',
      isdisplayed = 'Y',
      isdisplayedgrid = 'Y',
      isreadonly = 'Y',
      seqno = 8,
      seqnogrid = 8,
      updated = NOW()
    WHERE ad_tab_id = v_find_tab AND ad_column_id = v_lbl_col;
  END IF;

  -- Hide broken Search Assignment (-1)
  IF v_src_col IS NOT NULL THEN
    UPDATE ad_column SET
      ad_reference_id = 11,
      ad_reference_value_id = NULL,
      name = 'Source Assignment ID',
      isupdateable = 'N',
      updated = NOW()
    WHERE ad_column_id = v_src_col;

    UPDATE ad_field SET
      name = 'Source Assignment ID',
      isdisplayed = 'N',
      isdisplayedgrid = 'N',
      isreadonly = 'Y',
      updated = NOW()
    WHERE ad_tab_id = v_find_tab AND ad_column_id = v_src_col;
  END IF;

  UPDATE ad_process SET
    name = 'Open & Fix',
    description = 'Open Credential Assignment for the selected Open Findings row',
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

  -- Data fields readonly; button writable
  UPDATE ad_field SET isreadonly = 'Y', updated = NOW()
  WHERE ad_tab_id = v_find_tab AND ad_column_id <> v_btn_col;
  UPDATE ad_field SET isreadonly = 'N', updated = NOW()
  WHERE ad_tab_id = v_find_tab AND ad_column_id = v_btn_col;

  RAISE NOTICE 'SAW024-32 physical Open & Fix + Assignment Value ready';
END $$;

SELECT f.seqno, f.name, c.columnname, f.isdisplayed, f.isdisplayedgrid, f.isreadonly,
       c.ad_reference_id, c.columnsql IS NOT NULL AS has_sql, c.ad_process_id
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE f.ad_tab_id = (SELECT ad_tab_id FROM ad_tab WHERE ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001')
  AND c.columnname IN ('AbERP_OpenSource','AbERP_SourceAssignment_ID','AbERP_AssignmentLabel')
ORDER BY f.seqno;

SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='aberp_complianceresult' AND column_name='aberp_opensource';
