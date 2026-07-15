-- =============================================================================
-- SAW019 — Window, tabs, fields
-- Window 19a01903 / Tab1 19a01904 / Tab2 19a01905
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_window_id),0)+1 FROM ad_window))
WHERE name='AD_Window' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_tab_id),0)+1 FROM ad_tab))
WHERE name='AD_Tab' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw019_field(
  p_tab_id INTEGER, p_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_seqno INTEGER, p_displayed CHAR, p_readonly CHAR DEFAULT 'N',
  p_sameline CHAR DEFAULT 'N', p_gridseq INTEGER DEFAULT NULL,
  p_displayedgrid CHAR DEFAULT NULL, p_numlines INTEGER DEFAULT 1
) RETURNS void AS $$
DECLARE
  v_col_id INTEGER;
  v_field_id INTEGER;
  v_table_id INTEGER;
BEGIN
  SELECT ad_table_id INTO v_table_id FROM ad_tab WHERE ad_tab_id = p_tab_id;
  SELECT ad_column_id INTO v_col_id FROM ad_column
  WHERE ad_table_id = v_table_id AND columnname = p_columnname;
  IF v_col_id IS NULL THEN
    RAISE NOTICE 'SAW019 skip field % — column missing', p_columnname;
    RETURN;
  END IF;

  SELECT ad_field_id INTO v_field_id FROM ad_field WHERE ad_field_uu = p_uu;
  IF v_field_id IS NULL THEN
    SELECT ad_field_id INTO v_field_id FROM ad_field
    WHERE ad_tab_id = p_tab_id AND ad_column_id = v_col_id;
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
      p_name, 'Y', p_tab_id, v_col_id,
      p_displayed, 0, p_readonly, p_seqno, p_sameline,
      'N', 'N', 'N', 'Ab_ERP',
      COALESCE(p_displayedgrid, p_displayed), COALESCE(p_gridseq, p_seqno), 1, 2, p_numlines, p_uu
    );
  ELSE
    UPDATE ad_field SET
      name = p_name,
      isdisplayed = p_displayed,
      isreadonly = p_readonly,
      seqno = p_seqno,
      issameline = p_sameline,
      isdisplayedgrid = COALESCE(p_displayedgrid, p_displayed),
      seqnogrid = COALESCE(p_gridseq, p_seqno),
      numlines = p_numlines,
      ad_field_uu = COALESCE(ad_field_uu, p_uu),
      updated = NOW()
    WHERE ad_field_id = v_field_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_window_uu CONSTANT TEXT := '19a01903-c0d4-4f01-8e15-000000000001';
  v_tab1_uu   CONSTANT TEXT := '19a01904-c0d4-4f01-8e15-000000000001';
  v_tab2_uu   CONSTANT TEXT := '19a01905-c0d4-4f01-8e15-000000000001';
  v_window_id INTEGER;
  v_tab1_id INTEGER;
  v_tab2_id INTEGER;
  v_cap_table INTEGER;
  v_log_table INTEGER;
  v_link_col INTEGER;
