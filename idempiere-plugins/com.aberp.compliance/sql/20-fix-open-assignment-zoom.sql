-- =============================================================================
-- SAW024 — Fix Open Assignment zoom (display + window) under Employee > Open Findings
-- Name is blank on Credential Assignment; use Value + set AD_Window_ID for zoom.
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_ref_id INTEGER;
  v_cred_table INTEGER;
  v_key_col INTEGER;
  v_disp_col INTEGER;
  v_cred_window INTEGER;
  v_result_table INTEGER;
  v_find_tab INTEGER;
BEGIN
  SELECT ad_table_id INTO v_cred_table FROM ad_table WHERE tablename = 'AbERP_CredentialAssignment';
  SELECT ad_table_id INTO v_result_table FROM ad_table WHERE tablename = 'AbERP_ComplianceResult';
  SELECT ad_column_id INTO v_key_col FROM ad_column
  WHERE ad_table_id = v_cred_table AND columnname = 'AbERP_CredentialAssignment_ID';
  -- Name is often blank on HCO; Value is populated
  SELECT ad_column_id INTO v_disp_col FROM ad_column
  WHERE ad_table_id = v_cred_table AND columnname = 'Value';
  IF v_disp_col IS NULL THEN
    SELECT ad_column_id INTO v_disp_col FROM ad_column
    WHERE ad_table_id = v_cred_table AND columnname = 'Name';
  END IF;

  SELECT ad_window_id INTO v_cred_window
  FROM ad_window
  WHERE ad_window_uu = 'f974f00f-5cd3-4a5f-973e-0347aacc59df'
     OR name = 'Credential Assignment'
  LIMIT 1;

  SELECT ad_reference_id INTO v_ref_id
  FROM ad_reference
  WHERE ad_reference_uu = '24a02420-c0d4-4f01-8e15-000000000001'
     OR name = 'AbERP_CredentialAssignment'
  LIMIT 1;

  SELECT ad_tab_id INTO v_find_tab FROM ad_tab WHERE ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001';

  IF v_cred_table IS NULL OR v_key_col IS NULL OR v_disp_col IS NULL OR v_ref_id IS NULL THEN
    RAISE EXCEPTION 'SAW024-20: Open Assignment reference prerequisites missing';
  END IF;
  IF v_cred_window IS NULL THEN
    RAISE EXCEPTION 'SAW024-20: Credential Assignment window missing — cannot wire zoom';
  END IF;

  UPDATE ad_ref_table SET
    ad_table_id = v_cred_table,
    ad_key = v_key_col,
    ad_display = v_disp_col,
    ad_window_id = v_cred_window,
    isvaluedisplayed = 'Y',
    isdisplayidentifier = 'Y',
    displaysql = NULL,
    updated = NOW()
  WHERE ad_reference_id = v_ref_id;

  UPDATE ad_column SET
    columnsql = 'AbERP_ComplianceResult.Record_ID',
    ad_reference_id = 18,
    ad_reference_value_id = v_ref_id,
    isupdateable = 'N',
    updated = NOW()
  WHERE ad_table_id = v_result_table
    AND columnname = 'AbERP_OpenAssignment_ID';

  -- Prefer Open Assignment in grid; keep Open & Fix first
  UPDATE ad_field SET
    isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    isreadonly = 'Y',
    seqno = 85,
    seqnogrid = 85,
    name = 'Open Assignment',
    help = 'Click the zoom icon (or the value) to open Credential Assignment, renew/update expiry, then run Refresh Compliance.',
    updated = NOW()
  WHERE ad_tab_id = v_find_tab
    AND ad_column_id = (
      SELECT ad_column_id FROM ad_column
      WHERE ad_table_id = v_result_table AND columnname = 'AbERP_OpenAssignment_ID'
    );

  -- Ensure table default window stays Credential Assignment
  UPDATE ad_table SET
    ad_window_id = v_cred_window,
    updated = NOW()
  WHERE ad_table_id = v_cred_table
    AND (ad_window_id IS NULL OR ad_window_id <> v_cred_window);

  RAISE NOTICE 'SAW024-20 Open Assignment zoom wired ref=% window=% displayCol=%',
    v_ref_id, v_cred_window, v_disp_col;
END $$;

SELECT rt.ad_reference_id, t.tablename, kc.columnname AS key_col, dc.columnname AS display_col,
       w.name AS zoom_window, rt.isvaluedisplayed
FROM ad_ref_table rt
JOIN ad_table t ON t.ad_table_id = rt.ad_table_id
JOIN ad_column kc ON kc.ad_column_id = rt.ad_key
JOIN ad_column dc ON dc.ad_column_id = rt.ad_display
LEFT JOIN ad_window w ON w.ad_window_id = rt.ad_window_id
WHERE rt.ad_reference_id = (
  SELECT ad_reference_id FROM ad_reference
  WHERE ad_reference_uu = '24a02420-c0d4-4f01-8e15-000000000001'
     OR name = 'AbERP_CredentialAssignment'
  LIMIT 1
);

SELECT c.columnname, c.columnsql, c.ad_reference_value_id
FROM ad_column c
WHERE c.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_ComplianceResult')
  AND c.columnname = 'AbERP_OpenAssignment_ID';
