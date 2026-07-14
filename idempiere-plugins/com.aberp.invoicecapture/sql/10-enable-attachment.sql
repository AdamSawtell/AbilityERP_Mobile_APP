-- =============================================================================
-- SAW019 — Make Attachment usable on Invoice Capture
-- 1) Put standard Window Attachment on main toolbar (not buried in More)
-- 2) Add Upload Invoice PDF process + button (File picker → AD attachment)
-- Fixed UUs:
--   Process  19a01910-c0d4-4f01-8e15-000000000001
--   Para     19a01911-c0d4-4f01-8e15-000000000001
--   Column   19a019c0-0024-4f01-8e15-000000000001
--   Field    19a019f0-0017-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_process_id),0)+1 FROM ad_process))
WHERE name='AD_Process' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_process_para_id),0)+1 FROM ad_process_para))
WHERE name='AD_Process_Para' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';

-- Physical button column
ALTER TABLE aberp_invoicecapture
  ADD COLUMN IF NOT EXISTS aberp_uploadpdf character(1);

-- Standard attachment paperclip on main toolbar (was isshowmore=Y under "More")
UPDATE ad_toolbarbutton SET
  isshowmore = 'N',
  isactive = 'Y',
  updated = NOW(),
  updatedby = 100
WHERE componentname = 'Attachment'
  AND action = 'W'
  AND (ad_tab_id IS NULL);

DO $$
DECLARE
  v_proc_uu CONSTANT TEXT := '19a01910-c0d4-4f01-8e15-000000000001';
  v_para_uu CONSTANT TEXT := '19a01911-c0d4-4f01-8e15-000000000001';
  v_col_uu  CONSTANT TEXT := '19a019c0-0024-4f01-8e15-000000000001';
  -- 0017 is Client field UU (13-fix-client-field); Upload button uses 0019
  v_field_uu CONSTANT TEXT := '19a019f0-0019-4f01-8e15-000000000001';
  v_proc_id INTEGER;
  v_para_id INTEGER;
  v_table_id INTEGER;
  v_tab_id INTEGER;
  v_col_id INTEGER;
  v_field_id INTEGER;
  v_el INTEGER;
