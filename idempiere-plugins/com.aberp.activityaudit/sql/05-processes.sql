-- =============================================================================
-- SAW027 — Processes + button on Review
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_process_id),0)+1 FROM ad_process))
WHERE name='AD_Process' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_process_para_id),0)+1 FROM ad_process_para))
WHERE name='AD_Process_Para' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw027_process(
  p_uu TEXT, p_value TEXT, p_name TEXT, p_classname TEXT, p_server CHAR DEFAULT 'N'
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
      p_value, p_name, p_name, NULL,
      '3', 'Ab_ERP', 'N', 'N',
      p_classname, 0, 0,
      'N', p_server, 'Y', p_uu
    ) RETURNING ad_process_id INTO v_id;
  ELSE
    UPDATE ad_process SET
      name = p_name, value = p_value, classname = p_classname,
      isserverprocess = p_server, entitytype = 'Ab_ERP',
      ad_process_uu = COALESCE(ad_process_uu, p_uu), isactive = 'Y', updated = NOW()
    WHERE ad_process_id = v_id;
  END IF;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw027_para(
  p_process_id INTEGER, p_uu TEXT, p_name TEXT, p_columnname TEXT,
  p_seq INTEGER, p_ref INTEGER, p_ref_value INTEGER,
  p_mandatory CHAR DEFAULT 'N', p_default TEXT DEFAULT NULL
) RETURNS void AS $$
DECLARE
  v_id INTEGER;
  v_el INTEGER;
BEGIN
  SELECT ad_element_id INTO v_el FROM ad_element WHERE columnname = p_columnname LIMIT 1;
  IF v_el IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_columnname, 'Ab_ERP', p_name, p_name,
      '27a027e1-0000-4000-8000-' || lpad(substr(md5(p_columnname), 1, 12), 12, '0')
    ) RETURNING ad_element_id INTO v_el;
  END IF;

  SELECT ad_process_para_id INTO v_id FROM ad_process_para WHERE ad_process_para_uu = p_uu;
  IF v_id IS NULL THEN
    SELECT ad_process_para_id INTO v_id FROM ad_process_para
    WHERE ad_process_id = p_process_id AND columnname = p_columnname;
  END IF;
  IF v_id IS NULL THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_process_id, seqno,
      ad_reference_id, ad_reference_value_id, ad_val_rule_id,
      columnname, iscentrallymaintained, fieldlength, ismandatory,
      isrange, defaultvalue, entitytype, ad_element_id, ad_process_para_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process_Para' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, p_name, p_process_id, p_seq,
      p_ref, p_ref_value, NULL,
      p_columnname, 'Y', 0, p_mandatory,
      'N', p_default, 'Ab_ERP', v_el, p_uu
    );
  ELSE
    UPDATE ad_process_para SET
      name = p_name, seqno = p_seq, ad_reference_id = p_ref,
      ad_reference_value_id = p_ref_value, ismandatory = p_mandatory,
      defaultvalue = COALESCE(p_default, defaultvalue),
      ad_process_para_uu = COALESCE(ad_process_para_uu, p_uu), updated = NOW()
    WHERE ad_process_para_id = v_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_nightly INTEGER;
  v_hist INTEGER;
  v_open INTEGER;
  v_cat INTEGER;
  v_tab INTEGER;
  v_col INTEGER;
  v_field INTEGER;
