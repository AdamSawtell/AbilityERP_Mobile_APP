-- =============================================================================
-- SAW015 — Copy Dates From on Skip Dates (portable AD install)
-- =============================================================================
-- Resolves window/table/tab/roles by UU or name. Never hardcodes AD_*_ID targets.
-- Safe to re-run (idempotent upserts by *_UU / Value / ColumnName).
--
-- Fixed AbERP-owned UUs:
--   Process     15a01501-c0d4-4f01-8e15-000000000001
--   Element     15a01502-c0d4-4f01-8e15-000000000002
--   Column      15a01503-c0d4-4f01-8e15-000000000003
--   Field       15a01504-c0d4-4f01-8e15-000000000004
--   ProcessPara 15a01505-c0d4-4f01-8e15-000000000005
--   ValRule     15a01506-c0d4-4f01-8e15-000000000006
-- =============================================================================

SET search_path TO adempiere;

-- Physical button column
ALTER TABLE aberp_skip_dates
  ADD COLUMN IF NOT EXISTS aberp_copydatesfrom character(1);

-- ---------------------------------------------------------------------------
-- 1. Validation rule — exclude current Skip Dates from source picker
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_uu CONSTANT TEXT := '15a01506-c0d4-4f01-8e15-000000000006';
  v_id INTEGER;
BEGIN
  SELECT ad_val_rule_id INTO v_id FROM ad_val_rule WHERE ad_val_rule_uu = v_uu;
  IF v_id IS NULL THEN
    SELECT ad_val_rule_id INTO v_id FROM ad_val_rule
    WHERE name = 'AbERP Skip Dates - Exclude Current' AND entitytype = 'Ab_ERP' LIMIT 1;
  END IF;

  IF v_id IS NULL THEN
    INSERT INTO ad_val_rule (
      ad_val_rule_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, type, code, entitytype, ad_val_rule_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Val_Rule' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP Skip Dates - Exclude Current',
      'Source picker excludes the Skip Dates record currently open',
      'S',
      'AbERP_Skip_Dates.AbERP_Skip_Dates_ID<>@AbERP_Skip_Dates_ID@',
      'Ab_ERP',
      v_uu
    );
  ELSE
    UPDATE ad_val_rule SET
      name = 'AbERP Skip Dates - Exclude Current',
      code = 'AbERP_Skip_Dates.AbERP_Skip_Dates_ID<>@AbERP_Skip_Dates_ID@',
      type = 'S',
      entitytype = 'Ab_ERP',
      isactive = 'Y',
      updated = NOW(),
      updatedby = 100,
      ad_val_rule_uu = COALESCE(ad_val_rule_uu, v_uu)
    WHERE ad_val_rule_id = v_id;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. Process
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_uu CONSTANT TEXT := '15a01501-c0d4-4f01-8e15-000000000001';
  v_id INTEGER;
  v_help TEXT :=
    'The copied records contain specific dates. Please review all copied dates and update the year or individual dates where required before using this Skip Dates record.';
BEGIN
  SELECT ad_process_id INTO v_id FROM ad_process WHERE ad_process_uu = v_uu;
  IF v_id IS NULL THEN
    SELECT ad_process_id INTO v_id FROM ad_process WHERE value = 'AbERP_SkipDates_CopyDatesFrom' LIMIT 1;
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
      'AbERP_SkipDates_CopyDatesFrom', 'Copy Dates From',
      'Copy date lines from an existing Skip Dates record into the current Skip Dates header.',
      v_help,
      '3', 'Ab_ERP',
      'N', 'N',
      'com.aberp.skipdates.copyfrom.CopyDatesFrom',
      'N', 'N', 'Y',
      'N', v_uu,
      'P', 'N'
    );
  ELSE
    UPDATE ad_process SET
      value = 'AbERP_SkipDates_CopyDatesFrom',
      name = 'Copy Dates From',
      description = 'Copy date lines from an existing Skip Dates record into the current Skip Dates header.',
      help = v_help,
      classname = 'com.aberp.skipdates.copyfrom.CopyDatesFrom',
      showhelp = 'Y',
      entitytype = 'Ab_ERP',
      isactive = 'Y',
      updated = NOW(),
      updatedby = 100,
      ad_process_uu = COALESCE(NULLIF(ad_process_uu, ''), v_uu)
    WHERE ad_process_id = v_id
      AND (ad_process_uu IS NULL OR ad_process_uu = '' OR ad_process_uu = v_uu
           OR value = 'AbERP_SkipDates_CopyDatesFrom');
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Process parameter — source Skip Dates (Search)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_uu CONSTANT TEXT := '15a01505-c0d4-4f01-8e15-000000000005';
  v_process_id INTEGER;
  v_para_id INTEGER;
  v_val_rule_id INTEGER;
  v_element_id INTEGER;
  v_ref_search INTEGER;
