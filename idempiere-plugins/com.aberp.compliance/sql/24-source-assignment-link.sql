-- =============================================================================
-- SAW024 — Working link to Credential Assignment + toolbar Open & Fix
-- Fresh physical AbERP_SourceAssignment_ID (never virtual) + AD_ToolBarButton
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_toolbarbutton_id),0)+1 FROM ad_toolbarbutton))
WHERE name='AD_ToolBarButton' AND istableid='Y';

ALTER TABLE aberp_complianceresult
  ADD COLUMN IF NOT EXISTS aberp_sourceassignment_id NUMERIC(10);

UPDATE aberp_complianceresult r
SET aberp_sourceassignment_id = r.record_id
WHERE r.ad_table_id = (
        SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_CredentialAssignment' LIMIT 1
      )
  AND COALESCE(r.record_id, 0) > 0
  AND (r.aberp_sourceassignment_id IS DISTINCT FROM r.record_id);

DO $$
DECLARE
  v_result_table INTEGER;
  v_cred_table INTEGER;
  v_ref_id INTEGER;
  v_cred_window INTEGER;
  v_find_tab INTEGER;
  v_element_id INTEGER;
  v_col_id INTEGER;
  v_field_id INTEGER;
  v_process_id INTEGER;
  v_ttb_id INTEGER;
