-- =============================================================================
-- SAW019 — Fix display logic so Document / Capture Status / Last Result show
-- Nested (@Processed@=Y | (...)) was evaluating false in ZK (fields stayed
-- display:none) while Process with a simpler expression worked.
-- Use: @LastResult@!'' | @Processed@=Y
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_tab INTEGER;
  v_s23 CONSTANT TEXT := '@LastResult@!'''' | @Processed@=Y';
  v_s2  CONSTANT TEXT := '@Processed@=N & @LastResult@!''''';
  v_s1  CONSTANT TEXT := '@Processed@=N & @LastResult@=''''';
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
    displaylogic = CASE c.columnname
      WHEN 'Name' THEN '@Processed@=N & @LastResult@='''' | @Processed@=Y'
      WHEN 'AbERP_UploadPDF' THEN v_s1
      WHEN 'DocumentNo' THEN v_s23
      WHEN 'CaptureStatus' THEN v_s23
      WHEN 'LastResult' THEN v_s23
      WHEN 'AbERP_ProcessSelected' THEN v_s2
      WHEN 'C_BPartner_ID' THEN '@Processed@=Y'
      WHEN 'C_Order_ID' THEN '@Processed@=Y'
      WHEN 'VendorInvoiceNo' THEN '@Processed@=Y'
      WHEN 'InvoiceDate' THEN '@Processed@=Y'
      WHEN 'GrandTotal' THEN '@Processed@=Y'
      WHEN 'C_Invoice_ID' THEN '@Processed@=Y'
      WHEN 'ExtractedText' THEN '@Processed@=Y'
      ELSE f.displaylogic
    END,
    -- Keep Capture Status on Document row next to Document No
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
    updated = NOW(),
    updatedby = 100
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab
    AND f.ad_column_id = c.ad_column_id;

  RAISE NOTICE 'SAW019 display logic simplified (tab=%): Document/Status/LastResult use @LastResult@!'''' | @Processed@=Y', v_tab;
END $$;