BEGIN
  SELECT ad_process_id INTO v_process_id
  FROM ad_process
  WHERE ad_process_uu = '15a01501-c0d4-4f01-8e15-000000000001'
     OR value = 'AbERP_SkipDates_CopyDatesFrom'
  LIMIT 1;
  IF v_process_id IS NULL THEN
    RAISE EXCEPTION 'SAW015: process AbERP_SkipDates_CopyDatesFrom missing';
  END IF;

  SELECT ad_val_rule_id INTO v_val_rule_id
  FROM ad_val_rule
  WHERE ad_val_rule_uu = '15a01506-c0d4-4f01-8e15-000000000006'
     OR name = 'AbERP Skip Dates - Exclude Current'
  LIMIT 1;

  SELECT ad_element_id INTO v_element_id
  FROM ad_element WHERE columnname = 'AbERP_Skip_Dates_ID' LIMIT 1;

  SELECT ad_reference_id INTO v_ref_search
  FROM ad_reference WHERE name = 'Search' AND isactive = 'Y' LIMIT 1;
  IF v_ref_search IS NULL THEN
    v_ref_search := 30;
  END IF;

  SELECT ad_process_para_id INTO v_para_id
  FROM ad_process_para WHERE ad_process_para_uu = v_uu;
  IF v_para_id IS NULL THEN
    SELECT ad_process_para_id INTO v_para_id
    FROM ad_process_para
    WHERE ad_process_id = v_process_id AND columnname = 'AbERP_Skip_Dates_ID'
    LIMIT 1;
  END IF;

  IF v_para_id IS NULL THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, seqno, ad_process_id,
      columnname, iscentrallymaintained,
      fieldlength, ismandatory, isrange,
      ad_reference_id, ad_val_rule_id, ad_element_id,
      entitytype, ad_process_para_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process_Para' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Copy From Skip Dates',
      'Existing Skip Dates header whose date lines will be copied',
      10, v_process_id,
      'AbERP_Skip_Dates_ID', 'Y',
      22, 'Y', 'N',
      v_ref_search, v_val_rule_id, v_element_id,
      'Ab_ERP', v_uu
    );
  ELSE
    UPDATE ad_process_para SET
      name = 'Copy From Skip Dates',
      description = 'Existing Skip Dates header whose date lines will be copied',
      seqno = 10,
      ad_process_id = v_process_id,
      columnname = 'AbERP_Skip_Dates_ID',
      ismandatory = 'Y',
      ad_reference_id = v_ref_search,
      ad_val_rule_id = v_val_rule_id,
      ad_element_id = v_element_id,
      entitytype = 'Ab_ERP',
      isactive = 'Y',
      updated = NOW(),
      updatedby = 100,
      ad_process_para_uu = COALESCE(ad_process_para_uu, v_uu)
    WHERE ad_process_para_id = v_para_id;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 4. Element
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_uu CONSTANT TEXT := '15a01502-c0d4-4f01-8e15-000000000002';
  v_id INTEGER;
