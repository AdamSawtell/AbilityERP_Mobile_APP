-- =============================================================================
-- SAW019 — AD Table + Columns (capture + log)
-- Table UU: 19a01901-c0d4-4f01-8e15-000000000001
-- Log UU:   19a01902-c0d4-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_table_id),0)+1 FROM ad_table))
WHERE name='AD_Table' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_reference_id),0)+1 FROM ad_reference))
WHERE name='AD_Reference' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw019_col(
  p_table_id INTEGER, p_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_ref INTEGER, p_ref_value INTEGER, p_mandatory CHAR, p_updateable CHAR,
  p_seqno INTEGER, p_fieldlength INTEGER,
  p_iskey CHAR DEFAULT 'N', p_isparent CHAR DEFAULT 'N', p_isidentifier CHAR DEFAULT 'N',
  p_isselection CHAR DEFAULT 'N', p_default TEXT DEFAULT NULL,
  p_istoolbar CHAR DEFAULT 'N', p_ad_process_id INTEGER DEFAULT NULL
) RETURNS void AS $$
DECLARE
  v_col_id INTEGER;
  v_el INTEGER;
BEGIN
  SELECT ad_element_id INTO v_el FROM ad_element WHERE columnname = p_columnname LIMIT 1;
  IF v_el IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_columnname, 'Ab_ERP', p_name, p_name,
      '19a01900-0000-4000-8000-' || lpad(substr(md5(p_columnname), 1, 12), 12, '0')
    ) RETURNING ad_element_id INTO v_el;
  END IF;

  SELECT ad_column_id INTO v_col_id FROM ad_column WHERE ad_column_uu = p_uu;
  IF v_col_id IS NULL THEN
    SELECT ad_column_id INTO v_col_id FROM ad_column
    WHERE ad_table_id = p_table_id AND columnname = p_columnname;
  END IF;

  IF v_col_id IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, version, entitytype, columnname, ad_table_id,
      ad_reference_id, ad_reference_value_id, ad_process_id,
      fieldlength, iskey, isparent, ismandatory, isupdateable,
      isidentifier, seqno, istranslated, isencrypted, isselectioncolumn,
      ad_element_id, issyncdatabase, isalwaysupdateable,
      isallowcopy, defaultvalue, istoolbarbutton, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, 0, 'Ab_ERP', p_columnname, p_table_id,
      p_ref, p_ref_value, p_ad_process_id,
      p_fieldlength, p_iskey, p_isparent, p_mandatory, p_updateable,
      p_isidentifier, p_seqno, 'N', 'N', p_isselection,
      v_el, 'Y', 'N',
      'Y', p_default, p_istoolbar, p_uu
    );
  ELSE
    UPDATE ad_column SET
      name = p_name,
      ad_reference_id = p_ref,
      ad_reference_value_id = p_ref_value,
      ad_process_id = COALESCE(p_ad_process_id, ad_process_id),
      fieldlength = p_fieldlength,
      ismandatory = p_mandatory,
      isupdateable = p_updateable,
      isidentifier = p_isidentifier,
      iskey = p_iskey,
      isparent = p_isparent,
      isselectioncolumn = p_isselection,
      defaultvalue = COALESCE(p_default, defaultvalue),
      istoolbarbutton = COALESCE(NULLIF(p_istoolbar, 'N'), istoolbarbutton),
      entitytype = 'Ab_ERP',
      ad_column_uu = COALESCE(ad_column_uu, p_uu),
      updated = NOW(),
      updatedby = 100
    WHERE ad_column_id = v_col_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_cap_uu CONSTANT TEXT := '19a01901-c0d4-4f01-8e15-000000000001';
  v_log_uu CONSTANT TEXT := '19a01902-c0d4-4f01-8e15-000000000001';
  v_status_ref INTEGER;
  v_inv_ref INTEGER;
  v_bp_ref INTEGER;
  v_cap_id INTEGER;
  v_log_id INTEGER;
