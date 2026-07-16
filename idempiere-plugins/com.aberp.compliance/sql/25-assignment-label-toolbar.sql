-- =============================================================================
-- SAW024-25 — Fix Open Assignment display + working Open & Fix
-- Root cause: Record_ID field still had Table(18) override named "Open Assignment"
-- (included-tab context Record_ID → UI shows -1). Abandon Table lookup display.
-- Show assignment Value via ColumnSQL String; zoom via toolbar/process only.
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';

DO $$
DECLARE
  v_result_table INTEGER;
  v_find_tab INTEGER;
  v_process_id INTEGER;
  v_element_id INTEGER;
  v_col_id INTEGER;
  v_field_id INTEGER;
  v_src_col INTEGER;
BEGIN
  SELECT ad_table_id INTO v_result_table FROM ad_table WHERE tablename = 'AbERP_ComplianceResult';
  SELECT ad_tab_id INTO v_find_tab FROM ad_tab WHERE ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001';
  SELECT ad_process_id INTO v_process_id FROM ad_process WHERE value = 'AbERP_Compliance_OpenSource' LIMIT 1;

  IF v_result_table IS NULL OR v_find_tab IS NULL OR v_process_id IS NULL THEN
    RAISE EXCEPTION 'SAW024-25: prerequisites missing';
  END IF;

  -- 1) Disarm Record_ID / prior Open Assignment fields completely
  UPDATE ad_column SET
    ad_reference_id = 11,
    ad_reference_value_id = NULL,
    updated = NOW()
  WHERE ad_table_id = v_result_table AND columnname = 'Record_ID';

  UPDATE ad_field SET
    name = 'Source Record Key',
    ad_reference_id = NULL,
    ad_reference_value_id = NULL,
    isdisplayed = 'N',
    isdisplayedgrid = 'N',
    updated = NOW()
  WHERE ad_tab_id = v_find_tab
    AND ad_column_id = (
      SELECT ad_column_id FROM ad_column
      WHERE ad_table_id = v_result_table AND columnname = 'Record_ID'
    );

  UPDATE ad_field SET
    name = 'Open Assignment (internal)',
    isdisplayed = 'N',
    isdisplayedgrid = 'N',
    updated = NOW()
  WHERE ad_tab_id = v_find_tab
    AND ad_column_id IN (
      SELECT ad_column_id FROM ad_column
      WHERE ad_table_id = v_result_table
        AND columnname IN ('AbERP_OpenAssignment_ID', 'AD_Table_ID')
    );

  -- 2) SourceAssignment: store as Integer (no MLookup) — hidden, used by process
  SELECT ad_column_id INTO v_src_col
  FROM ad_column
  WHERE ad_table_id = v_result_table AND columnname = 'AbERP_SourceAssignment_ID';

  IF v_src_col IS NULL THEN
    RAISE EXCEPTION 'SAW024-25: AbERP_SourceAssignment_ID missing — run 24 first';
  END IF;

  UPDATE ad_column SET
    ad_reference_id = 11,
    ad_reference_value_id = NULL,
    columnsql = NULL,
    isupdateable = 'N',
    name = 'Source Assignment ID',
    updated = NOW()
  WHERE ad_column_id = v_src_col;

  UPDATE ad_field SET
    name = 'Source Assignment ID',
    ad_reference_id = NULL,
    ad_reference_value_id = NULL,
    isdisplayed = 'N',
    isdisplayedgrid = 'N',
    updated = NOW()
  WHERE ad_tab_id = v_find_tab AND ad_column_id = v_src_col;

  -- 3) Visible label: assignment Value as plain String (ColumnSQL) — no zoom lookup
  SELECT ad_element_id INTO v_element_id
  FROM ad_element WHERE columnname = 'AbERP_AssignmentLabel' LIMIT 1;
  IF v_element_id IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, description, help, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_AssignmentLabel', 'Ab_ERP', 'Assignment', 'Assignment',
      'Credential Assignment Value for this finding',
      'Select the row, then click toolbar Open & Fix to open this Credential Assignment.',
      '24a02470-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_element_id INTO v_element_id;
  END IF;

  SELECT ad_column_id INTO v_col_id
  FROM ad_column
  WHERE ad_column_uu = '24a02402-c025-4f01-8e15-000000000001'
     OR (ad_table_id = v_result_table AND columnname = 'AbERP_AssignmentLabel')
  LIMIT 1;

  IF v_col_id IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, version, entitytype,
      columnname, ad_table_id, ad_reference_id, ad_reference_value_id, fieldlength,
      iskey, isparent, ismandatory, isupdateable, isidentifier,
      seqno, istranslated, isencrypted, isselectioncolumn,
      ad_element_id, isautocomplete, isalwaysupdateable,
      columnsql, isallowcopy, issyncdatabase, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Assignment', 'Credential Assignment Value',
      'Select row and use toolbar Open & Fix to open the assignment.',
      0, 'Ab_ERP',
      'AbERP_AssignmentLabel', v_result_table, 10, NULL, 40,
      'N', 'N', 'N', 'N', 'N',
      8, 'N', 'N', 'N',
      v_element_id, 'N', 'N',
      '(SELECT ca.Value FROM AbERP_CredentialAssignment ca WHERE ca.AbERP_CredentialAssignment_ID=COALESCE(AbERP_ComplianceResult.AbERP_SourceAssignment_ID, AbERP_ComplianceResult.AbERP_OpenAssignment_ID, AbERP_ComplianceResult.Record_ID))',
      'N', 'N', '24a02402-c025-4f01-8e15-000000000001'
    ) RETURNING ad_column_id INTO v_col_id;
  ELSE
    UPDATE ad_column SET
      ad_reference_id = 10,
      ad_reference_value_id = NULL,
      fieldlength = 40,
      isupdateable = 'N',
      columnsql = '(SELECT ca.Value FROM AbERP_CredentialAssignment ca WHERE ca.AbERP_CredentialAssignment_ID=COALESCE(AbERP_ComplianceResult.AbERP_SourceAssignment_ID, AbERP_ComplianceResult.AbERP_OpenAssignment_ID, AbERP_ComplianceResult.Record_ID))',
      name = 'Assignment',
      ad_element_id = v_element_id,
      ad_column_uu = COALESCE(ad_column_uu, '24a02402-c025-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_column_id = v_col_id;
  END IF;

  SELECT ad_field_id INTO v_field_id FROM ad_field WHERE ad_field_uu = '24a02410-f040-4f01-8e15-000000000001';
  IF v_field_id IS NULL THEN
    SELECT ad_field_id INTO v_field_id
    FROM ad_field WHERE ad_tab_id = v_find_tab AND ad_column_id = v_col_id;
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
      'Assignment', 'Credential Assignment to fix',
      'Select this row, then click Open & Fix on the toolbar to open Credential Assignment.',
      'N', v_find_tab, v_col_id,
      'Y', 20, 'Y', 8, 'N',
      'N', 'N', 'N', 'Ab_ERP',
      'Y', 8, 1, 2, 1, '24a02410-f040-4f01-8e15-000000000001'
    );
  ELSE
    UPDATE ad_field SET
      name = 'Assignment',
      ad_column_id = v_col_id,
      isdisplayed = 'Y',
      isdisplayedgrid = 'Y',
      isreadonly = 'Y',
      seqno = 8,
      seqnogrid = 8,
      ad_field_uu = COALESCE(ad_field_uu, '24a02410-f040-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_field_id = v_field_id;
  END IF;

  -- 4) Open & Fix: toolbar process (grid Button columns stay disabled on included tabs)
  UPDATE ad_column SET
    istoolbarbutton = 'Y',
    isupdateable = 'Y',
    isalwaysupdateable = 'Y',
    updated = NOW()
  WHERE ad_table_id = v_result_table AND columnname = 'AbERP_OpenSource';

  UPDATE ad_field SET
    isdisplayed = 'N',
    isdisplayedgrid = 'N',
    isreadonly = 'N',
    updated = NOW()
  WHERE ad_tab_id = v_find_tab
    AND ad_column_id = (
      SELECT ad_column_id FROM ad_column
      WHERE ad_table_id = v_result_table AND columnname = 'AbERP_OpenSource'
    );

  UPDATE ad_toolbarbutton SET
    isactive = 'Y',
    ad_tab_id = v_find_tab,
    ad_process_id = v_process_id,
    action = 'W',
    name = 'Open & Fix',
    componentname = 'Open & Fix',
    isshowmore = 'N',
    seqno = 10,
    updated = NOW()
  WHERE ad_toolbarbutton_uu = '24a02460-c0d4-4f01-8e15-000000000001';

  UPDATE ad_tab SET isreadonly = 'N', updated = NOW() WHERE ad_tab_id = v_find_tab;

  RAISE NOTICE 'SAW024-25 label_col=% tab=%', v_col_id, v_find_tab;
END $$;

-- sanity: sample labels
SELECT r.aberp_complianceresult_id,
       r.aberp_sourceassignment_id,
       (SELECT ca.Value FROM AbERP_CredentialAssignment ca
         WHERE ca.AbERP_CredentialAssignment_ID = COALESCE(r.aberp_sourceassignment_id, r.aberp_openassignment_id, r.record_id)) AS label
FROM aberp_complianceresult r
WHERE r.aberp_complianceresult_id IN (1000019, 1000203)
ORDER BY 1;

SELECT f.seqnogrid, f.name, f.isdisplayedgrid, c.columnname, c.ad_reference_id,
       left(coalesce(c.columnsql,''), 60) AS sql_prefix
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE f.ad_tab_id = (SELECT ad_tab_id FROM ad_tab WHERE ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001')
  AND f.isdisplayedgrid = 'Y'
ORDER BY f.seqnogrid;
