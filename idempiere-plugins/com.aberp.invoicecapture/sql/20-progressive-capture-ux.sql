-- =============================================================================
-- SAW019 — Progressive Invoice Capture UX (field groups + display logic)
-- Stages:
--   1) New / not uploaded (Processed=N, LastResult empty): Name + Upload PDF
--   2) Uploaded, ready (Processed=N, LastResult set): Document No + Last Result + Process
--   3) Processed (Processed=Y): full result fields in groups; buttons hidden
-- iDempiere practice: AD_FieldGroup Label (L) for step headers; Collapsible (C)
-- for detail sections. Display Logic is on each field (groups have no display logic).
-- "Ready" signal: Upload Invoice PDF sets LastResult to "PDF uploaded: …"
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_fieldgroup_id),0)+1 FROM ad_fieldgroup))
WHERE name = 'AD_FieldGroup' AND istableid = 'Y';

DO $$
DECLARE
  v_tab INTEGER;
  v_fg_upload INTEGER;
  v_fg_ready INTEGER;
  v_fg_invoice INTEGER;
  v_fg_ocr INTEGER;
  v_fg_upload_uu  CONSTANT TEXT := '19a019fg-0001-4f01-8e15-000000000001';
  v_fg_ready_uu   CONSTANT TEXT := '19a019fg-0002-4f01-8e15-000000000001';
  v_fg_invoice_uu CONSTANT TEXT := '19a019fg-0003-4f01-8e15-000000000001';
  v_fg_ocr_uu     CONSTANT TEXT := '19a019fg-0004-4f01-8e15-000000000001';
  v_s1  CONSTANT TEXT := '@Processed@=N & @LastResult@=''''';
  v_s2  CONSTANT TEXT := '@Processed@=N & @LastResult@!''''';
  v_s3  CONSTANT TEXT := '@Processed@=Y';
  -- Avoid nested parentheses — ZK Evaluator hid fields with (...|...) form
  v_s23 CONSTANT TEXT := '@LastResult@!'''' | @Processed@=Y';
BEGIN
  SELECT t.ad_tab_id INTO v_tab
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE w.ad_window_uu = '19a01903-c0d4-4f01-8e15-000000000001'
    AND t.seqno = 10
  LIMIT 1;
  IF v_tab IS NULL THEN
    SELECT t.ad_tab_id INTO v_tab
    FROM ad_tab t
    JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
    WHERE tb.tablename = 'AbERP_InvoiceCapture' AND t.seqno = 10
    LIMIT 1;
  END IF;
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'SAW019: Invoice Capture header tab missing';
  END IF;

  -- 1. Upload PDF (Label)
  SELECT ad_fieldgroup_id INTO v_fg_upload FROM ad_fieldgroup WHERE ad_fieldgroup_uu = v_fg_upload_uu;
  IF v_fg_upload IS NULL THEN
    SELECT ad_fieldgroup_id INTO v_fg_upload FROM ad_fieldgroup
    WHERE name = '1. Upload PDF' AND entitytype = 'Ab_ERP' LIMIT 1;
  END IF;
  IF v_fg_upload IS NULL THEN
    INSERT INTO ad_fieldgroup (
      ad_fieldgroup_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, entitytype, fieldgrouptype, iscollapsedbydefault, ad_fieldgroup_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_FieldGroup' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      '1. Upload PDF', 'Ab_ERP', 'L', 'N', v_fg_upload_uu
    ) RETURNING ad_fieldgroup_id INTO v_fg_upload;
  ELSE
    UPDATE ad_fieldgroup SET
      name = '1. Upload PDF', fieldgrouptype = 'L', iscollapsedbydefault = 'N',
      entitytype = 'Ab_ERP',
      ad_fieldgroup_uu = COALESCE(NULLIF(ad_fieldgroup_uu, ''), v_fg_upload_uu),
      updated = NOW()
    WHERE ad_fieldgroup_id = v_fg_upload;
  END IF;

  -- Document (Label) — Doc No / Last Result (stage 2+3) + Process (stage 2 only)
  SELECT ad_fieldgroup_id INTO v_fg_ready FROM ad_fieldgroup WHERE ad_fieldgroup_uu = v_fg_ready_uu;
  IF v_fg_ready IS NULL THEN
    SELECT ad_fieldgroup_id INTO v_fg_ready FROM ad_fieldgroup
    WHERE name IN ('Document', '2. Ready to Process') AND entitytype = 'Ab_ERP' LIMIT 1;
  END IF;
  IF v_fg_ready IS NULL THEN
    INSERT INTO ad_fieldgroup (
      ad_fieldgroup_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, entitytype, fieldgrouptype, iscollapsedbydefault, ad_fieldgroup_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_FieldGroup' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Document', 'Ab_ERP', 'L', 'N', v_fg_ready_uu
    ) RETURNING ad_fieldgroup_id INTO v_fg_ready;
  ELSE
    UPDATE ad_fieldgroup SET
      name = 'Document', fieldgrouptype = 'L', iscollapsedbydefault = 'N',
      entitytype = 'Ab_ERP',
      ad_fieldgroup_uu = COALESCE(NULLIF(ad_fieldgroup_uu, ''), v_fg_ready_uu),
      updated = NOW()
    WHERE ad_fieldgroup_id = v_fg_ready;
  END IF;

  -- Invoice Details (Collapsible) — after process
  SELECT ad_fieldgroup_id INTO v_fg_invoice FROM ad_fieldgroup WHERE ad_fieldgroup_uu = v_fg_invoice_uu;
  IF v_fg_invoice IS NULL THEN
    SELECT ad_fieldgroup_id INTO v_fg_invoice FROM ad_fieldgroup
    WHERE name = 'Invoice Details' AND entitytype = 'Ab_ERP' LIMIT 1;
  END IF;
  IF v_fg_invoice IS NULL THEN
    INSERT INTO ad_fieldgroup (
      ad_fieldgroup_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, entitytype, fieldgrouptype, iscollapsedbydefault, ad_fieldgroup_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_FieldGroup' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Invoice Details', 'Ab_ERP', 'C', 'N', v_fg_invoice_uu
    ) RETURNING ad_fieldgroup_id INTO v_fg_invoice;
  ELSE
    UPDATE ad_fieldgroup SET
      name = 'Invoice Details', fieldgrouptype = 'C', iscollapsedbydefault = 'N',
      entitytype = 'Ab_ERP',
      ad_fieldgroup_uu = COALESCE(NULLIF(ad_fieldgroup_uu, ''), v_fg_invoice_uu),
      updated = NOW()
    WHERE ad_fieldgroup_id = v_fg_invoice;
  END IF;

  -- OCR Extract (Collapsible)
  SELECT ad_fieldgroup_id INTO v_fg_ocr FROM ad_fieldgroup WHERE ad_fieldgroup_uu = v_fg_ocr_uu;
  IF v_fg_ocr IS NULL THEN
    SELECT ad_fieldgroup_id INTO v_fg_ocr FROM ad_fieldgroup
    WHERE name = 'OCR Extract' AND entitytype = 'Ab_ERP' LIMIT 1;
  END IF;
  IF v_fg_ocr IS NULL THEN
    INSERT INTO ad_fieldgroup (
      ad_fieldgroup_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, entitytype, fieldgrouptype, iscollapsedbydefault, ad_fieldgroup_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_FieldGroup' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'OCR Extract', 'Ab_ERP', 'C', 'N', v_fg_ocr_uu
    ) RETURNING ad_fieldgroup_id INTO v_fg_ocr;
  ELSE
    UPDATE ad_fieldgroup SET
      name = 'OCR Extract', fieldgrouptype = 'C', iscollapsedbydefault = 'N',
      entitytype = 'Ab_ERP',
      ad_fieldgroup_uu = COALESCE(NULLIF(ad_fieldgroup_uu, ''), v_fg_ocr_uu),
      updated = NOW()
    WHERE ad_fieldgroup_id = v_fg_ocr;
  END IF;

  INSERT INTO ad_fieldgroup_trl (
    ad_fieldgroup_id, ad_language, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, name, istranslated
  )
  SELECT fg.ad_fieldgroup_id, l.ad_language, 0, 0, 'Y',
         NOW(), 100, NOW(), 100, fg.name, 'N'
  FROM ad_fieldgroup fg
  CROSS JOIN ad_language l
  WHERE fg.ad_fieldgroup_id IN (v_fg_upload, v_fg_ready, v_fg_invoice, v_fg_ocr)
    AND l.issystemlanguage = 'Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_fieldgroup_trl t
      WHERE t.ad_fieldgroup_id = fg.ad_fieldgroup_id AND t.ad_language = l.ad_language
    );

  UPDATE ad_fieldgroup_trl t SET name = fg.name, updated = NOW()
  FROM ad_fieldgroup fg
  WHERE t.ad_fieldgroup_id = fg.ad_fieldgroup_id
    AND fg.ad_fieldgroup_id IN (v_fg_upload, v_fg_ready, v_fg_invoice, v_fg_ocr);

  UPDATE ad_field f SET
    isdisplayed = CASE c.columnname
      WHEN 'AbERP_InvoiceCapture_ID' THEN 'N'
      WHEN 'AD_Client_ID' THEN 'N'
      WHEN 'AD_Org_ID' THEN 'N'
      WHEN 'FilePath' THEN 'N'
      WHEN 'TaxID' THEN 'N'
      WHEN 'IsActive' THEN 'N'
      WHEN 'Processed' THEN 'N'
      WHEN 'Name' THEN 'Y'
      WHEN 'AbERP_UploadPDF' THEN 'Y'
      WHEN 'DocumentNo' THEN 'Y'
      WHEN 'LastResult' THEN 'Y'
      WHEN 'AbERP_ProcessSelected' THEN 'Y'
      WHEN 'CaptureStatus' THEN 'Y'
      WHEN 'C_BPartner_ID' THEN 'Y'
      WHEN 'C_Order_ID' THEN 'Y'
      WHEN 'VendorInvoiceNo' THEN 'Y'
      WHEN 'InvoiceDate' THEN 'Y'
      WHEN 'GrandTotal' THEN 'Y'
      WHEN 'C_Invoice_ID' THEN 'Y'
      WHEN 'ExtractedText' THEN 'Y'
      ELSE f.isdisplayed
    END,
    isdisplayedgrid = CASE c.columnname
      WHEN 'DocumentNo' THEN 'Y'
      WHEN 'CaptureStatus' THEN 'Y'
      WHEN 'Name' THEN 'Y'
      WHEN 'C_BPartner_ID' THEN 'Y'
      WHEN 'VendorInvoiceNo' THEN 'Y'
      WHEN 'InvoiceDate' THEN 'Y'
      WHEN 'GrandTotal' THEN 'Y'
      WHEN 'C_Invoice_ID' THEN 'Y'
      WHEN 'LastResult' THEN 'Y'
      ELSE 'N'
    END,
    seqno = CASE c.columnname
      WHEN 'Name' THEN 10
      WHEN 'AbERP_UploadPDF' THEN 20
      WHEN 'DocumentNo' THEN 30
      WHEN 'CaptureStatus' THEN 35
      WHEN 'LastResult' THEN 40
      WHEN 'AbERP_ProcessSelected' THEN 50
      WHEN 'C_BPartner_ID' THEN 70
      WHEN 'C_Order_ID' THEN 80
      WHEN 'VendorInvoiceNo' THEN 90
      WHEN 'InvoiceDate' THEN 100
      WHEN 'GrandTotal' THEN 110
      WHEN 'C_Invoice_ID' THEN 120
      WHEN 'ExtractedText' THEN 130
      WHEN 'AbERP_InvoiceCapture_ID' THEN 0
      WHEN 'AD_Client_ID' THEN 5
      WHEN 'AD_Org_ID' THEN 8
      WHEN 'FilePath' THEN 900
      WHEN 'TaxID' THEN 910
      WHEN 'IsActive' THEN 930
      WHEN 'Processed' THEN 940
      ELSE f.seqno
    END,
    seqnogrid = CASE c.columnname
      WHEN 'DocumentNo' THEN 10
      WHEN 'CaptureStatus' THEN 20
      WHEN 'Name' THEN 30
      WHEN 'C_BPartner_ID' THEN 40
      WHEN 'VendorInvoiceNo' THEN 50
      WHEN 'InvoiceDate' THEN 60
      WHEN 'GrandTotal' THEN 70
      WHEN 'C_Invoice_ID' THEN 80
      WHEN 'LastResult' THEN 90
      ELSE 0
    END,
    displaylogic = CASE c.columnname
      WHEN 'Name' THEN '@Processed@=N & @LastResult@='''' | @Processed@=Y'
      WHEN 'AbERP_UploadPDF' THEN v_s1
      WHEN 'DocumentNo' THEN v_s23
      WHEN 'LastResult' THEN v_s23
      WHEN 'AbERP_ProcessSelected' THEN v_s2
      WHEN 'CaptureStatus' THEN v_s23
      WHEN 'C_BPartner_ID' THEN v_s3
      WHEN 'C_Order_ID' THEN v_s3
      WHEN 'VendorInvoiceNo' THEN v_s3
      WHEN 'InvoiceDate' THEN v_s3
      WHEN 'GrandTotal' THEN v_s3
      WHEN 'C_Invoice_ID' THEN v_s3
      WHEN 'ExtractedText' THEN v_s3
      ELSE NULL
    END,
    ad_fieldgroup_id = CASE c.columnname
      -- Name stays ungrouped (stage 1 + after process). Upload alone under Label group.
      WHEN 'Name' THEN NULL
      WHEN 'AbERP_UploadPDF' THEN v_fg_upload
      WHEN 'DocumentNo' THEN v_fg_ready
      WHEN 'CaptureStatus' THEN v_fg_ready
      WHEN 'LastResult' THEN v_fg_ready
      WHEN 'AbERP_ProcessSelected' THEN v_fg_ready
      WHEN 'C_BPartner_ID' THEN v_fg_invoice
      WHEN 'C_Order_ID' THEN v_fg_invoice
      WHEN 'VendorInvoiceNo' THEN v_fg_invoice
      WHEN 'InvoiceDate' THEN v_fg_invoice
      WHEN 'GrandTotal' THEN v_fg_invoice
      WHEN 'C_Invoice_ID' THEN v_fg_invoice
      WHEN 'ExtractedText' THEN v_fg_ocr
      ELSE NULL
    END,
    issameline = CASE c.columnname
      WHEN 'CaptureStatus' THEN 'Y'
      WHEN 'C_Order_ID' THEN 'Y'
      WHEN 'InvoiceDate' THEN 'Y'
      ELSE 'N'
    END,
    xposition = CASE c.columnname
      WHEN 'CaptureStatus' THEN 4
      WHEN 'C_Order_ID' THEN 4
      WHEN 'InvoiceDate' THEN 4
      WHEN 'AbERP_UploadPDF' THEN 2
      WHEN 'AbERP_ProcessSelected' THEN 2
      ELSE 1
    END,
    columnspan = CASE c.columnname
      WHEN 'Name' THEN 5
      WHEN 'DocumentNo' THEN 2
      WHEN 'LastResult' THEN 5
      WHEN 'ExtractedText' THEN 5
      WHEN 'C_Invoice_ID' THEN 5
      WHEN 'CaptureStatus' THEN 2
      WHEN 'C_BPartner_ID' THEN 2
      WHEN 'C_Order_ID' THEN 2
      WHEN 'VendorInvoiceNo' THEN 2
      WHEN 'InvoiceDate' THEN 2
      WHEN 'GrandTotal' THEN 2
      WHEN 'AbERP_UploadPDF' THEN 2
      WHEN 'AbERP_ProcessSelected' THEN 2
      ELSE 2
    END,
    numlines = CASE c.columnname
      WHEN 'LastResult' THEN 2
      WHEN 'ExtractedText' THEN 10
      ELSE 1
    END,
    displaylength = CASE c.columnname
      WHEN 'Name' THEN 40
      WHEN 'DocumentNo' THEN 20
      WHEN 'LastResult' THEN 60
      WHEN 'ExtractedText' THEN 80
      WHEN 'AbERP_UploadPDF' THEN 18
      WHEN 'AbERP_ProcessSelected' THEN 18
      ELSE COALESCE(f.displaylength, 0)
    END,
    isreadonly = CASE c.columnname
      WHEN 'DocumentNo' THEN 'Y'
      WHEN 'CaptureStatus' THEN 'Y'
      WHEN 'C_Invoice_ID' THEN 'Y'
      WHEN 'LastResult' THEN 'Y'
      WHEN 'ExtractedText' THEN 'Y'
      WHEN 'Processed' THEN 'Y'
      WHEN 'AbERP_InvoiceCapture_ID' THEN 'Y'
      WHEN 'AD_Client_ID' THEN 'Y'
      ELSE 'N'
    END,
    updated = NOW(),
    updatedby = 100
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab
    AND f.ad_column_id = c.ad_column_id;

  UPDATE ad_field f SET
    name = CASE c.columnname
      WHEN 'AbERP_UploadPDF' THEN 'Upload PDF'
      WHEN 'AbERP_ProcessSelected' THEN 'Process'
      ELSE f.name
    END,
    iscentrallymaintained = 'N',
    updated = NOW()
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab
    AND f.ad_column_id = c.ad_column_id
    AND c.columnname IN ('AbERP_UploadPDF', 'AbERP_ProcessSelected');

  UPDATE ad_field_trl trl SET
    name = f.name, istranslated = 'N', updated = NOW()
  FROM ad_field f
  JOIN ad_column c ON c.ad_column_id = f.ad_column_id
  WHERE trl.ad_field_id = f.ad_field_id
    AND f.ad_tab_id = v_tab
    AND c.columnname IN ('AbERP_UploadPDF', 'AbERP_ProcessSelected');

  UPDATE ad_column c SET
    isalwaysupdateable = 'Y',
    isupdateable = 'Y',
    updated = NOW()
  FROM ad_table t
  WHERE t.ad_table_id = c.ad_table_id
    AND t.tablename = 'AbERP_InvoiceCapture'
    AND c.columnname IN ('AbERP_UploadPDF', 'AbERP_ProcessSelected');

  RAISE NOTICE 'SAW019 progressive UX tab=% upload=% ready=% invoice=% ocr=%',
    v_tab, v_fg_upload, v_fg_ready, v_fg_invoice, v_fg_ocr;
END $$;