BEGIN
  SELECT ad_element_id INTO v_id FROM ad_element WHERE ad_element_uu = v_uu;
  IF v_id IS NULL THEN
    SELECT ad_element_id INTO v_id FROM ad_element WHERE columnname = 'AbERP_CopyDatesFrom' LIMIT 1;
  END IF;

  IF v_id IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, description, help, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_CopyDatesFrom', 'Ab_ERP', 'Copy Dates From', 'Copy Dates From',
      'Copy date lines from another Skip Dates record',
      'The copied records contain specific dates. Please review all copied dates and update the year or individual dates where required before using this Skip Dates record.',
      v_uu
    );
  ELSE
    UPDATE ad_element SET
      columnname = 'AbERP_CopyDatesFrom',
      name = 'Copy Dates From',
      printname = 'Copy Dates From',
      entitytype = 'Ab_ERP',
      updated = NOW(),
      updatedby = 100,
      ad_element_uu = COALESCE(ad_element_uu, v_uu)
    WHERE ad_element_id = v_id;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 5. Column (Button → process) on AbERP_Skip_Dates
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_uu CONSTANT TEXT := '15a01503-c0d4-4f01-8e15-000000000003';
  v_table_id INTEGER;
  v_element_id INTEGER;
  v_process_id INTEGER;
  v_col_id INTEGER;
  v_ref_button INTEGER;
BEGIN
  SELECT ad_table_id INTO v_table_id
  FROM ad_table
  WHERE ad_table_uu = '88130ae9-2aac-4c86-9c98-f94b272af212'
     OR tablename = 'AbERP_Skip_Dates'
  LIMIT 1;
  IF v_table_id IS NULL THEN
    RAISE EXCEPTION 'SAW015: AbERP_Skip_Dates table missing';
  END IF;

  SELECT ad_element_id INTO v_element_id FROM ad_element WHERE columnname = 'AbERP_CopyDatesFrom' LIMIT 1;
  SELECT ad_process_id INTO v_process_id
  FROM ad_process
  WHERE ad_process_uu = '15a01501-c0d4-4f01-8e15-000000000001'
     OR value = 'AbERP_SkipDates_CopyDatesFrom'
  LIMIT 1;

  SELECT ad_reference_id INTO v_ref_button
  FROM ad_reference WHERE name = 'Button' AND isactive = 'Y' LIMIT 1;
  IF v_ref_button IS NULL THEN
    v_ref_button := 28;
  END IF;

  SELECT ad_column_id INTO v_col_id FROM ad_column WHERE ad_column_uu = v_uu;
  IF v_col_id IS NULL THEN
    SELECT ad_column_id INTO v_col_id
    FROM ad_column
    WHERE ad_table_id = v_table_id AND columnname = 'AbERP_CopyDatesFrom'
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
      'Copy Dates From', 'Ab_ERP', 'AbERP_CopyDatesFrom', v_table_id,
      v_ref_button, 1, 0,
      'N', 'N', 'N', 'Y', 'N', 0,
      'N', 'N', 'N',
      v_element_id, v_process_id, 'Y', 'N',
      'N', 'Y', 'N', 0,
      'B', 'N', 'N', 'N', 'N',
      v_uu
    );
  ELSE
    UPDATE ad_column SET
      name = 'Copy Dates From',
      ad_reference_id = v_ref_button,
      fieldlength = 1,
      isupdateable = 'Y',
      ad_element_id = v_element_id,
      ad_process_id = v_process_id,
      issyncdatabase = 'Y',
      istoolbarbutton = 'B',
      entitytype = 'Ab_ERP',
      isactive = 'Y',
      updated = NOW(),
      updatedby = 100,
      ad_column_uu = COALESCE(ad_column_uu, v_uu)
    WHERE ad_column_id = v_col_id;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 6. Field on Skip Dates header tab
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_uu CONSTANT TEXT := '15a01504-c0d4-4f01-8e15-000000000004';
  v_tab_id INTEGER;
  v_col_id INTEGER;
  v_field_id INTEGER;
  v_seq INTEGER;
