-- =============================================================================
-- SAW024 — Zoomable Source Record on Open Findings (field-level Table override)
-- Open Assignment physical/virtual ColumnSQL stayed -1 in WebUI; Record_ID works.
-- Override AD_Field reference on Open Findings only → Credential Assignment zoom.
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_find_tab INTEGER;
  v_ref_id INTEGER;
  v_cred_window INTEGER;
  v_record_field INTEGER;
  v_oa_field INTEGER;
BEGIN
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

  IF v_find_tab IS NULL OR v_ref_id IS NULL THEN
    RAISE EXCEPTION 'SAW024-23: Open Findings tab or Credential Assignment reference missing';
  END IF;

  -- Ensure ref table has zoom window + Value display
  UPDATE ad_ref_table SET
    ad_window_id = COALESCE(v_cred_window, ad_window_id),
    isvaluedisplayed = 'Y',
    isdisplayidentifier = 'Y',
    ad_display = COALESCE(
      (SELECT ad_column_id FROM ad_column c
       JOIN ad_table t ON t.ad_table_id = c.ad_table_id
       WHERE t.tablename = 'AbERP_CredentialAssignment' AND c.columnname = 'Value'),
      ad_display
    ),
    updated = NOW()
  WHERE ad_reference_id = v_ref_id;

  SELECT ad_field_id INTO v_record_field
  FROM ad_field
  WHERE ad_tab_id = v_find_tab
    AND ad_column_id = (
      SELECT ad_column_id FROM ad_column
      WHERE ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_ComplianceResult')
        AND columnname = 'Record_ID'
    );

  IF v_record_field IS NULL THEN
    RAISE EXCEPTION 'SAW024-23: Source Record field missing on Open Findings';
  END IF;

  -- Field-level override: Integer Record_ID → Table lookup to Credential Assignment
  UPDATE ad_field SET
    name = 'Open Assignment',
    description = 'Credential Assignment to open and fix',
    help = 'Click Zoom (field menu) to open the Credential Assignment, renew/update expiry, then Refresh Compliance.',
    ad_reference_id = 18,
    ad_reference_value_id = v_ref_id,
    isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    isreadonly = 'Y',
    seqno = 85,
    seqnogrid = 85,
    displaylength = 20,
    updated = NOW()
  WHERE ad_field_id = v_record_field;

  -- Hide the broken AbERP_OpenAssignment_ID field (kept for engine backfill / future)
  SELECT ad_field_id INTO v_oa_field
  FROM ad_field
  WHERE ad_tab_id = v_find_tab
    AND ad_column_id = (
      SELECT ad_column_id FROM ad_column
      WHERE ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_ComplianceResult')
        AND columnname = 'AbERP_OpenAssignment_ID'
    );

  IF v_oa_field IS NOT NULL THEN
    UPDATE ad_field SET
      isdisplayed = 'N',
      isdisplayedgrid = 'N',
      name = 'Open Assignment (internal)',
      updated = NOW()
    WHERE ad_field_id = v_oa_field;
  END IF;

  -- Hide raw Source Table in grid (still in form for support)
  UPDATE ad_field SET
    isdisplayedgrid = 'N',
    updated = NOW()
  WHERE ad_tab_id = v_find_tab
    AND ad_column_id = (
      SELECT ad_column_id FROM ad_column
      WHERE ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_ComplianceResult')
        AND columnname = 'AD_Table_ID'
    );

  RAISE NOTICE 'SAW024-23 Open Findings Source Record field=% → Table ref=% (Credential Assignment zoom)',
    v_record_field, v_ref_id;
END $$;

SELECT f.name, f.isdisplayed, f.isdisplayedgrid, f.seqnogrid,
       f.ad_reference_id, f.ad_reference_value_id, c.columnname, c.ad_reference_id AS col_ref
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE f.ad_tab_id = (SELECT ad_tab_id FROM ad_tab WHERE ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001')
  AND c.columnname IN ('Record_ID', 'AbERP_OpenAssignment_ID', 'AD_Table_ID', 'AbERP_OpenSource')
ORDER BY f.seqnogrid NULLS LAST;