BEGIN
  SELECT ad_table_id INTO v_table_id FROM ad_table WHERE tablename = 'AbERP_InvoiceCapture';
  SELECT ad_tab_id INTO v_tab_id FROM ad_tab
  WHERE ad_tab_uu = '19a01904-c0d4-4f01-8e15-000000000001'
     OR (ad_table_id = v_table_id AND seqno = 10)
  LIMIT 1;
  IF v_table_id IS NULL OR v_tab_id IS NULL THEN
    RAISE EXCEPTION 'SAW019: Invoice Capture table/tab missing — run 03/04 first';
  END IF;

  -- Process
  SELECT ad_process_id INTO v_proc_id FROM ad_process WHERE ad_process_uu = v_proc_uu;
  IF v_proc_id IS NULL THEN
    SELECT ad_process_id INTO v_proc_id FROM ad_process WHERE value = 'AbERP_InvoiceCapture_UploadPdf' LIMIT 1;
  END IF;

  IF v_proc_id IS NULL THEN
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
      'AbERP_InvoiceCapture_UploadPdf', 'Upload Invoice PDF',
      'Upload a PDF and attach it to the current Invoice Capture record.',
      'Save the capture record first, then Upload Invoice PDF, then Process Selected Invoice. Uses standard iDempiere attachments.',
      '3', 'Ab_ERP', 'N', 'N',
      'com.aberp.invoicecapture.process.UploadInvoicePdf',
      'N', 'N', 'Y',
      'N', v_proc_uu, 'P'
    ) RETURNING ad_process_id INTO v_proc_id;
  ELSE
    UPDATE ad_process SET
      value = 'AbERP_InvoiceCapture_UploadPdf',
      name = 'Upload Invoice PDF',
      classname = 'com.aberp.invoicecapture.process.UploadInvoicePdf',
      entitytype = 'Ab_ERP',
      isactive = 'Y',
      ad_process_uu = COALESCE(NULLIF(ad_process_uu, ''), v_proc_uu),
      updated = NOW()
    WHERE ad_process_id = v_proc_id;
  END IF;

  -- File parameter (FileName / FilePath style used by ZK upload)
  SELECT ad_process_para_id INTO v_para_id FROM ad_process_para WHERE ad_process_para_uu = v_para_uu;
  IF v_para_id IS NULL THEN
    SELECT ad_process_para_id INTO v_para_id FROM ad_process_para
    WHERE ad_process_id = v_proc_id AND columnname = 'FileName' LIMIT 1;
  END IF;

  IF v_para_id IS NULL THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, ad_process_id, seqno,
      ad_reference_id, columnname, ismandatory, isrange,
      fieldlength, iscentrallymaintained, entitytype, ad_process_para_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process_Para' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'File Name', 'PDF to attach', 'Select the vendor invoice PDF',
      v_proc_id, 10,
      -- 39 = FileName on this iDempiere build (file upload in process dialog)
      39, 'FileName', 'Y', 'N',
      500, 'Y', 'Ab_ERP', v_para_uu
    );
  ELSE
    UPDATE ad_process_para SET
      ad_process_id = v_proc_id,
      columnname = 'FileName',
      ad_reference_id = 39,
      ismandatory = 'Y',
      name = 'File Name',
      ad_process_para_uu = COALESCE(ad_process_para_uu, v_para_uu),
      updated = NOW()
    WHERE ad_process_para_id = v_para_id;
  END IF;

  -- Element + column button
  SELECT ad_element_id INTO v_el FROM ad_element WHERE columnname = 'AbERP_UploadPDF' LIMIT 1;
  IF v_el IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_UploadPDF', 'Ab_ERP', 'Upload Invoice PDF', 'Upload Invoice PDF',
      '19a01900-0000-4000-8000-' || lpad(substr(md5('AbERP_UploadPDF'), 1, 12), 12, '0')
    ) RETURNING ad_element_id INTO v_el;
  END IF;

  SELECT ad_column_id INTO v_col_id FROM ad_column WHERE ad_column_uu = v_col_uu;
  IF v_col_id IS NULL THEN
    SELECT ad_column_id INTO v_col_id FROM ad_column
    WHERE ad_table_id = v_table_id AND columnname = 'AbERP_UploadPDF';
  END IF;

  IF v_col_id IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, version, entitytype, columnname, ad_table_id,
      ad_reference_id, ad_process_id, fieldlength,
      iskey, isparent, ismandatory, isupdateable, isidentifier,
      seqno, istranslated, isencrypted, isselectioncolumn,
      ad_element_id, issyncdatabase, isalwaysupdateable,
      isallowcopy, istoolbarbutton, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Upload Invoice PDF', 0, 'Ab_ERP', 'AbERP_UploadPDF', v_table_id,
      28, v_proc_id, 1,
      'N', 'N', 'N', 'Y', 'N',
      215, 'N', 'N', 'N',
      v_el, 'Y', 'N',
      'N', 'B', v_col_uu
    ) RETURNING ad_column_id INTO v_col_id;
  ELSE
    UPDATE ad_column SET
      ad_reference_id = 28,
      ad_process_id = v_proc_id,
      istoolbarbutton = 'B',
      isupdateable = 'Y',
      ad_column_uu = COALESCE(ad_column_uu, v_col_uu),
      updated = NOW()
    WHERE ad_column_id = v_col_id;
  END IF;

  SELECT ad_field_id INTO v_field_id FROM ad_field
  WHERE ad_tab_id = v_tab_id AND ad_column_id = v_col_id;
  IF v_field_id IS NULL THEN
    SELECT ad_field_id INTO v_field_id FROM ad_field
    WHERE ad_field_uu = v_field_uu AND ad_tab_id = v_tab_id;
  END IF;

  IF v_field_id IS NULL THEN
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
      'Upload Invoice PDF', 'Y', v_tab_id, v_col_id,
      'Y', 0, 'N', 135, 'Y',
      'N', 'N', 'N', 'Ab_ERP',
      'N', 135, 1, 2, 1, v_field_uu
    );
  ELSE
    UPDATE ad_field SET
      isdisplayed = 'Y',
      seqno = 135,
      issameline = 'Y',
      ad_field_uu = COALESCE(ad_field_uu, v_field_uu),
      updated = NOW()
    WHERE ad_field_id = v_field_id;
  END IF;

  -- Process access
  INSERT INTO ad_process_access (
    ad_process_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, isreadwrite, ad_process_access_uu
  )
  SELECT v_proc_id, r.ad_role_id, r.ad_client_id, 0, 'Y',
         NOW(), 100, NOW(), 100, 'Y', NULL
  FROM ad_role r
  WHERE r.name IN ('AbilityERP Admin', 'Admin', 'System Administrator')
    AND r.isactive = 'Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_process_access pa
      WHERE pa.ad_process_id = v_proc_id
        AND pa.ad_role_id = r.ad_role_id
        AND pa.ad_client_id = r.ad_client_id
    );

  RAISE NOTICE 'SAW019 attachment enabled: upload process=% toolbar Attachment on main bar', v_proc_id;
END $$;
