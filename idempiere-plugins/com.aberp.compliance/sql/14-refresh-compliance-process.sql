-- =============================================================================
-- SAW023 Phase 2 — Refresh Compliance process + Organisation Audit toolbar button
-- Process UU: 23a02340-…  Element: 23a02341-…  Column: 23a02342-…  Field: 23a02343-…
-- Requires dashboard VIEW column aberp_refreshcompliance (see 04-dashboard-view.sql)
-- =============================================================================
SET search_path TO adempiere;

-- ---------------------------------------------------------------------------
-- 1. Process
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_uu CONSTANT TEXT := '23a02340-c0d4-4f01-8e15-000000000001';
  v_id INTEGER;
BEGIN
  SELECT ad_process_id INTO v_id FROM ad_process WHERE ad_process_uu = v_uu;
  IF v_id IS NULL THEN
    SELECT ad_process_id INTO v_id FROM ad_process
    WHERE value = 'AbERP_Compliance_Refresh' LIMIT 1;
  END IF;

  IF v_id IS NULL THEN
    INSERT INTO ad_process (
      ad_process_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      value, name, description, help,
      accesslevel, entitytype,
      isreport, isdirectprint,
      classname,
      isbetafunctionality, isserverprocess, showhelp,
      copyfromprocess, ad_process_uu,
      allowmultipleexecution, isprinterpreview
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_Compliance_Refresh', 'Refresh Compliance',
      'Re-evaluate compliance rules and refresh organisation audit scores.',
      'Phase 2 stub: confirms the button and process factory are wired. Live rule evaluation arrives in Phase 3.',
      '3', 'Ab_ERP',
      'N', 'N',
      'com.aberp.compliance.RefreshCompliance',
      'N', 'N', 'S',
      'N', v_uu,
      'P', 'N'
    );
  ELSE
    UPDATE ad_process SET
      value = 'AbERP_Compliance_Refresh',
      name = 'Refresh Compliance',
      description = 'Re-evaluate compliance rules and refresh organisation audit scores.',
      help = 'Phase 2 stub: confirms the button and process factory are wired. Live rule evaluation arrives in Phase 3.',
      classname = 'com.aberp.compliance.RefreshCompliance',
      showhelp = 'S',
      entitytype = 'Ab_ERP',
      isactive = 'Y',
      updated = NOW(),
      updatedby = 100,
      ad_process_uu = COALESCE(NULLIF(ad_process_uu, ''), v_uu)
    WHERE ad_process_id = v_id;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. Element
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_uu CONSTANT TEXT := '23a02341-c0d4-4f01-8e15-000000000001';
  v_id INTEGER;
BEGIN
  SELECT ad_element_id INTO v_id FROM ad_element WHERE ad_element_uu = v_uu;
  IF v_id IS NULL THEN
    SELECT ad_element_id INTO v_id FROM ad_element
    WHERE columnname = 'AbERP_RefreshCompliance' LIMIT 1;
  END IF;

  IF v_id IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, description, help, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_RefreshCompliance', 'Ab_ERP', 'Refresh Compliance', 'Refresh Compliance',
      'Re-evaluate compliance rules and refresh organisation audit scores',
      'Runs the Refresh Compliance process for the current organisation audit row.',
      v_uu
    );
  ELSE
    UPDATE ad_element SET
      columnname = 'AbERP_RefreshCompliance',
      name = 'Refresh Compliance',
      printname = 'Refresh Compliance',
      entitytype = 'Ab_ERP',
      updated = NOW(),
      updatedby = 100,
      ad_element_uu = COALESCE(ad_element_uu, v_uu)
    WHERE ad_element_id = v_id;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Button column on AbERP_ComplianceDashboard
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_uu CONSTANT TEXT := '23a02342-c0d4-4f01-8e15-000000000001';
  v_table_id INTEGER;
  v_element_id INTEGER;
  v_process_id INTEGER;
  v_col_id INTEGER;
  v_ref_button INTEGER;
