-- =============================================================================
-- SAW019 — Processes + bind Process Selected Invoice button
-- Selected UU: 19a01908-c0d4-4f01-8e15-000000000001
-- Batch UU:    19a01909-c0d4-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_process_id),0)+1 FROM ad_process))
WHERE name='AD_Process' AND istableid='Y';

DO $$
DECLARE
  v_sel_uu CONSTANT TEXT := '19a01908-c0d4-4f01-8e15-000000000001';
  v_bat_uu CONSTANT TEXT := '19a01909-c0d4-4f01-8e15-000000000001';
  v_sel_id INTEGER;
  v_bat_id INTEGER;
  v_table_id INTEGER;
  v_col_id INTEGER;
BEGIN
  -- Selected
  SELECT ad_process_id INTO v_sel_id FROM ad_process WHERE ad_process_uu = v_sel_uu;
  IF v_sel_id IS NULL THEN
    SELECT ad_process_id INTO v_sel_id FROM ad_process WHERE value = 'AbERP_InvoiceCapture_ProcessSelected' LIMIT 1;
  END IF;

  IF v_sel_id IS NULL THEN
    INSERT INTO ad_process (
      ad_process_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      value, name, description, help,
      accesslevel, entitytype, isreport, isdirectprint,
      classname, isbetafunctionality, isserverprocess, showhelp,
      copyfromprocess, ad_process_uu, allowmultipleexecution
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_InvoiceCapture_ProcessSelected', 'Process Selected Invoice',
      'Process the currently selected Invoice Capture record (OCR → match → Draft AP Invoice).',
      'Uses the same shared InvoiceCaptureService as the nightly batch. Requires a PDF attachment or valid File Path. Eligible statuses: Pending, Requires Review, Vendor Not Matched, Validation Failed, Processing Error, Possible Duplicate, PDF Unreadable. Successfully Processed records with a linked invoice are refused to prevent duplicates.',
      '3', 'Ab_ERP', 'N', 'N',
      'com.aberp.invoicecapture.process.ProcessSelectedInvoice',
      'N', 'N', 'Y',
      'N', v_sel_uu, 'P'
    ) RETURNING ad_process_id INTO v_sel_id;
  ELSE
    UPDATE ad_process SET
      value = 'AbERP_InvoiceCapture_ProcessSelected',
      name = 'Process Selected Invoice',
      classname = 'com.aberp.invoicecapture.process.ProcessSelectedInvoice',
      entitytype = 'Ab_ERP',
      isactive = 'Y',
      ad_process_uu = COALESCE(NULLIF(ad_process_uu, ''), v_sel_uu),
      updated = NOW()
    WHERE ad_process_id = v_sel_id;
  END IF;

  -- Batch
  SELECT ad_process_id INTO v_bat_id FROM ad_process WHERE ad_process_uu = v_bat_uu;
  IF v_bat_id IS NULL THEN
    SELECT ad_process_id INTO v_bat_id FROM ad_process WHERE value = 'AbERP_InvoiceCapture_ProcessBatch' LIMIT 1;
  END IF;

  IF v_bat_id IS NULL THEN
    INSERT INTO ad_process (
      ad_process_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      value, name, description, help,
      accesslevel, entitytype, isreport, isdirectprint,
      classname, isbetafunctionality, isserverprocess, showhelp,
      copyfromprocess, ad_process_uu, allowmultipleexecution
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_InvoiceCapture_ProcessBatch', 'Process Invoice Capture Batch',
      'Process all eligible Invoice Capture records (shared service with Process Selected Invoice).',
      'Intended for scheduler / overnight catch-up while the host is idle. Users can still process any single record anytime via Process Selected Invoice.',
      '3', 'Ab_ERP', 'N', 'N',
      'com.aberp.invoicecapture.process.ProcessInvoiceCaptureBatch',
      'N', 'Y', 'Y',
      'N', v_bat_uu, 'P'
    ) RETURNING ad_process_id INTO v_bat_id;
  ELSE
    UPDATE ad_process SET
      value = 'AbERP_InvoiceCapture_ProcessBatch',
      name = 'Process Invoice Capture Batch',
      classname = 'com.aberp.invoicecapture.process.ProcessInvoiceCaptureBatch',
      isserverprocess = 'Y',
      entitytype = 'Ab_ERP',
      isactive = 'Y',
      ad_process_uu = COALESCE(NULLIF(ad_process_uu, ''), v_bat_uu),
      updated = NOW()
    WHERE ad_process_id = v_bat_id;
  END IF;

  SELECT ad_table_id INTO v_table_id FROM ad_table WHERE tablename = 'AbERP_InvoiceCapture';
  SELECT ad_column_id INTO v_col_id FROM ad_column
  WHERE ad_table_id = v_table_id AND columnname = 'AbERP_ProcessSelected';

  IF v_col_id IS NULL THEN
    RAISE EXCEPTION 'SAW019: AbERP_ProcessSelected column missing';
  END IF;

  UPDATE ad_column SET
    ad_reference_id = 28,
    ad_process_id = v_sel_id,
    istoolbarbutton = 'B',
    isupdateable = 'Y',
    updated = NOW()
  WHERE ad_column_id = v_col_id;

  -- Process access by role name
  INSERT INTO ad_process_access (
    ad_process_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, isreadwrite, ad_process_access_uu
  )
  SELECT p.ad_process_id, r.ad_role_id, r.ad_client_id, 0, 'Y',
         NOW(), 100, NOW(), 100, 'Y', NULL
  FROM ad_process p
  CROSS JOIN ad_role r
  WHERE p.ad_process_id IN (v_sel_id, v_bat_id)
    AND r.name IN ('AbilityERP Admin', 'Admin', 'System Administrator')
    AND r.isactive = 'Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_process_access pa
      WHERE pa.ad_process_id = p.ad_process_id
        AND pa.ad_role_id = r.ad_role_id
        AND pa.ad_client_id = r.ad_client_id
    );

  RAISE NOTICE 'SAW019 processes selected=% batch=%', v_sel_id, v_bat_id;
END $$;