BEGIN
  SELECT ad_table_id INTO v_cap_table FROM ad_table WHERE tablename = 'AbERP_InvoiceCapture';
  SELECT ad_table_id INTO v_log_table FROM ad_table WHERE tablename = 'AbERP_InvoiceCaptureLog';
  IF v_cap_table IS NULL OR v_log_table IS NULL THEN
    RAISE EXCEPTION 'SAW019: tables missing — run 03 first';
  END IF;

  SELECT ad_window_id INTO v_window_id FROM ad_window WHERE ad_window_uu = v_window_uu;
  IF v_window_id IS NULL THEN
    SELECT ad_window_id INTO v_window_id FROM ad_window WHERE name = 'Invoice Capture' AND entitytype = 'Ab_ERP';
  END IF;

  IF v_window_id IS NULL THEN
    INSERT INTO ad_window (
      ad_window_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, windowtype, issotrx,
      entitytype, processing, isdefault, isbetafunctionality, ad_window_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Window' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Invoice Capture',
      'Capture vendor invoice PDFs, process OCR, create Draft AP Invoices',
      'Attach a PDF (or set File Path), then use Process Selected Invoice. Nightly batch uses the same pipeline. Vendor Invoice stays Draft for review — zoom via Vendor Invoice field.',
      'M', 'N',
      'Ab_ERP', 'N', 'N', 'N', v_window_uu
    ) RETURNING ad_window_id INTO v_window_id;
  ELSE
    UPDATE ad_window SET
      name = 'Invoice Capture',
      description = 'Capture vendor invoice PDFs, process OCR, create Draft AP Invoices',
      ad_window_uu = COALESCE(ad_window_uu, v_window_uu),
      entitytype = 'Ab_ERP',
      isactive = 'Y',
      updated = NOW()
    WHERE ad_window_id = v_window_id;
  END IF;

  UPDATE ad_table SET ad_window_id = v_window_id, updated = NOW()
  WHERE ad_table_id IN (v_cap_table, v_log_table);

  SELECT ad_tab_id INTO v_tab1_id FROM ad_tab WHERE ad_tab_uu = v_tab1_uu;
  IF v_tab1_id IS NULL THEN
    SELECT ad_tab_id INTO v_tab1_id FROM ad_tab
    WHERE ad_window_id = v_window_id AND ad_table_id = v_cap_table AND seqno = 10;
  END IF;

  IF v_tab1_id IS NULL THEN
    INSERT INTO ad_tab (
      ad_tab_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_table_id, ad_window_id, seqno,
      tablevel, issinglerow, isinfotab, istranslationtab, isreadonly,
      hastree, processing, issorttab, entitytype, isinsertrecord, isadvancedtab, ad_tab_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Tab' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Invoice Capture', 'Vendor invoice capture header',
      v_cap_table, v_window_id, 10,
      0, 'Y', 'N', 'N', 'N',
      'N', 'N', 'N', 'Ab_ERP', 'Y', 'N', v_tab1_uu
    ) RETURNING ad_tab_id INTO v_tab1_id;
  END IF;

  SELECT ad_column_id INTO v_link_col FROM ad_column
  WHERE ad_table_id = v_log_table AND columnname = 'AbERP_InvoiceCapture_ID';

  SELECT ad_tab_id INTO v_tab2_id FROM ad_tab WHERE ad_tab_uu = v_tab2_uu;
  IF v_tab2_id IS NULL THEN
    SELECT ad_tab_id INTO v_tab2_id FROM ad_tab
    WHERE ad_window_id = v_window_id AND ad_table_id = v_log_table AND seqno = 20;
  END IF;

  IF v_tab2_id IS NULL THEN
    INSERT INTO ad_tab (
      ad_tab_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_table_id, ad_window_id, seqno,
      tablevel, issinglerow, isinfotab, istranslationtab, isreadonly,
      hastree, processing, issorttab, entitytype, isinsertrecord, isadvancedtab,
      ad_column_id, ad_tab_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Tab' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Processing Log', 'Append-only processing attempts (never cleared)',
      v_log_table, v_window_id, 20,
      1, 'N', 'N', 'N', 'Y',
      'N', 'N', 'N', 'Ab_ERP', 'N', 'N',
      v_link_col, v_tab2_uu
    ) RETURNING ad_tab_id INTO v_tab2_id;
  ELSE
    UPDATE ad_tab SET ad_column_id = v_link_col, isreadonly = 'Y', isinsertrecord = 'N', updated = NOW()
    WHERE ad_tab_id = v_tab2_id;
  END IF;

  -- Header fields (PK + Client must exist on tab — even hidden — or Record_ID/Client stay 0/-1)
  -- Clean layout: hide Org/FilePath/Tax/Active/Processed; Extracted Text after process; buttons side-by-side
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0000-4f01-8e15-000000000001','AbERP_InvoiceCapture_ID','Invoice Capture',0,'N','Y','N',0,'N');
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0017-4f01-8e15-000000000001','AD_Client_ID','Client',5,'N','Y','N',0,'N');
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0001-4f01-8e15-000000000001','AD_Org_ID','Organization',8,'N','N','N',0,'N');
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0002-4f01-8e15-000000000001','DocumentNo','Document No',10,'Y','Y','N',10,'Y');
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0004-4f01-8e15-000000000001','CaptureStatus','Capture Status',20,'Y','Y','Y',20,'Y');
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0003-4f01-8e15-000000000001','Name','Name',30,'Y','N','N',30,'Y');
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0006-4f01-8e15-000000000001','C_BPartner_ID','Business Partner',40,'Y','N','N',40,'Y');
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0018-4f01-8e15-000000000001','C_Order_ID','Purchase Order',50,'Y','N','Y',50,'Y');
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0007-4f01-8e15-000000000001','VendorInvoiceNo','Vendor Invoice No',60,'Y','N','N',60,'Y');
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0009-4f01-8e15-000000000001','InvoiceDate','Invoice Date',70,'Y','N','Y',70,'Y');
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0010-4f01-8e15-000000000001','GrandTotal','Grand Total',80,'Y','N','N',80,'Y');
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0011-4f01-8e15-000000000001','C_Invoice_ID','Vendor Invoice',90,'Y','Y','N',90,'Y');
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0012-4f01-8e15-000000000001','LastResult','Last Result',100,'Y','Y','N',100,'Y',2);
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0013-4f01-8e15-000000000001','ExtractedText','Extracted Text',105,'Y','Y','N',0,'N',10);
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0019-4f01-8e15-000000000001','AbERP_UploadPDF','Upload PDF',110,'Y','N','N',NULL,'N');
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0014-4f01-8e15-000000000001','AbERP_ProcessSelected','Process',120,'Y','N','Y',NULL,'N');
  -- Hidden legacy / system fields (still present for attachments / batch File Path)
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0005-4f01-8e15-000000000001','FilePath','File Path',900,'N','N','N',0,'N');
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0008-4f01-8e15-000000000001','TaxID','Tax ID',910,'N','N','N',0,'N');
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0015-4f01-8e15-000000000001','IsActive','Active',930,'N','N','N',0,'N');
  PERFORM pg_temp.saw019_field(v_tab1_id,'19a019f0-0016-4f01-8e15-000000000001','Processed','Processed',940,'N','Y','N',0,'N');

  -- Fine-tune positions/spans (helper defaults columnspan=2 / xposition=1)
  UPDATE ad_field f SET
    xposition = CASE c.columnname
      WHEN 'CaptureStatus' THEN 4 WHEN 'C_Order_ID' THEN 4 WHEN 'InvoiceDate' THEN 4
      WHEN 'AbERP_UploadPDF' THEN 2 WHEN 'AbERP_ProcessSelected' THEN 3 ELSE 1 END,
    columnspan = CASE c.columnname
      WHEN 'Name' THEN 5 WHEN 'LastResult' THEN 5 WHEN 'ExtractedText' THEN 5 WHEN 'C_Invoice_ID' THEN 5
      WHEN 'AbERP_UploadPDF' THEN 1 WHEN 'AbERP_ProcessSelected' THEN 1 ELSE 2 END,
    displaylength = CASE c.columnname
      WHEN 'AbERP_UploadPDF' THEN 14 WHEN 'AbERP_ProcessSelected' THEN 18
      WHEN 'LastResult' THEN 60 WHEN 'ExtractedText' THEN 80 ELSE f.displaylength END,
    displaylogic = CASE c.columnname
      WHEN 'ExtractedText' THEN '@Processed@=Y' ELSE f.displaylogic END,
    iscentrallymaintained = CASE WHEN c.columnname IN ('AbERP_UploadPDF','AbERP_ProcessSelected') THEN 'N' ELSE f.iscentrallymaintained END,
    updated = NOW()
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab1_id AND f.ad_column_id = c.ad_column_id;

  -- Log fields
  PERFORM pg_temp.saw019_field(v_tab2_id,'19a019f1-0000-4f01-8e15-000000000001','AbERP_InvoiceCaptureLog_ID','Invoice Capture Log',0,'N','Y','N',0,'N');
  PERFORM pg_temp.saw019_field(v_tab2_id,'19a019f1-0001-4f01-8e15-000000000001','ProcessedAt','Processed At',10,'Y','Y', 'N',10,'Y');
  PERFORM pg_temp.saw019_field(v_tab2_id,'19a019f1-0002-4f01-8e15-000000000001','TriggerType','Trigger',20,'Y','Y', 'Y',20,'Y');
  PERFORM pg_temp.saw019_field(v_tab2_id,'19a019f1-0003-4f01-8e15-000000000001','ResultCode','Result Code',30,'Y','Y', 'N',30,'Y');
  PERFORM pg_temp.saw019_field(v_tab2_id,'19a019f1-0004-4f01-8e15-000000000001','Message','Message',40,'Y','Y', 'N',40,'Y', 3);
  PERFORM pg_temp.saw019_field(v_tab2_id,'19a019f1-0005-4f01-8e15-000000000001','C_Invoice_ID','Vendor Invoice',50,'Y','Y', 'N',50,'Y');

  RAISE NOTICE 'SAW019 window=% tab1=% tab2=%', v_window_id, v_tab1_id, v_tab2_id;
END $$;