BEGIN
  SELECT ad_table_id INTO v_table_id
  FROM ad_table
  WHERE ad_table_uu = '23a02304-c0d4-4f01-8e15-000000000001'
     OR tablename = 'AbERP_ComplianceDashboard'
  LIMIT 1;
  IF v_table_id IS NULL THEN
    RAISE EXCEPTION 'SAW023: AbERP_ComplianceDashboard table missing — run 04 first';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'adempiere'
      AND table_name = 'aberp_compliancedashboard'
      AND column_name = 'aberp_refreshcompliance'
  ) THEN
    RAISE EXCEPTION 'SAW023: view column aberp_refreshcompliance missing — re-run 04-dashboard-view.sql';
  END IF;

  SELECT ad_element_id INTO v_element_id
  FROM ad_element WHERE columnname = 'AbERP_RefreshCompliance' LIMIT 1;

  SELECT ad_process_id INTO v_process_id
  FROM ad_process
  WHERE ad_process_uu = '23a02340-c0d4-4f01-8e15-000000000001'
     OR value = 'AbERP_Compliance_Refresh'
  LIMIT 1;
  IF v_process_id IS NULL THEN
    RAISE EXCEPTION 'SAW023: process AbERP_Compliance_Refresh missing';
  END IF;

  SELECT ad_reference_id INTO v_ref_button
  FROM ad_reference WHERE name = 'Button' AND isactive = 'Y' LIMIT 1;
  IF v_ref_button IS NULL THEN
    v_ref_button := 28;
  END IF;

  SELECT ad_column_id INTO v_col_id FROM ad_column WHERE ad_column_uu = v_uu;
  IF v_col_id IS NULL THEN
    SELECT ad_column_id INTO v_col_id
    FROM ad_column
    WHERE ad_table_id = v_table_id AND columnname = 'AbERP_RefreshCompliance'
    LIMIT 1;
  END IF;

  IF v_col_id IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, entitytype, columnname, ad_table_id,
      ad_reference_id, fieldlength, version,
      iskey, isparent, ismandatory, isupdateable, isidentifier, seqno,
      istranslated, isencrypted, isselectioncolumn,
      ad_element_id, ad_process_id, issyncdatabase, isalwaysupdateable,
      isautocomplete, isallowlogging, isallowcopy, seqnoselection,
      istoolbarbutton, issecure, fkconstrainttype, ishtml, isdisablezoomacross,
      ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Refresh Compliance', 'Ab_ERP', 'AbERP_RefreshCompliance', v_table_id,
      v_ref_button, 1, 0,
      'N', 'N', 'N', 'Y', 'N', 300,
      'N', 'N', 'N',
      v_element_id, v_process_id, 'Y', 'Y',
      'N', 'Y', 'N', 0,
      'B', 'N', 'N', 'N', 'N',
      v_uu
    );
  ELSE
    UPDATE ad_column SET
      name = 'Refresh Compliance',
      ad_reference_id = v_ref_button,
      fieldlength = 1,
      isupdateable = 'Y',
      isalwaysupdateable = 'Y',
      ad_element_id = v_element_id,
      ad_process_id = v_process_id,
      issyncdatabase = 'Y',
      istoolbarbutton = 'B',
      seqno = 300,
      entitytype = 'Ab_ERP',
      isactive = 'Y',
      updated = NOW(),
      updatedby = 100,
      ad_column_uu = COALESCE(ad_column_uu, v_uu)
    WHERE ad_column_id = v_col_id;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 4. Field on Organisation Audit tab
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_uu CONSTANT TEXT := '23a02343-c0d4-4f01-8e15-000000000001';
  v_tab_id INTEGER;
  v_col_id INTEGER;
  v_field_id INTEGER;
  v_seq INTEGER;
