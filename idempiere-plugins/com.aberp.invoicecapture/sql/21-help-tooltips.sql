-- =============================================================================
-- SAW019 — Help / Description (tooltips + How-To) for Invoice Capture UX
-- iDempiere: Description = hover tooltip; Help = Context Help / How-To panel
-- Field-level text with IsCentrallyMaintained=N so shared Elements are not changed
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_window INTEGER;
  v_tab INTEGER;
  v_menu INTEGER;
BEGIN
  SELECT ad_window_id INTO v_window
  FROM ad_window WHERE ad_window_uu = '19a01903-c0d4-4f01-8e15-000000000001';
  IF v_window IS NULL THEN
    SELECT ad_window_id INTO v_window
    FROM ad_window WHERE name = 'Invoice Capture' AND entitytype = 'Ab_ERP' LIMIT 1;
  END IF;
  IF v_window IS NULL THEN
    RAISE EXCEPTION 'SAW019: Invoice Capture window missing';
  END IF;

  SELECT t.ad_tab_id INTO v_tab
  FROM ad_tab t
  WHERE t.ad_window_id = v_window AND t.seqno = 10
  LIMIT 1;

  UPDATE ad_window SET
    description = 'Capture a vendor PDF, run OCR, and create a Draft AP Invoice (optional PO match).',
    help = $h$How to use Invoice Capture

1) New — enter a Name, Save, then click Upload PDF and choose the vendor invoice PDF.
2) Ready — Document No and Last Result appear. Click Process to run OCR and create the Draft AP Invoice.
3) Result — Invoice Details and OCR Extract show what was matched. Upload and Process are hidden after success.

Tips
• Always use Upload PDF (not only the paperclip) so the form advances to the Process step.
• After Process, zoom Vendor Invoice to review the Draft AP, then Complete it when ready.
• Amount must be within $1 of the Purchase Order (Grand Total or open line net) or status becomes Requires Review.
• Possible Duplicate means the same vendor + invoice number already exists — review before continuing.$h$,
    updated = NOW(),
    updatedby = 100
  WHERE ad_window_id = v_window;

  UPDATE ad_window_trl wt SET
    description = w.description,
    help = w.help,
    istranslated = 'N',
    updated = NOW()
  FROM ad_window w
  WHERE wt.ad_window_id = w.ad_window_id AND w.ad_window_id = v_window;

  UPDATE ad_tab SET
    description = 'Follow the steps: Name → Upload PDF → Process → review results.',
    help = $h$Step-by-step

• Stage 1 (new): fill Name, Save, Upload PDF.
• Stage 2 (uploaded): check Document No / Last Result, then Process.
• Stage 3 (processed): review Invoice Details and OCR Extract. Buttons are hidden.