BEGIN
  SELECT ad_reference_id INTO v_status_ref
  FROM ad_reference
  WHERE ad_reference_uu = '19a01907-c0d4-4f01-8e15-000000000001'
     OR name = 'AbERP_InvoiceCapture_Status'
  LIMIT 1;
  IF v_status_ref IS NULL THEN
    RAISE EXCEPTION 'SAW019: status reference missing — run 02-status-reference.sql first';
  END IF;

  -- Search C_Invoice
  SELECT ad_reference_id INTO v_inv_ref
  FROM ad_reference
  WHERE ad_reference_uu = '19a0190b-c0d4-4f01-8e15-000000000001';
  IF v_inv_ref IS NULL THEN
    INSERT INTO ad_reference (
      ad_reference_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, validationtype, entitytype, ad_reference_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Reference' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP Invoice Capture -> Invoice', 'Zoom to Vendor Invoice',
      'T', 'Ab_ERP', '19a0190b-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_reference_id INTO v_inv_ref;

    INSERT INTO ad_ref_table (
      ad_reference_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      ad_table_id, ad_key, ad_display, isvaluedisplayed, entitytype, whereclause, orderbyclause
    ) VALUES (
      v_inv_ref, 0, 0, 'Y', NOW(), 100, NOW(), 100,
      (SELECT ad_table_id FROM ad_table WHERE tablename = 'C_Invoice'),
      (SELECT ad_column_id FROM ad_column c JOIN ad_table t ON t.ad_table_id = c.ad_table_id
        WHERE t.tablename = 'C_Invoice' AND c.columnname = 'C_Invoice_ID'),
      (SELECT ad_column_id FROM ad_column c JOIN ad_table t ON t.ad_table_id = c.ad_table_id
        WHERE t.tablename = 'C_Invoice' AND c.columnname = 'DocumentNo'),
      'N', 'Ab_ERP', 'C_Invoice.IsSOTrx=''N''', 'DocumentNo DESC'
    );
  END IF;

  SELECT ad_reference_id INTO v_bp_ref
  FROM ad_reference WHERE name = 'C_BPartner Cust Vend' OR name = 'C_BPartner'
  LIMIT 1;

  -- Capture table
  SELECT ad_table_id INTO v_cap_id FROM ad_table WHERE ad_table_uu = v_cap_uu OR tablename = 'AbERP_InvoiceCapture' LIMIT 1;
  IF v_cap_id IS NULL THEN
    INSERT INTO ad_table (
      ad_table_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, tablename, isview, accesslevel, entitytype,
      issecurityenabled, isdeleteable, ishighvolume, importtable,
      ischangelog, replicationtype, ad_table_uu, iscentrallymaintained
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Table' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Invoice Capture', 'Vendor invoice PDF capture and processing',
      'AbERP_InvoiceCapture', 'N', '2', 'Ab_ERP',
      'N', 'Y', 'N', 'N',
      'Y', 'L', v_cap_uu, 'Y'
    ) RETURNING ad_table_id INTO v_cap_id;
  ELSE
    UPDATE ad_table SET
      name = 'Invoice Capture',
      tablename = 'AbERP_InvoiceCapture',
      entitytype = 'Ab_ERP',
      accesslevel = '2',
      ad_table_uu = COALESCE(ad_table_uu, v_cap_uu),
      updated = NOW()
    WHERE ad_table_id = v_cap_id;
  END IF;

  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0001-4f01-8e15-000000000001','AbERP_InvoiceCapture_ID','Invoice Capture',13,NULL,'Y','N',0,22,'Y','N','N');
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0002-4f01-8e15-000000000001','AD_Client_ID','Client',19,NULL,'Y','N',10,22);
  -- Default real org (login Org=* leaves a blank mandatory Organization and blocks Save)
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0003-4f01-8e15-000000000001','AD_Org_ID','Organization',19,NULL,'Y','Y',20,22,'N','N','N','N','@SQL=SELECT MIN(AD_Org_ID) FROM AD_Org WHERE AD_Client_ID=@#AD_Client_ID@ AND IsSummary=''N'' AND IsActive=''Y'' AND AD_Org_ID<>0');
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0004-4f01-8e15-000000000001','IsActive','Active',20,NULL,'Y','Y',30,1,'N','N','N','N','Y');
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0005-4f01-8e15-000000000001','Created','Created',16,NULL,'Y','N',40,7);
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0006-4f01-8e15-000000000001','CreatedBy','Created By',18,110,'Y','N',50,22);
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0007-4f01-8e15-000000000001','Updated','Updated',16,NULL,'Y','N',60,7);
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0008-4f01-8e15-000000000001','UpdatedBy','Updated By',18,110,'Y','N',70,22);
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0009-4f01-8e15-000000000001','AbERP_InvoiceCapture_UU','UU',10,NULL,'N','Y',80,36);
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0010-4f01-8e15-000000000001','DocumentNo','Document No',10,NULL,'N','Y',90,60, 'N','N','Y','Y');
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0011-4f01-8e15-000000000001','Name','Name',10,NULL,'N','Y',100,120, 'N','N','Y','Y');
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0012-4f01-8e15-000000000001','CaptureStatus','Capture Status',17,v_status_ref,'Y','Y',110,2, 'N','N','N','Y','PE');
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0013-4f01-8e15-000000000001','FilePath','File Path',10,NULL,'N','Y',120,1000);
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0014-4f01-8e15-000000000001','VendorInvoiceNo','Vendor Invoice No',10,NULL,'N','Y',130,60, 'N','N','N','Y');
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0015-4f01-8e15-000000000001','TaxID','Tax ID',10,NULL,'N','Y',140,40);
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0016-4f01-8e15-000000000001','InvoiceDate','Invoice Date',15,NULL,'N','Y',150,7);
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0017-4f01-8e15-000000000001','GrandTotal','Grand Total',12,NULL,'N','Y',160,22);
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0018-4f01-8e15-000000000001','C_BPartner_ID','Business Partner',30,v_bp_ref,'N','Y',170,22, 'N','N','N','Y');
  -- Writable by service (UI fields stay read-only via AD_Field.IsReadOnly)
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0019-4f01-8e15-000000000001','C_Invoice_ID','Vendor Invoice',30,v_inv_ref,'N','Y',180,22, 'N','N','N','Y');
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0020-4f01-8e15-000000000001','ExtractedText','Extracted Text',14,NULL,'N','Y',190,4000);
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0021-4f01-8e15-000000000001','LastResult','Last Result',10,NULL,'N','Y',200,255);
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0022-4f01-8e15-000000000001','Processed','Processed',20,NULL,'N','Y',210,1, 'N','N','N','N','N');
  -- Button (process linked in 05)
  PERFORM pg_temp.saw019_col(v_cap_id,'19a019c0-0023-4f01-8e15-000000000001','AbERP_ProcessSelected','Process Selected Invoice',28,NULL,'N','Y',220,1, 'N','N','N','N',NULL,'B');

  -- Log table
  SELECT ad_table_id INTO v_log_id FROM ad_table WHERE ad_table_uu = v_log_uu OR tablename = 'AbERP_InvoiceCaptureLog' LIMIT 1;
  IF v_log_id IS NULL THEN
    INSERT INTO ad_table (
      ad_table_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, tablename, isview, accesslevel, entitytype,
      issecurityenabled, isdeleteable, ishighvolume, importtable,
      ischangelog, replicationtype, ad_table_uu, iscentrallymaintained
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Table' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Invoice Capture Log', 'Append-only processing attempts',
      'AbERP_InvoiceCaptureLog', 'N', '3', 'Ab_ERP',
      'N', 'Y', 'N', 'N',
      'Y', 'L', v_log_uu, 'Y'
    ) RETURNING ad_table_id INTO v_log_id;
  END IF;

  PERFORM pg_temp.saw019_col(v_log_id,'19a019l0-0001-4f01-8e15-000000000001','AbERP_InvoiceCaptureLog_ID','Invoice Capture Log',13,NULL,'Y','N',0,22,'Y');
  PERFORM pg_temp.saw019_col(v_log_id,'19a019l0-0002-4f01-8e15-000000000001','AD_Client_ID','Client',19,NULL,'Y','N',10,22);
  PERFORM pg_temp.saw019_col(v_log_id,'19a019l0-0003-4f01-8e15-000000000001','AD_Org_ID','Organization',19,NULL,'Y','N',20,22);
  PERFORM pg_temp.saw019_col(v_log_id,'19a019l0-0004-4f01-8e15-000000000001','IsActive','Active',20,NULL,'Y','Y',30,1);
  PERFORM pg_temp.saw019_col(v_log_id,'19a019l0-0005-4f01-8e15-000000000001','Created','Created',16,NULL,'Y','N',40,7);
  PERFORM pg_temp.saw019_col(v_log_id,'19a019l0-0006-4f01-8e15-000000000001','CreatedBy','Created By',18,110,'Y','N',50,22);
  PERFORM pg_temp.saw019_col(v_log_id,'19a019l0-0007-4f01-8e15-000000000001','Updated','Updated',16,NULL,'Y','N',60,7);
  PERFORM pg_temp.saw019_col(v_log_id,'19a019l0-0008-4f01-8e15-000000000001','UpdatedBy','Updated By',18,110,'Y','N',70,22);
  PERFORM pg_temp.saw019_col(v_log_id,'19a019l0-0009-4f01-8e15-000000000001','AbERP_InvoiceCaptureLog_UU','UU',10,NULL,'N','Y',80,36);
  PERFORM pg_temp.saw019_col(v_log_id,'19a019l0-0010-4f01-8e15-000000000001','AbERP_InvoiceCapture_ID','Invoice Capture',19,NULL,'Y','N',90,22,'N','Y');
  PERFORM pg_temp.saw019_col(v_log_id,'19a019l0-0011-4f01-8e15-000000000001','ProcessedAt','Processed At',16,NULL,'Y','N',100,7);
  PERFORM pg_temp.saw019_col(v_log_id,'19a019l0-0012-4f01-8e15-000000000001','ResultCode','Result Code',10,NULL,'N','N',110,40);
  PERFORM pg_temp.saw019_col(v_log_id,'19a019l0-0013-4f01-8e15-000000000001','Message','Message',14,NULL,'N','N',120,2000);
  PERFORM pg_temp.saw019_col(v_log_id,'19a019l0-0014-4f01-8e15-000000000001','TriggerType','Trigger',10,NULL,'N','N',130,20);
  PERFORM pg_temp.saw019_col(v_log_id,'19a019l0-0015-4f01-8e15-000000000001','C_Invoice_ID','Vendor Invoice',30,v_inv_ref,'N','N',140,22);

  RAISE NOTICE 'SAW019 AD tables ready capture=% log=%', v_cap_id, v_log_id;
END $$;