BEGIN
  SELECT t.ad_tab_id INTO v_tab_id
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE (t.ad_tab_uu = '23a02310-c0d4-4f01-8e15-000000000001'
         OR (w.ad_window_uu = '23a02305-c0d4-4f01-8e15-000000000001'
             AND t.name = 'Organisation Audit')
         OR (w.name = 'NDIS Audit Tool' AND t.name = 'Organisation Audit'))
    AND t.isactive = 'Y'
  LIMIT 1;
  IF v_tab_id IS NULL THEN
    RAISE EXCEPTION 'SAW023: Organisation Audit tab missing';
  END IF;

  SELECT c.ad_column_id INTO v_col_id
  FROM ad_column c
  JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
  WHERE tb.tablename = 'AbERP_ComplianceDashboard'
    AND (c.ad_column_uu = '23a02342-c0d4-4f01-8e15-000000000001'
         OR c.columnname = 'AbERP_RefreshCompliance')
  LIMIT 1;
  IF v_col_id IS NULL THEN
    RAISE EXCEPTION 'SAW023: AbERP_RefreshCompliance column missing';
  END IF;

  SELECT COALESCE(MAX(seqno), 0) + 10 INTO v_seq FROM ad_field WHERE ad_tab_id = v_tab_id;

  SELECT ad_field_id INTO v_field_id FROM ad_field WHERE ad_field_uu = v_uu;
  IF v_field_id IS NULL THEN
    SELECT ad_field_id INTO v_field_id
    FROM ad_field
    WHERE ad_tab_id = v_tab_id AND ad_column_id = v_col_id
    LIMIT 1;
  END IF;

  IF v_field_id IS NULL THEN
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, iscentrallymaintained,
      ad_tab_id, ad_column_id,
      isdisplayed, displaylength, isreadonly, seqno,
      issameline, isheading, isfieldonly, isencrypted, entitytype,
      isdisplayedgrid, xposition, numlines, columnspan,
      isquickentry, istoolbarbutton, ad_field_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Refresh Compliance',
      'Re-evaluate compliance rules and refresh organisation audit scores',
      'Runs the Refresh Compliance process for the current organisation audit row.',
      'N',
      v_tab_id, v_col_id,
      'Y', 1, 'N', v_seq,
      'N', 'N', 'N', 'N', 'Ab_ERP',
      'N', 5, 1, 2,
      'N', 'B', v_uu
    );
  ELSE
    UPDATE ad_field SET
      name = 'Refresh Compliance',
      isdisplayed = 'Y',
      isreadonly = 'N',
      isdisplayedgrid = 'N',
      istoolbarbutton = 'B',
      entitytype = 'Ab_ERP',
      isactive = 'Y',
      updated = NOW(),
      updatedby = 100,
      ad_field_uu = COALESCE(ad_field_uu, v_uu)
    WHERE ad_field_id = v_field_id;
  END IF;

  -- VIEW uses stable Created/Updated timestamps; tab can be non-RO so the form button enables.
  -- KPI columns remain non-updateable at column level.
  UPDATE ad_tab SET
    isreadonly = 'N',
    updated = NOW()
  WHERE ad_tab_id = v_tab_id;
END $$;

-- ---------------------------------------------------------------------------
-- 5. Process access — Admin + AbilityERP Admin + System Administrator
-- ---------------------------------------------------------------------------
INSERT INTO ad_process_access (
  ad_process_id, ad_role_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby, isreadwrite, ad_process_access_uu
)
SELECT p.ad_process_id, r.ad_role_id, r.ad_client_id, 0, 'Y',
  NOW(), 100, NOW(), 100, 'Y', NULL
FROM ad_process p
CROSS JOIN ad_role r
WHERE (p.ad_process_uu = '23a02340-c0d4-4f01-8e15-000000000001'
       OR p.value = 'AbERP_Compliance_Refresh')
  AND r.name IN ('Admin', 'AbilityERP Admin', 'System Administrator')
  AND r.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_process_access x
    WHERE x.ad_process_id = p.ad_process_id
      AND x.ad_role_id = r.ad_role_id
      AND x.ad_client_id = r.ad_client_id
  );

UPDATE ad_process_access wa SET
  isactive = 'Y',
  isreadwrite = 'Y',
  updated = NOW()
FROM ad_process p, ad_role r
WHERE wa.ad_process_id = p.ad_process_id
  AND wa.ad_role_id = r.ad_role_id
  AND wa.ad_client_id = r.ad_client_id
  AND (p.ad_process_uu = '23a02340-c0d4-4f01-8e15-000000000001'
       OR p.value = 'AbERP_Compliance_Refresh')
  AND r.name IN ('Admin', 'AbilityERP Admin', 'System Administrator');

-- ---------------------------------------------------------------------------
-- 6. Verify
-- ---------------------------------------------------------------------------
SELECT 'process' AS obj, p.value, p.classname, p.ad_process_uu
FROM ad_process p
WHERE p.value = 'AbERP_Compliance_Refresh'
UNION ALL
SELECT 'column', c.columnname, c.istoolbarbutton, c.ad_column_uu
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'AbERP_ComplianceDashboard' AND c.columnname = 'AbERP_RefreshCompliance'
UNION ALL
SELECT 'field', f.name, f.istoolbarbutton, f.ad_field_uu
FROM ad_field f
WHERE f.ad_field_uu = '23a02343-c0d4-4f01-8e15-000000000001'
   OR f.name = 'Refresh Compliance'
UNION ALL
SELECT 'access', r.name, wa.isreadwrite, r.ad_client_id::text
FROM ad_process_access wa
JOIN ad_process p ON p.ad_process_id = wa.ad_process_id
JOIN ad_role r ON r.ad_role_id = wa.ad_role_id AND r.ad_client_id = wa.ad_client_id
WHERE p.value = 'AbERP_Compliance_Refresh'
ORDER BY 1, 2;