BEGIN
  SELECT t.ad_tab_id INTO v_tab_id
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
  WHERE (t.ad_tab_uu = '4224ab0d-fa68-44ac-9371-eb5fd100c3b3'
         OR (w.name = 'Skip Dates' AND t.name = 'Skip Dates'))
    AND tb.tablename = 'AbERP_Skip_Dates'
    AND t.isactive = 'Y'
  LIMIT 1;
  IF v_tab_id IS NULL THEN
    RAISE EXCEPTION 'SAW015: Skip Dates header tab missing';
  END IF;

  SELECT c.ad_column_id INTO v_col_id
  FROM ad_column c
  JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
  WHERE tb.tablename = 'AbERP_Skip_Dates'
    AND (c.ad_column_uu = '15a01503-c0d4-4f01-8e15-000000000003'
         OR c.columnname = 'AbERP_CopyDatesFrom')
  LIMIT 1;

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
      'Copy Dates From',
      'Copy date lines from another Skip Dates record',
      'The copied records contain specific dates. Please review all copied dates and update the year or individual dates where required before using this Skip Dates record.',
      'N',
      v_tab_id, v_col_id,
      'Y', 1, 'N', v_seq,
      'N', 'N', 'N', 'N', 'Ab_ERP',
      'N', 5, 1, 2,
      'N', 'B', v_uu
    );
  ELSE
    UPDATE ad_field SET
      name = 'Copy Dates From',
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
END $$;

-- ---------------------------------------------------------------------------
-- 7. Process access — AbilityERP Admin + Admin (+ System Administrator)
-- ---------------------------------------------------------------------------
INSERT INTO ad_process_access (
  ad_process_id, ad_role_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby, isreadwrite, ad_process_access_uu
)
SELECT p.ad_process_id, roles.ad_role_id, roles.ad_client_id, 0, 'Y',
  NOW(), 100, NOW(), 100, 'Y',
  (
    substring(md5('SAW015-pa-' || p.ad_process_id::text || '-' || roles.ad_role_id::text || '-' || roles.ad_client_id::text), 1, 8) || '-' ||
    substring(md5('SAW015-pa-' || p.ad_process_id::text || '-' || roles.ad_role_id::text || '-' || roles.ad_client_id::text), 9, 4) || '-4a15-8e15-' ||
    substring(md5('SAW015-pa-tail-' || roles.ad_role_id::text || '-' || roles.ad_client_id::text), 1, 12)
  )
FROM ad_process p
CROSS JOIN (
  SELECT ad_role_id, ad_client_id FROM ad_role
  WHERE name IN ('AbilityERP Admin', 'Admin') AND isactive = 'Y'
  UNION ALL
  SELECT 0, 0
) AS roles(ad_role_id, ad_client_id)
WHERE (p.ad_process_uu = '15a01501-c0d4-4f01-8e15-000000000001'
       OR p.value = 'AbERP_SkipDates_CopyDatesFrom')
  AND NOT EXISTS (
    SELECT 1 FROM ad_process_access x
    WHERE x.ad_process_id = p.ad_process_id
      AND x.ad_role_id = roles.ad_role_id
      AND x.ad_client_id = roles.ad_client_id
  );

-- ---------------------------------------------------------------------------
-- 8. Verify summary
-- ---------------------------------------------------------------------------
SELECT 'process' AS obj, p.ad_process_id::text AS id, p.value, p.classname, p.ad_process_uu
FROM ad_process p
WHERE p.value = 'AbERP_SkipDates_CopyDatesFrom'
UNION ALL
SELECT 'column', c.ad_column_id::text, c.columnname, c.istoolbarbutton, c.ad_column_uu
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'AbERP_Skip_Dates' AND c.columnname = 'AbERP_CopyDatesFrom'
UNION ALL
SELECT 'field', f.ad_field_id::text, f.name, f.istoolbarbutton, f.ad_field_uu
FROM ad_field f
WHERE f.ad_field_uu = '15a01504-c0d4-4f01-8e15-000000000004'
   OR f.name = 'Copy Dates From';
