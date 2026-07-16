-- =============================================================================
-- SAW024 — Physical Open Assignment FK (virtual ColumnSQL returned -1 in WebUI)
-- =============================================================================
SET search_path TO adempiere;

ALTER TABLE aberp_complianceresult
  ADD COLUMN IF NOT EXISTS aberp_openassignment_id NUMERIC(10);

UPDATE aberp_complianceresult r
SET aberp_openassignment_id = r.record_id
WHERE r.ad_table_id = (
        SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_CredentialAssignment' LIMIT 1
      )
  AND r.record_id IS NOT NULL
  AND r.record_id > 0
  AND (r.aberp_openassignment_id IS DISTINCT FROM r.record_id);

DO $$
DECLARE
  v_result_table INTEGER;
  v_cred_table INTEGER;
  v_ref_id INTEGER;
  v_cred_window INTEGER;
  v_col_id INTEGER;
  v_find_tab INTEGER;
  v_key_col INTEGER;
  v_disp_col INTEGER;
BEGIN
  SELECT ad_table_id INTO v_result_table FROM ad_table WHERE tablename = 'AbERP_ComplianceResult';
  SELECT ad_table_id INTO v_cred_table FROM ad_table WHERE tablename = 'AbERP_CredentialAssignment';
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
  SELECT ad_column_id INTO v_key_col FROM ad_column
  WHERE ad_table_id = v_cred_table AND columnname = 'AbERP_CredentialAssignment_ID';
  SELECT ad_column_id INTO v_disp_col FROM ad_column
  WHERE ad_table_id = v_cred_table AND columnname = 'Value';
  IF v_disp_col IS NULL THEN
    SELECT ad_column_id INTO v_disp_col FROM ad_column
    WHERE ad_table_id = v_cred_table AND columnname = 'Name';
  END IF;
  SELECT ad_tab_id INTO v_find_tab FROM ad_tab WHERE ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001';

  IF v_result_table IS NULL OR v_cred_table IS NULL OR v_ref_id IS NULL OR v_cred_window IS NULL THEN
    RAISE EXCEPTION 'SAW024-21: Open Assignment physical FK prerequisites missing';
  END IF;

  UPDATE ad_ref_table SET
    ad_table_id = v_cred_table,
    ad_key = v_key_col,
    ad_display = v_disp_col,
    ad_window_id = v_cred_window,
    isvaluedisplayed = 'Y',
    isdisplayidentifier = 'Y',
    updated = NOW()
  WHERE ad_reference_id = v_ref_id;

  SELECT ad_column_id INTO v_col_id
  FROM ad_column
  WHERE ad_table_id = v_result_table AND columnname = 'AbERP_OpenAssignment_ID'
  LIMIT 1;

  IF v_col_id IS NULL THEN
    RAISE EXCEPTION 'SAW024-21: AbERP_OpenAssignment_ID column missing — run 18 first';
  END IF;

  -- Convert virtual → physical Table reference
  UPDATE ad_column SET
    columnsql = NULL,
    ad_reference_id = 18,
    ad_reference_value_id = v_ref_id,
    fieldlength = 10,
    isupdateable = 'N',
    ismandatory = 'N',
    issyncdatabase = 'Y',
    isalwaysupdateable = 'N',
    entitytype = 'Ab_ERP',
    name = 'Open Assignment',
    description = 'Credential Assignment to open and fix',
    help = 'Zoom to open Credential Assignment, renew/update expiry, then Refresh Compliance.',
    updated = NOW()
  WHERE ad_column_id = v_col_id;

  UPDATE ad_field SET
    isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    isreadonly = 'Y',
    seqno = 85,
    seqnogrid = 85,
    name = 'Open Assignment',
    help = 'Click Zoom (field menu) or the lookup zoom icon to open Credential Assignment and take action.',
    updated = NOW()
  WHERE ad_tab_id = v_find_tab
    AND ad_column_id = v_col_id;

  RAISE NOTICE 'SAW024-21 physical Open Assignment col=% backfilled for Credential Assignment rows', v_col_id;
END $$;

SELECT COUNT(*) AS open_assignment_set,
       COUNT(*) FILTER (WHERE aberp_openassignment_id IS NULL) AS nulls
FROM aberp_complianceresult r
JOIN aberp_compliancerule ru ON ru.aberp_compliancerule_id = r.aberp_compliancerule_id
WHERE ru.compliancecategory = 'W' AND r.isresolved = 'N' AND r.isactive = 'Y';

SELECT c.columnname, c.columnsql, c.ad_reference_id, c.ad_reference_value_id, c.issyncdatabase
FROM ad_column c
WHERE c.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_ComplianceResult')
  AND c.columnname = 'AbERP_OpenAssignment_ID';
