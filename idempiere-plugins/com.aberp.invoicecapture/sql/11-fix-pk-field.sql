-- =============================================================================
-- SAW019 — Fix missing PK fields (Record_ID / Attachment / button processes)
-- Without a tab field for the key column, WebUI leaves Record_ID=0 so:
--   Attachment stays disabled, Upload/Process say "Save the record first".
-- Fixed UUs:
--   Header PK  19a019f0-0000-4f01-8e15-000000000001
--   Log PK     19a019f1-0000-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';

DO $$
DECLARE
  v_tab1_uu CONSTANT TEXT := '19a01904-c0d4-4f01-8e15-000000000001';
  v_tab2_uu CONSTANT TEXT := '19a01905-c0d4-4f01-8e15-000000000001';
  v_hdr_pk_uu CONSTANT TEXT := '19a019f0-0000-4f01-8e15-000000000001';
  v_log_pk_uu CONSTANT TEXT := '19a019f1-0000-4f01-8e15-000000000001';
  v_tab1 INTEGER;
  v_tab2 INTEGER;
  v_col INTEGER;
  v_field INTEGER;
  v_table INTEGER;
BEGIN
  SELECT ad_tab_id INTO v_tab1 FROM ad_tab WHERE ad_tab_uu = v_tab1_uu;
  SELECT ad_tab_id INTO v_tab2 FROM ad_tab WHERE ad_tab_uu = v_tab2_uu;
  IF v_tab1 IS NULL THEN
    SELECT t.ad_tab_id INTO v_tab1
    FROM ad_tab t
    JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
    WHERE tb.tablename = 'AbERP_InvoiceCapture' AND t.seqno = 10
    LIMIT 1;
  END IF;
  IF v_tab2 IS NULL THEN
    SELECT t.ad_tab_id INTO v_tab2
    FROM ad_tab t
    JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
    WHERE tb.tablename = 'AbERP_InvoiceCaptureLog' AND t.seqno = 20
    LIMIT 1;
  END IF;
  IF v_tab1 IS NULL THEN
    RAISE EXCEPTION 'SAW019: Invoice Capture header tab missing';
  END IF;

  -- Header PK (hidden)
  SELECT ad_table_id INTO v_table FROM ad_tab WHERE ad_tab_id = v_tab1;
  SELECT ad_column_id INTO v_col FROM ad_column
  WHERE ad_table_id = v_table AND columnname = 'AbERP_InvoiceCapture_ID';
  IF v_col IS NULL THEN
    RAISE EXCEPTION 'SAW019: AbERP_InvoiceCapture_ID column missing';
  END IF;
  SELECT ad_field_id INTO v_field FROM ad_field WHERE ad_field_uu = v_hdr_pk_uu;
  IF v_field IS NULL THEN
    SELECT ad_field_id INTO v_field FROM ad_field
    WHERE ad_tab_id = v_tab1 AND ad_column_id = v_col;
  END IF;
  IF v_field IS NULL THEN
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
      'Invoice Capture', 'Y', v_tab1, v_col,
      'N', 14, 'Y', 0, 'N',
      'N', 'N', 'N', 'Ab_ERP',
      'N', 0, 1, 2, 1, v_hdr_pk_uu
    );
  ELSE
    UPDATE ad_field SET
      isdisplayed = 'N',
      isdisplayedgrid = 'N',
      isreadonly = 'Y',
      seqno = 0,
      ad_field_uu = COALESCE(ad_field_uu, v_hdr_pk_uu),
      updated = NOW()
    WHERE ad_field_id = v_field;
  END IF;

  -- Org must be updateable with login default (avoid * / org 0 rows)
  UPDATE ad_column SET
    isupdateable = 'Y',
    defaultvalue = '@#AD_Org_ID@',
    updated = NOW(),
    updatedby = 100
  WHERE ad_table_id = v_table AND columnname = 'AD_Org_ID';

  -- Columns written by InvoiceCaptureService must be updateable (UI can stay read-only)
  UPDATE ad_column SET
    isupdateable = 'Y',
    updated = NOW(),
    updatedby = 100
  WHERE ad_table_id = v_table
    AND columnname IN (
      'LastResult','ExtractedText','C_Invoice_ID','Processed',
      'C_BPartner_ID','VendorInvoiceNo','TaxID','InvoiceDate','GrandTotal',
      'CaptureStatus','FilePath','Name'
    );

  -- Log PK (hidden) if log tab exists
  IF v_tab2 IS NOT NULL THEN
    SELECT ad_table_id INTO v_table FROM ad_tab WHERE ad_tab_id = v_tab2;
    SELECT ad_column_id INTO v_col FROM ad_column
    WHERE ad_table_id = v_table AND columnname = 'AbERP_InvoiceCaptureLog_ID';
    IF v_col IS NOT NULL THEN
      SELECT ad_field_id INTO v_field FROM ad_field WHERE ad_field_uu = v_log_pk_uu;
      IF v_field IS NULL THEN
        SELECT ad_field_id INTO v_field FROM ad_field
        WHERE ad_tab_id = v_tab2 AND ad_column_id = v_col;
      END IF;
      IF v_field IS NULL THEN
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
          'Invoice Capture Log', 'Y', v_tab2, v_col,
          'N', 14, 'Y', 0, 'N',
          'N', 'N', 'N', 'Ab_ERP',
          'N', 0, 1, 2, 1, v_log_pk_uu
        );
      END IF;
    END IF;
  END IF;

  -- Repair smoke / orphan org=* capture rows when AbilityERP org exists
  UPDATE aberp_invoicecapture c
  SET ad_org_id = o.ad_org_id,
      updated = NOW(),
      updatedby = 100
  FROM ad_org o
  WHERE c.ad_org_id = 0
    AND o.ad_client_id = c.ad_client_id
    AND o.issummary = 'N'
    AND o.isactive = 'Y'
    AND o.value = 'AbilityERP';

  RAISE NOTICE 'SAW019 PK fields ready (header tab=%)', v_tab1;
END $$;