Last Result always explains the latest upload or process outcome.$h$,
    updated = NOW(),
    updatedby = 100
  WHERE ad_tab_id = v_tab;

  UPDATE ad_tab_trl tt SET
    description = t.description,
    help = t.help,
    istranslated = 'N',
    updated = NOW()
  FROM ad_tab t
  WHERE tt.ad_tab_id = t.ad_tab_id AND t.ad_tab_id = v_tab;

  SELECT ad_menu_id INTO v_menu
  FROM ad_menu WHERE ad_menu_uu = '19a01906-c0d4-4f01-8e15-000000000001';
  IF v_menu IS NOT NULL THEN
    UPDATE ad_menu SET
      description = 'Vendor PDF capture → OCR → Draft AP Invoice',
      updated = NOW()
    WHERE ad_menu_id = v_menu;
    UPDATE ad_menu_trl mt SET
      description = m.description,
      istranslated = 'N',
      updated = NOW()
    FROM ad_menu m
    WHERE mt.ad_menu_id = m.ad_menu_id AND m.ad_menu_id = v_menu;
  END IF;

  -- -------------------------------------------------------------------------
  -- Fields: Description = tooltip, Help = How-To (Context Help)
  -- -------------------------------------------------------------------------
  UPDATE ad_field f SET
    iscentrallymaintained = 'N',
    description = CASE c.columnname
      WHEN 'Name' THEN 'Short label for this capture (required before Upload).'
      WHEN 'AbERP_UploadPDF' THEN 'Attach the vendor invoice PDF to this record.'
      WHEN 'DocumentNo' THEN 'System document number for this capture (assigned on Save).'
      WHEN 'LastResult' THEN 'Outcome of the last Upload or Process.'
      WHEN 'AbERP_ProcessSelected' THEN 'Run OCR and create the Draft AP Invoice.'
      WHEN 'CaptureStatus' THEN 'Current capture status after Process.'
      WHEN 'C_BPartner_ID' THEN 'Vendor matched from the PDF (or confirmation).'
      WHEN 'C_Order_ID' THEN 'Purchase Order linked to this capture / draft invoice.'
      WHEN 'VendorInvoiceNo' THEN 'Vendor invoice number read from the PDF.'
      WHEN 'InvoiceDate' THEN 'Invoice date read from the PDF.'
      WHEN 'GrandTotal' THEN 'Invoice total read from the PDF (inc. tax when present).'
      WHEN 'C_Invoice_ID' THEN 'Draft Vendor Invoice created by Process — zoom to open it.'
      WHEN 'ExtractedText' THEN 'OCR text extracted from the PDF (for review).'
      ELSE f.description
    END,
    help = CASE c.columnname
      WHEN 'Name' THEN
        'Enter a clear name (vendor + invoice reference works well), then Save. The Upload PDF button appears for a new capture until a PDF is uploaded.'
      WHEN 'AbERP_UploadPDF' THEN
        'Save the record first, then choose the PDF. Upload attaches the file and updates Last Result (e.g. “PDF uploaded: …”). That advances the form to the Process step. Prefer this button over the toolbar paperclip so the guided steps work.'
      WHEN 'DocumentNo' THEN
        'Assigned automatically when you Save. Use it to find the capture later. Shown after a PDF is uploaded and again on the processed result.'
      WHEN 'LastResult' THEN
        'After Upload: confirms the PDF was attached. After Process: summarises OCR / matching / Draft AP creation (or why review is required). Read this message when something looks wrong.'
      WHEN 'AbERP_ProcessSelected' THEN
        'Runs the same pipeline as the overnight batch: OCR → vendor / PO match → Draft AP Invoice. Visible only after Upload. Hidden once Processed. On success, review Vendor Invoice and Complete when ready.'
      WHEN 'CaptureStatus' THEN
        'Typical values: Successfully Processed, Requires Review, Vendor Not Matched, Possible Duplicate, PDF Unreadable. Requires Review often means the amount differs from the PO by more than $1.'
      WHEN 'C_BPartner_ID' THEN
        'Filled by Process when the vendor is recognised (e.g. ABN / name). Confirm or correct before completing the Vendor Invoice.'
      WHEN 'C_Order_ID' THEN
        'Linked when a PO number is found on the PDF or you selected a Purchase Order. Draft AP lines are created from open PO lines when possible. Check this field — not only Order Reference on the invoice.'
      WHEN 'VendorInvoiceNo' THEN
        'Parsed from the PDF. Used for duplicate checks (same vendor + invoice number).'
      WHEN 'InvoiceDate' THEN
        'Parsed from the PDF. Becomes the AP Account / Invoice date where applicable.'
      WHEN 'GrandTotal' THEN
        'Parsed from the PDF. Compared to the PO Grand Total or open line net (± $1). Outside that band → Requires Review.'
      WHEN 'C_Invoice_ID' THEN
        'Zoom here to open the Draft Vendor Invoice. Complete it in the Invoice window after you are satisfied with vendor, PO lines, and amounts. Matched POs tab on the invoice may stay empty for charge-only lines — the header Purchase Order still links the documents.'
      WHEN 'ExtractedText' THEN
        'Raw text from pdftotext / OCR. Use it to verify why fields were filled or why matching failed. Shown after Process only.'
      ELSE f.help
    END,
    updated = NOW(),
    updatedby = 100
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab
    AND f.ad_column_id = c.ad_column_id
    AND c.columnname IN (
      'Name', 'AbERP_UploadPDF', 'DocumentNo', 'LastResult', 'AbERP_ProcessSelected',
      'CaptureStatus', 'C_BPartner_ID', 'C_Order_ID', 'VendorInvoiceNo', 'InvoiceDate',
      'GrandTotal', 'C_Invoice_ID', 'ExtractedText'
    );

  UPDATE ad_field_trl ft SET
    description = f.description,
    help = f.help,
    istranslated = 'N',
    updated = NOW()
  FROM ad_field f
  JOIN ad_column c ON c.ad_column_id = f.ad_column_id
  WHERE ft.ad_field_id = f.ad_field_id
    AND f.ad_tab_id = v_tab
    AND c.columnname IN (
      'Name', 'AbERP_UploadPDF', 'DocumentNo', 'LastResult', 'AbERP_ProcessSelected',
      'CaptureStatus', 'C_BPartner_ID', 'C_Order_ID', 'VendorInvoiceNo', 'InvoiceDate',
      'GrandTotal', 'C_Invoice_ID', 'ExtractedText'
    );

  -- -------------------------------------------------------------------------
  -- Processes
  -- -------------------------------------------------------------------------
  UPDATE ad_process SET
    description = 'Attach a vendor invoice PDF to this capture record.',
    help = $h$Save the Invoice Capture first, click Upload PDF, and select the file.