BEGIN
  SELECT ad_table_id INTO v_result_table FROM ad_table WHERE tablename = 'AbERP_ComplianceResult';
  SELECT ad_table_id INTO v_cred_table FROM ad_table WHERE tablename = 'AbERP_CredentialAssignment';
  SELECT ad_tab_id INTO v_find_tab FROM ad_tab WHERE ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001';
  SELECT ad_reference_id INTO v_ref_id
  FROM ad_reference
  WHERE ad_reference_uu = '24a02420-c0d4-4f01-8e15-000000000001'
     OR name = 'AbERP_CredentialAssignment'
  LIMIT 1;
  SELECT ad_window_id INTO v_cred_window
  FROM ad_window
  WHERE ad_window_uu = 'f974f00f-5cd3-4a5f-973e-0347aacc59df'
     OR name = 'Credential Assignment'
  LIMIT 1;
  SELECT ad_process_id INTO v_process_id
  FROM ad_process WHERE value = 'AbERP_Compliance_OpenSource' LIMIT 1;

  IF v_result_table IS NULL OR v_cred_table IS NULL OR v_find_tab IS NULL OR v_ref_id IS NULL OR v_cred_window IS NULL THEN
    RAISE EXCEPTION 'SAW024-24: prerequisites missing (result/cred/tab/ref/window)';
  END IF;
  IF v_process_id IS NULL THEN
    RAISE EXCEPTION 'SAW024-24: AbERP_Compliance_OpenSource process missing — run 19 first';
  END IF;

  -- Ref table: Value display + zoom window
  UPDATE ad_ref_table SET
    ad_table_id = v_cred_table,
    ad_key = (SELECT ad_column_id FROM ad_column WHERE ad_table_id = v_cred_table AND columnname = 'AbERP_CredentialAssignment_ID'),
    ad_display = COALESCE(
      (SELECT ad_column_id FROM ad_column WHERE ad_table_id = v_cred_table AND columnname = 'Value'),
      (SELECT ad_column_id FROM ad_column WHERE ad_table_id = v_cred_table AND columnname = 'Name')
    ),
    ad_window_id = v_cred_window,
    isvaluedisplayed = 'Y',
    isdisplayidentifier = 'Y',
    updated = NOW()
  WHERE ad_reference_id = v_ref_id;

  UPDATE ad_table SET ad_window_id = v_cred_window, updated = NOW()
  WHERE ad_table_id = v_cred_table;

  -- Element
  SELECT ad_element_id INTO v_element_id FROM ad_element WHERE columnname = 'AbERP_SourceAssignment_ID' LIMIT 1;
  IF v_element_id IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, description, help, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_SourceAssignment_ID', 'Ab_ERP', 'Open Assignment', 'Open Assignment',
      'Credential Assignment linked to this finding',
      'Zoom to open the Credential Assignment, renew/update expiry, then Refresh Compliance.',
      '24a02450-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_element_id INTO v_element_id;
  END IF;

  -- Brand-new physical Table column (never had ColumnSQL)
  SELECT ad_column_id INTO v_col_id
  FROM ad_column
  WHERE ad_column_uu = '24a02402-c005-4f01-8e15-000000000001'
     OR (ad_table_id = v_result_table AND columnname = 'AbERP_SourceAssignment_ID')
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
      isallowcopy, issyncdatabase, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Open Assignment', 'Credential Assignment to fix',
      'Zoom to open Credential Assignment and take action.',
      0, 'Ab_ERP',
      'AbERP_SourceAssignment_ID', v_result_table, 18, v_ref_id, 10,
      'N', 'N', 'N', 'N', 'N',
      86, 'N', 'N', 'N',
      v_element_id, 'N', 'N',
      'N', 'Y', '24a02402-c005-4f01-8e15-000000000001'
    ) RETURNING ad_column_id INTO v_col_id;
  ELSE
    UPDATE ad_column SET
      columnsql = NULL,
      ad_reference_id = 18,
      ad_reference_value_id = v_ref_id,
      isupdateable = 'N',
      issyncdatabase = 'Y',
      name = 'Open Assignment',
      ad_element_id = v_element_id,
      entitytype = 'Ab_ERP',
      ad_column_uu = COALESCE(ad_column_uu, '24a02402-c005-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_column_id = v_col_id;
  END IF;

  -- Hide broken prior Open Assignment fields
  UPDATE ad_field SET
    isdisplayed = 'N', isdisplayedgrid = 'N', updated = NOW()
  WHERE ad_tab_id = v_find_tab
    AND ad_column_id IN (
      SELECT ad_column_id FROM ad_column
      WHERE ad_table_id = v_result_table
        AND columnname IN ('AbERP_OpenAssignment_ID', 'Record_ID', 'AD_Table_ID')
    );

  -- Field for new Source Assignment
  SELECT ad_field_id INTO v_field_id FROM ad_field WHERE ad_field_uu = '24a02410-f030-4f01-8e15-000000000001';
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
      'Open Assignment', 'Open Credential Assignment to take action',
      'Click Zoom (field menu / magnifier) to open this Credential Assignment. Renew or update Expiry Date, Save, then Refresh Compliance.',
      'N', v_find_tab, v_col_id,
      'Y', 20, 'Y', 8, 'N',
      'N', 'N', 'N', 'Ab_ERP',
      'Y', 8, 1, 2, 1, '24a02410-f030-4f01-8e15-000000000001'
    );
  ELSE
    UPDATE ad_field SET
      name = 'Open Assignment',
      ad_column_id = v_col_id,
      isdisplayed = 'Y',
      isdisplayedgrid = 'Y',
      isreadonly = 'Y',
      seqno = 8,
      seqnogrid = 8,
      ad_field_uu = COALESCE(ad_field_uu, '24a02410-f030-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_field_id = v_field_id;
  END IF;

  -- Toolbar Open & Fix on Open Findings tab (Action W = window process)
  SELECT ad_toolbarbutton_id INTO v_ttb_id
  FROM ad_toolbarbutton WHERE ad_toolbarbutton_uu = '24a02460-c0d4-4f01-8e15-000000000001';
  IF v_ttb_id IS NULL THEN
    SELECT ad_toolbarbutton_id INTO v_ttb_id
    FROM ad_toolbarbutton
    WHERE ad_tab_id = v_find_tab AND name = 'Open & Fix' AND action = 'W'
    LIMIT 1;
  END IF;

  IF v_ttb_id IS NULL THEN
    INSERT INTO ad_toolbarbutton (
      ad_toolbarbutton_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, componentname, action, ad_tab_id, ad_process_id,
      seqno, isadvancedbutton, isaddseparator, entitytype, iscustomization,
      displaylogic, ad_toolbarbutton_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_ToolBarButton' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Open & Fix', 'Open & Fix', 'W', v_find_tab, v_process_id,
      10, 'N', 'N', 'Ab_ERP', 'N',
      NULL, '24a02460-c0d4-4f01-8e15-000000000001'
    );
  ELSE
    UPDATE ad_toolbarbutton SET
      isactive = 'Y',
      ad_tab_id = v_find_tab,
      ad_process_id = v_process_id,
      action = 'W',
      name = 'Open & Fix',
      componentname = 'Open & Fix',
      entitytype = 'Ab_ERP',
      ad_toolbarbutton_uu = COALESCE(ad_toolbarbutton_uu, '24a02460-c0d4-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_toolbarbutton_id = v_ttb_id;
  END IF;

  -- Keep grid Open & Fix button usable
  UPDATE ad_column SET
    isupdateable = 'Y',
    isalwaysupdateable = 'Y',
    istoolbarbutton = 'B',
    updated = NOW()
  WHERE ad_table_id = v_result_table AND columnname = 'AbERP_OpenSource';

  UPDATE ad_field SET
    isreadonly = 'N',
    isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    seqno = 5,
    seqnogrid = 5,
    updated = NOW()
  WHERE ad_tab_id = v_find_tab
    AND ad_column_id = (
      SELECT ad_column_id FROM ad_column
      WHERE ad_table_id = v_result_table AND columnname = 'AbERP_OpenSource'
    );

  UPDATE ad_tab SET isreadonly = 'N', updated = NOW() WHERE ad_tab_id = v_find_tab;

  RAISE NOTICE 'SAW024-24 SourceAssignment col=% tab=% process=%', v_col_id, v_find_tab, v_process_id;
END $$;

SELECT COUNT(*) AS source_set
FROM aberp_complianceresult r
JOIN aberp_compliancerule ru ON ru.aberp_compliancerule_id = r.aberp_compliancerule_id
WHERE ru.compliancecategory = 'W' AND r.isresolved = 'N' AND r.isactive = 'Y'
  AND r.aberp_sourceassignment_id IS NOT NULL;

SELECT f.seqnogrid, f.name, f.isdisplayedgrid, c.columnname, c.ad_reference_id, c.columnsql
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE f.ad_tab_id = (SELECT ad_tab_id FROM ad_tab WHERE ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001')
  AND f.isdisplayedgrid = 'Y'
ORDER BY f.seqnogrid;

SELECT name, action, componentname, isactive
FROM ad_toolbarbutton
WHERE ad_toolbarbutton_uu = '24a02460-c0d4-4f01-8e15-000000000001';
