-- =============================================================================
-- SAW019 — Clean Invoice Capture window layout
-- Hide Org / File Path / Tax ID / Active / Processed
-- Extracted Text: after Last Result, full width, displaylogic @Processed@=Y (see also 19)
-- Two-column field pairs; Upload + Process half-width on one line
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_tab INTEGER;
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

  UPDATE ad_field f SET
    isdisplayed = CASE c.columnname
      WHEN 'AbERP_InvoiceCapture_ID' THEN 'N'
      WHEN 'AD_Client_ID' THEN 'N'
      WHEN 'AD_Org_ID' THEN 'N'
      WHEN 'FilePath' THEN 'N'
      WHEN 'TaxID' THEN 'N'
      WHEN 'IsActive' THEN 'N'
      WHEN 'Processed' THEN 'N'
      WHEN 'DocumentNo' THEN 'Y'
      WHEN 'CaptureStatus' THEN 'Y'
      WHEN 'Name' THEN 'Y'
      WHEN 'C_BPartner_ID' THEN 'Y'
      WHEN 'C_Order_ID' THEN 'Y'
      WHEN 'VendorInvoiceNo' THEN 'Y'
      WHEN 'InvoiceDate' THEN 'Y'
      WHEN 'GrandTotal' THEN 'Y'
      WHEN 'C_Invoice_ID' THEN 'Y'
      WHEN 'LastResult' THEN 'Y'
      WHEN 'ExtractedText' THEN 'Y'
      WHEN 'AbERP_UploadPDF' THEN 'Y'
      WHEN 'AbERP_ProcessSelected' THEN 'Y'
      ELSE f.isdisplayed
    END,
    isdisplayedgrid = CASE c.columnname
      WHEN 'DocumentNo' THEN 'Y'
      WHEN 'CaptureStatus' THEN 'Y'
      WHEN 'Name' THEN 'Y'
      WHEN 'C_BPartner_ID' THEN 'Y'
      WHEN 'C_Order_ID' THEN 'Y'
      WHEN 'VendorInvoiceNo' THEN 'Y'
      WHEN 'InvoiceDate' THEN 'Y'
      WHEN 'GrandTotal' THEN 'Y'
      WHEN 'C_Invoice_ID' THEN 'Y'
      WHEN 'LastResult' THEN 'Y'
      ELSE 'N'
    END,
    seqno = CASE c.columnname
      WHEN 'AbERP_InvoiceCapture_ID' THEN 0
      WHEN 'AD_Client_ID' THEN 5
      WHEN 'AD_Org_ID' THEN 8
      WHEN 'DocumentNo' THEN 10
      WHEN 'CaptureStatus' THEN 20
      WHEN 'Name' THEN 30
      WHEN 'C_BPartner_ID' THEN 40
      WHEN 'C_Order_ID' THEN 50
      WHEN 'VendorInvoiceNo' THEN 60
      WHEN 'InvoiceDate' THEN 70
      WHEN 'GrandTotal' THEN 80
      WHEN 'C_Invoice_ID' THEN 90
      WHEN 'LastResult' THEN 100
      WHEN 'ExtractedText' THEN 105
      WHEN 'AbERP_UploadPDF' THEN 110
      WHEN 'AbERP_ProcessSelected' THEN 120
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
      WHEN 'C_Order_ID' THEN 50
      WHEN 'VendorInvoiceNo' THEN 60
      WHEN 'InvoiceDate' THEN 70
      WHEN 'GrandTotal' THEN 80
      WHEN 'C_Invoice_ID' THEN 90
      WHEN 'LastResult' THEN 100
      ELSE 0
    END,
    issameline = CASE c.columnname
      WHEN 'CaptureStatus' THEN 'Y'
      WHEN 'C_Order_ID' THEN 'Y'
      WHEN 'InvoiceDate' THEN 'Y'
      WHEN 'AbERP_ProcessSelected' THEN 'Y'
      ELSE 'N'
    END,
    xposition = CASE c.columnname
      WHEN 'CaptureStatus' THEN 4
      WHEN 'C_Order_ID' THEN 4
      WHEN 'InvoiceDate' THEN 4
      WHEN 'AbERP_UploadPDF' THEN 2
      WHEN 'AbERP_ProcessSelected' THEN 3
      ELSE 1
    END,
    columnspan = CASE c.columnname
      WHEN 'Name' THEN 5
      WHEN 'LastResult' THEN 5
      WHEN 'ExtractedText' THEN 5
      WHEN 'C_Invoice_ID' THEN 5
      WHEN 'AbERP_UploadPDF' THEN 1
      WHEN 'AbERP_ProcessSelected' THEN 1
      WHEN 'CaptureStatus' THEN 2
      WHEN 'C_Order_ID' THEN 2
      WHEN 'InvoiceDate' THEN 2
      WHEN 'DocumentNo' THEN 2
      WHEN 'C_BPartner_ID' THEN 2
      WHEN 'VendorInvoiceNo' THEN 2
      WHEN 'GrandTotal' THEN 2
      ELSE 2
    END,
    numlines = CASE c.columnname
      WHEN 'LastResult' THEN 2
      WHEN 'ExtractedText' THEN 10
      ELSE 1
    END,
    displaylength = CASE c.columnname
      WHEN 'DocumentNo' THEN 20
      WHEN 'CaptureStatus' THEN 20
      WHEN 'Name' THEN 40
      WHEN 'C_BPartner_ID' THEN 30
      WHEN 'C_Order_ID' THEN 25
      WHEN 'VendorInvoiceNo' THEN 25
      WHEN 'InvoiceDate' THEN 14
      WHEN 'GrandTotal' THEN 14
      WHEN 'C_Invoice_ID' THEN 30
      WHEN 'LastResult' THEN 60
      WHEN 'ExtractedText' THEN 80
      WHEN 'AbERP_UploadPDF' THEN 14
      WHEN 'AbERP_ProcessSelected' THEN 18
      ELSE COALESCE(f.displaylength, 0)
    END,
    displaylogic = CASE c.columnname
      WHEN 'ExtractedText' THEN '@Processed@=Y'
      ELSE f.displaylogic
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

  -- Short labels on buttons for half-width fit
  UPDATE ad_field f SET
    name = CASE c.columnname
      WHEN 'AbERP_UploadPDF' THEN 'Upload PDF'
      WHEN 'AbERP_ProcessSelected' THEN 'Process'
      ELSE f.name
    END,
    iscentrallymaintained = CASE c.columnname
      WHEN 'AbERP_UploadPDF' THEN 'N'
      WHEN 'AbERP_ProcessSelected' THEN 'N'
      ELSE f.iscentrallymaintained
    END,
    updated = NOW()
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab
    AND f.ad_column_id = c.ad_column_id
    AND c.columnname IN ('AbERP_UploadPDF', 'AbERP_ProcessSelected');

  -- Keep en_AU / es_CO field names in sync for short button labels
  UPDATE ad_field_trl trl SET
    name = f.name,
    istranslated = 'N',
    updated = NOW()
  FROM ad_field f
  JOIN ad_column c ON c.ad_column_id = f.ad_column_id
  WHERE trl.ad_field_id = f.ad_field_id
    AND f.ad_tab_id = v_tab
    AND c.columnname IN ('AbERP_UploadPDF', 'AbERP_ProcessSelected');

  RAISE NOTICE 'SAW019 Invoice Capture layout cleaned (tab=%)', v_tab;
END $$;
