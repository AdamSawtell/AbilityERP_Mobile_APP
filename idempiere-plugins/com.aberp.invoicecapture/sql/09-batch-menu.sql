-- =============================================================================
-- SAW019 — Menu entry to run batch on demand (same process as nightly)
-- Menu UU: 19a0190e-c0d4-4f01-8e15-000000000001
-- Also move scheduler to System client (0) so server processor picks it up.
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_menu_id),0)+1 FROM ad_menu))
WHERE name='AD_Menu' AND istableid='Y';

DO $$
DECLARE
  v_proc INTEGER;
  v_menu INTEGER;
  v_seq INTEGER;
BEGIN
  SELECT ad_process_id INTO v_proc
  FROM ad_process
  WHERE ad_process_uu = '19a01909-c0d4-4f01-8e15-000000000001'
     OR value = 'AbERP_InvoiceCapture_ProcessBatch'
  LIMIT 1;
  IF v_proc IS NULL THEN
    RAISE EXCEPTION 'SAW019: batch process missing';
  END IF;

  SELECT ad_menu_id INTO v_menu FROM ad_menu WHERE ad_menu_uu = '19a0190e-c0d4-4f01-8e15-000000000001';
  IF v_menu IS NULL THEN
    SELECT ad_menu_id INTO v_menu FROM ad_menu WHERE name = 'Process Invoice Capture Batch' AND ad_process_id = v_proc;
  END IF;

  IF v_menu IS NULL THEN
    INSERT INTO ad_menu (
      ad_menu_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, issummary, issotrx, isreadonly,
      action, ad_process_id, entitytype, ad_menu_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Menu' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Process Invoice Capture Batch',
      'Run Invoice Capture batch now (same shared service as Process Selected Invoice)',
      'N', 'N', 'N',
      'P', v_proc, 'Ab_ERP', '19a0190e-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_menu_id INTO v_menu;
  END IF;

  SELECT COALESCE(MAX(seqno),0)+10 INTO v_seq FROM ad_treenodemm WHERE parent_id = -1 AND ad_tree_id = 10;
  IF NOT EXISTS (SELECT 1 FROM ad_treenodemm WHERE node_id = v_menu AND ad_tree_id = 10) THEN
    INSERT INTO ad_treenodemm (
      ad_tree_id, node_id, parent_id, seqno, ad_client_id, ad_org_id,
      created, createdby, updated, updatedby, isactive
    ) VALUES (10, v_menu, -1, v_seq, 0, 0, NOW(), 100, NOW(), 100, 'Y');
  END IF;

  -- Server processor typically executes System-client schedulers
  UPDATE ad_scheduler SET
    ad_client_id = 0,
    supervisor_id = 100,
    datenextrun = NOW() - INTERVAL '1 minute',
    updated = NOW()
  WHERE ad_scheduler_uu = '19a0190a-c0d4-4f01-8e15-000000000001'
     OR name = 'Invoice Capture Nightly Batch';

  RAISE NOTICE 'SAW019 batch menu=%', v_menu;
END $$;