BEGIN
  SELECT ad_reference_id INTO v_cat FROM ad_reference
  WHERE ad_reference_uu = '27a02722-c0d4-4f01-8e15-000000000001' OR name = 'AbERP_ActivityAudit_Category' LIMIT 1;

  v_nightly := pg_temp.saw027_process(
    '27a02770-c0d4-4f01-8e15-000000000001',
    'AbERP_ActivityAudit_Nightly',
    'Activity Audit Nightly',
    'com.aberp.activityaudit.process.ActivityAuditNightly', 'Y');

  v_hist := pg_temp.saw027_process(
    '27a02771-c0d4-4f01-8e15-000000000001',
    'AbERP_ActivityAudit_Historical',
    'Historical Activity Audit',
    'com.aberp.activityaudit.process.ActivityAuditHistorical', 'N');

  PERFORM pg_temp.saw027_para(v_hist, '27a02771-p001-4f01-8e15-000000000001', 'Start Date', 'DateFrom', 10, 15, NULL, 'Y');
  PERFORM pg_temp.saw027_para(v_hist, '27a02771-p002-4f01-8e15-000000000001', 'End Date', 'DateTo', 20, 15, NULL, 'Y');
  PERFORM pg_temp.saw027_para(v_hist, '27a02771-p003-4f01-8e15-000000000001', 'Organisation', 'AD_Org_ID', 30, 19, NULL, 'N');
  PERFORM pg_temp.saw027_para(v_hist, '27a02771-p004-4f01-8e15-000000000001', 'Activity Type', 'ContactActivityType', 40, 10, NULL, 'N');
  PERFORM pg_temp.saw027_para(v_hist, '27a02771-p005-4f01-8e15-000000000001', 'Audit Category', 'Category', 50, 17, v_cat, 'N');
  PERFORM pg_temp.saw027_para(v_hist, '27a02771-p006-4f01-8e15-000000000001', 'Include Previously Processed', 'IncludePreviouslyProcessed', 60, 20, NULL, 'N', 'N');
  PERFORM pg_temp.saw027_para(v_hist, '27a02771-p007-4f01-8e15-000000000001', 'Only Check Newly Added Terms', 'OnlyNewTerms', 70, 20, NULL, 'N', 'N');
  PERFORM pg_temp.saw027_para(v_hist, '27a02771-p008-4f01-8e15-000000000001', 'Reopen Existing Reviews', 'ReopenExistingReviews', 80, 20, NULL, 'N', 'Y');

  v_open := pg_temp.saw027_process(
    '27a02772-c0d4-4f01-8e15-000000000001',
    'AbERP_ActivityAudit_OpenActivity',
    'Open Activity',
    'com.aberp.activityaudit.process.OpenActivity', 'N');

  -- Button field on Review tab
  SELECT ad_tab_id INTO v_tab FROM ad_tab WHERE ad_tab_uu = '27a02751-c0d4-4f01-8e15-000000000001';
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'SAW027: Review tab missing — run 04 first';
  END IF;

  -- Physical Open Activity button (SAW024 pattern) — also applied by 12-open-activity-button.sql
  ALTER TABLE aberp_activityauditreview
    ADD COLUMN IF NOT EXISTS aberp_openactivity character(1) DEFAULT NULL;
  ALTER TABLE aberp_activityauditreview
    ADD COLUMN IF NOT EXISTS processing character(1) NOT NULL DEFAULT 'N';

  -- Ensure a button column exists on review table (process button via AD_Column.AD_Process_ID)
  SELECT ad_column_id INTO v_col FROM ad_column
  WHERE ad_table_id = (SELECT ad_table_id FROM ad_tab WHERE ad_tab_id = v_tab)
    AND columnname = 'AbERP_OpenActivity';
  IF v_col IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, version, entitytype, columnname, ad_table_id,
      ad_reference_id, fieldlength, iskey, isparent, ismandatory, isupdateable,
      isidentifier, seqno, istranslated, isencrypted, isselectioncolumn,
      ad_element_id, issyncdatabase, isalwaysupdateable, isallowcopy,
      ad_process_id, ad_column_uu
    )
    SELECT
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Open Activity', 0, 'Ab_ERP', 'AbERP_OpenActivity', t.ad_table_id,
      28, 1, 'N', 'N', 'N', 'Y',
      'N', 5, 'N', 'N', 'N',
      (SELECT ad_element_id FROM ad_element WHERE columnname = 'AbERP_OpenActivity' LIMIT 1),
      'N', 'Y', 'N',
      v_open, '27a02704-c027-4f01-8e15-000000000001'
    FROM ad_table t WHERE t.tablename = 'AbERP_ActivityAuditReview'
    RETURNING ad_column_id INTO v_col;
  ELSE
    UPDATE ad_column SET ad_process_id = v_open, ad_reference_id = 28,
      columnsql = NULL, isupdateable = 'Y', isalwaysupdateable = 'Y', updated = NOW()
    WHERE ad_column_id = v_col;
  END IF;

  SELECT ad_field_id INTO v_field FROM ad_field WHERE ad_field_uu = '27a02751-f019-4f01-8e15-000000000001';
  IF v_field IS NULL THEN
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, iscentrallymaintained, ad_tab_id, ad_column_id,
      isdisplayed, displaylength, isreadonly, seqno, issameline,
      isheading, isfieldonly, isencrypted, entitytype,
      isdisplayedgrid, seqnogrid, xposition, columnspan, numlines, ad_field_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Open Activity', 'N', v_tab, v_col,
      'Y', 0, 'N', 15, 'Y',
      'N', 'N', 'N', 'Ab_ERP',
      'Y', 15, 4, 2, 1, '27a02751-f019-4f01-8e15-000000000001'
    );
  END IF;

  -- Process access
  INSERT INTO ad_process_access (
    ad_process_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, isreadwrite
  )
  SELECT p.ad_process_id, r.ad_role_id, r.ad_client_id, 0, 'Y',
         NOW(), 100, NOW(), 100, 'Y'
  FROM ad_role r
  CROSS JOIN (VALUES (v_nightly), (v_hist), (v_open)) AS p(ad_process_id)
  WHERE r.name IN ('AbilityERP Admin', 'Admin', 'System Administrator')
    AND NOT EXISTS (
      SELECT 1 FROM ad_process_access x
      WHERE x.ad_process_id = p.ad_process_id AND x.ad_role_id = r.ad_role_id
    );

  RAISE NOTICE 'SAW027 processes ready';
END $$;
