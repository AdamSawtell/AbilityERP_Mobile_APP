-- =============================================================================
-- SAW024 — Zoom Across from Open Findings → Credential Assignment (Record_ID)
-- Physical Open Assignment still shows -1 in some sessions; Zoom Condition is reliable.
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_result_table INTEGER;
  v_cred_table INTEGER;
  v_cred_window INTEGER;
  v_zc_id INTEGER;
BEGIN
  SELECT ad_table_id INTO v_result_table FROM ad_table WHERE tablename = 'AbERP_ComplianceResult';
  SELECT ad_table_id INTO v_cred_table FROM ad_table WHERE tablename = 'AbERP_CredentialAssignment';
  SELECT ad_window_id INTO v_cred_window
  FROM ad_window
  WHERE ad_window_uu = 'f974f00f-5cd3-4a5f-973e-0347aacc59df'
     OR name = 'Credential Assignment'
  LIMIT 1;

  IF v_result_table IS NULL OR v_cred_table IS NULL OR v_cred_window IS NULL THEN
    RAISE EXCEPTION 'SAW024-22: Zoom Condition prerequisites missing';
  END IF;

  SELECT ad_zoomcondition_id INTO v_zc_id
  FROM ad_zoomcondition
  WHERE ad_zoomcondition_uu = '24a02440-c0d4-4f01-8e15-000000000001'
  LIMIT 1;

  IF v_zc_id IS NULL THEN
    SELECT ad_zoomcondition_id INTO v_zc_id
    FROM ad_zoomcondition
    WHERE ad_table_id = v_result_table
      AND ad_window_id = v_cred_window
      AND entitytype = 'Ab_ERP'
    LIMIT 1;
  END IF;

  IF v_zc_id IS NULL THEN
    INSERT INTO ad_zoomcondition (
      ad_zoomcondition_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      seqno, entitytype, ad_table_id, ad_window_id,
      whereclause, name, description, ad_zoomcondition_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_ZoomCondition' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      10, 'Ab_ERP', v_result_table, v_cred_window,
      'AbERP_CredentialAssignment_ID=(SELECT r.Record_ID FROM AbERP_ComplianceResult r WHERE r.AbERP_ComplianceResult_ID=@Record_ID@)',
      'Open Findings → Credential Assignment',
      'SAW024: Zoom Across from a finding to its Credential Assignment source',
      '24a02440-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_zoomcondition_id INTO v_zc_id;
  ELSE
    UPDATE ad_zoomcondition SET
      ad_table_id = v_result_table,
      ad_window_id = v_cred_window,
      whereclause = 'AbERP_CredentialAssignment_ID=(SELECT r.Record_ID FROM AbERP_ComplianceResult r WHERE r.AbERP_ComplianceResult_ID=@Record_ID@)',
      name = 'Open Findings → Credential Assignment',
      isactive = 'Y',
      entitytype = 'Ab_ERP',
      ad_zoomcondition_uu = COALESCE(ad_zoomcondition_uu, '24a02440-c0d4-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_zoomcondition_id = v_zc_id;
  END IF;

  -- Ensure sequences keep up
  UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_zoomcondition_id),0)+1 FROM ad_zoomcondition))
  WHERE name = 'AD_ZoomCondition' AND istableid = 'Y';

  RAISE NOTICE 'SAW024-22 ZoomCondition=% resultTable=% credWindow=%', v_zc_id, v_result_table, v_cred_window;
END $$;

SELECT z.ad_zoomcondition_id, z.name, z.whereclause, w.name AS window_name, t.tablename
FROM ad_zoomcondition z
JOIN ad_window w ON w.ad_window_id = z.ad_window_id
JOIN ad_table t ON t.ad_table_id = z.ad_table_id
WHERE z.ad_zoomcondition_uu = '24a02440-c0d4-4f01-8e15-000000000001';