Upload stores a standard attachment and sets Last Result so the window shows Document No and the Process button.

Then click Process to run OCR and create the Draft AP Invoice.$h$,
    updated = NOW()
  WHERE ad_process_uu = '19a01910-c0d4-4f01-8e15-000000000001'
     OR value = 'AbERP_InvoiceCapture_UploadPdf';

  UPDATE ad_process SET
    description = 'OCR the PDF, match vendor/PO, and create a Draft Vendor Invoice.',
    help = $h$Available after Upload PDF (Last Result set, not yet Processed).

Requires a PDF attachment. Creates or updates capture fields from OCR, links Purchase Order when matched, and creates a Draft AP Invoice for review.

After success, zoom Vendor Invoice → Complete when ready. Re-run is blocked once Successfully Processed with a linked invoice.$h$,
    updated = NOW()
  WHERE ad_process_uu = '19a01908-c0d4-4f01-8e15-000000000001'
     OR value = 'AbERP_InvoiceCapture_ProcessSelected';

  UPDATE ad_process SET
    description = 'Overnight catch-up: process eligible Pending captures.',
    help = $h$Scheduler / batch process using the same pipeline as Process on the window.

Prefer processing single records in Invoice Capture during the day. Use batch overnight for leftover Pending uploads.$h$,
    updated = NOW()
  WHERE ad_process_uu = '19a01909-c0d4-4f01-8e15-000000000001'
     OR value = 'AbERP_InvoiceCapture_ProcessBatch';

  UPDATE ad_process_trl pt SET
    description = p.description,
    help = p.help,
    istranslated = 'N',
    updated = NOW()
  FROM ad_process p
  WHERE pt.ad_process_id = p.ad_process_id
    AND (
      p.ad_process_uu IN (
        '19a01908-c0d4-4f01-8e15-000000000001',
        '19a01909-c0d4-4f01-8e15-000000000001',
        '19a01910-c0d4-4f01-8e15-000000000001'
      )
      OR p.value IN (
        'AbERP_InvoiceCapture_ProcessSelected',
        'AbERP_InvoiceCapture_ProcessBatch',
        'AbERP_InvoiceCapture_UploadPdf'
      )
    );

  -- Process parameter FileName tooltip
  UPDATE ad_process_para pp SET
    description = 'Choose the vendor invoice PDF to attach.',
    help = 'Select a PDF from your computer. The file is saved as an attachment on this capture record.',
    iscentrallymaintained = 'N',
    updated = NOW()
  FROM ad_process p
  WHERE pp.ad_process_id = p.ad_process_id
    AND p.value = 'AbERP_InvoiceCapture_UploadPdf'
    AND pp.columnname = 'FileName';

  RAISE NOTICE 'SAW019 help/tooltips updated window=% tab=%', v_window, v_tab;
END $$;
