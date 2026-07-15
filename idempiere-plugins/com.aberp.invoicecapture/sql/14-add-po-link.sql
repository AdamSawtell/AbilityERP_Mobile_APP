-- =============================================================================
-- SAW019 — Link Invoice Capture to Purchase Order (C_Order)
-- Physical column + AD field; Purchase Order Search filtered to PO docs.
-- Fixed UUs:
--   Table ref  19a0190c-c0d4-4f01-8e15-000000000001
--   Val rule   19a0190d-c0d4-4f01-8e15-000000000001
--   Column     19a019c0-0025-4f01-8e15-000000000001  (0024 already used by AbERP_UploadPDF)
--   Field      19a019f0-0018-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

ALTER TABLE aberp_invoicecapture
  ADD COLUMN IF NOT EXISTS c_order_id numeric(10);

CREATE INDEX IF NOT EXISTS aberp_invoicecapture_order_idx
  ON aberp_invoicecapture (c_order_id)
  WHERE c_order_id IS NOT NULL;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_reference_id),0)+1 FROM ad_reference))
WHERE name='AD_Reference' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_val_rule_id),0)+1 FROM ad_val_rule))
WHERE name='AD_Val_Rule' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';

DO $$
DECLARE
  v_cap_table INTEGER;
  v_tab INTEGER;
  v_ref_uu CONSTANT TEXT := '19a0190c-c0d4-4f01-8e15-000000000001';
  v_vr_uu CONSTANT TEXT := '19a0190d-c0d4-4f01-8e15-000000000001';
  v_col_uu CONSTANT TEXT := '19a019c0-0025-4f01-8e15-000000000001';
  v_field_uu CONSTANT TEXT := '19a019f0-0018-4f01-8e15-000000000001';
  v_ref INTEGER;
  v_vr INTEGER;
  v_col INTEGER;
  v_field INTEGER;
  v_el INTEGER;
  v_order_table INTEGER;
  v_key_col INTEGER;
  v_disp_col INTEGER;
BEGIN
  SELECT ad_table_id INTO v_cap_table FROM ad_table WHERE tablename = 'AbERP_InvoiceCapture';
  IF v_cap_table IS NULL THEN
    RAISE EXCEPTION 'SAW019: AbERP_InvoiceCapture table missing';
  END IF;

  SELECT t.ad_tab_id INTO v_tab
  FROM ad_tab t
  JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
  WHERE tb.tablename = 'AbERP_InvoiceCapture' AND t.seqno = 10
  LIMIT 1;
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'SAW019: Invoice Capture tab missing';
  END IF;

  SELECT ad_table_id INTO v_order_table FROM ad_table WHERE tablename = 'C_Order';
  SELECT ad_column_id INTO v_key_col FROM ad_column
  WHERE ad_table_id = v_order_table AND columnname = 'C_Order_ID';
  SELECT ad_column_id INTO v_disp_col FROM ad_column
  WHERE ad_table_id = v_order_table AND columnname = 'DocumentNo';

  -- Purchase Order Search reference (PO only)
  SELECT ad_reference_id INTO v_ref FROM ad_reference WHERE ad_reference_uu = v_ref_uu;
  IF v_ref IS NULL THEN
    SELECT ad_reference_id INTO v_ref FROM ad_reference WHERE name = 'AbERP Purchase Order' LIMIT 1;
  END IF;
  IF v_ref IS NULL THEN
    INSERT INTO ad_reference (
      ad_reference_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, validationtype, entitytype, ad_reference_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Reference' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP Purchase Order', 'Purchase orders (IsSOTrx=N) for Invoice Capture',
      'T', 'Ab_ERP', v_ref_uu
    ) RETURNING ad_reference_id INTO v_ref;

    INSERT INTO ad_ref_table (
      ad_reference_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      ad_table_id, ad_key, ad_display, isvaluedisplayed, entitytype,
      whereclause, orderbyclause
    ) VALUES (
      v_ref, 0, 0, 'Y', NOW(), 100, NOW(), 100,
      v_order_table, v_key_col, v_disp_col, 'N', 'Ab_ERP',
      'C_Order.IsSOTrx=''N'' AND C_Order.DocStatus IN (''CO'',''CL'') AND EXISTS (SELECT 1 FROM C_OrderLine ol WHERE ol.C_Order_ID=C_Order.C_Order_ID AND ol.IsActive=''Y'' AND ol.QtyOrdered > COALESCE(ol.QtyInvoiced,0))',
      'DocumentNo DESC'
    );
  END IF;

  SELECT ad_val_rule_id INTO v_vr FROM ad_val_rule WHERE ad_val_rule_uu = v_vr_uu;
  IF v_vr IS NULL THEN
    SELECT ad_val_rule_id INTO v_vr FROM ad_val_rule WHERE name = 'AbERP PO by Vendor (Capture)' LIMIT 1;
  END IF;
  IF v_vr IS NULL THEN
    INSERT INTO ad_val_rule (
      ad_val_rule_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, type, code, entitytype, ad_val_rule_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Val_Rule' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP PO by Vendor (Capture)',
      'Purchase orders for the capture vendor (or all POs if vendor blank)',
      'S',
      'C_Order.IsSOTrx=''N'' AND C_Order.DocStatus IN (''CO'',''CL'') AND C_Order.IsActive=''Y'' AND (@C_BPartner_ID@=0 OR C_Order.C_BPartner_ID=@C_BPartner_ID@) AND EXISTS (SELECT 1 FROM C_OrderLine ol WHERE ol.C_Order_ID=C_Order.C_Order_ID AND ol.IsActive=''Y'' AND ol.QtyOrdered > COALESCE(ol.QtyInvoiced,0))',
      'Ab_ERP', v_vr_uu
    ) RETURNING ad_val_rule_id INTO v_vr;
  ELSE
    UPDATE ad_val_rule SET
      code = 'C_Order.IsSOTrx=''N'' AND C_Order.DocStatus IN (''CO'',''CL'') AND C_Order.IsActive=''Y'' AND (@C_BPartner_ID@=0 OR C_Order.C_BPartner_ID=@C_BPartner_ID@) AND EXISTS (SELECT 1 FROM C_OrderLine ol WHERE ol.C_Order_ID=C_Order.C_Order_ID AND ol.IsActive=''Y'' AND ol.QtyOrdered > COALESCE(ol.QtyInvoiced,0))',
      description = 'Open (qty) purchase orders for the capture vendor (or all open POs if vendor blank)',
      updated = NOW()
    WHERE ad_val_rule_id = v_vr;
  END IF;

  SELECT ad_element_id INTO v_el FROM ad_element WHERE columnname = 'C_Order_ID' LIMIT 1;
  IF v_el IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'C_Order_ID', 'Ab_ERP', 'Purchase Order', 'Purchase Order',
      '19a01900-0000-4000-8000-' || lpad(substr(md5('C_Order_ID_capture'), 1, 12), 12, '0')
    ) RETURNING ad_element_id INTO v_el;
  END IF;

  -- Resolve by table+columnname first (avoid colliding with a reused UU on another column)
  SELECT ad_column_id INTO v_col FROM ad_column
  WHERE ad_table_id = v_cap_table AND columnname = 'C_Order_ID';
  IF v_col IS NULL THEN
    SELECT ad_column_id INTO v_col FROM ad_column WHERE ad_column_uu = v_col_uu
      AND ad_table_id = v_cap_table AND columnname = 'C_Order_ID';
  END IF;

  IF v_col IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, version, entitytype, columnname, ad_table_id,
      ad_reference_id, ad_reference_value_id, ad_val_rule_id,
      fieldlength, iskey, isparent, ismandatory, isupdateable,
      isidentifier, seqno, istranslated, isencrypted, isselectioncolumn,
      ad_element_id, issyncdatabase, isalwaysupdateable,
      isallowcopy, istoolbarbutton, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Purchase Order', 0, 'Ab_ERP', 'C_Order_ID', v_cap_table,
      30, v_ref, v_vr,
      22, 'N', 'N', 'N', 'Y',
      'N', 175, 'N', 'N', 'Y',
      v_el, 'Y', 'N',
      'Y', 'N', v_col_uu
    ) RETURNING ad_column_id INTO v_col;
  ELSE
    UPDATE ad_column SET
      name = 'Purchase Order',
      ad_reference_id = 30,
      ad_reference_value_id = v_ref,
      ad_val_rule_id = v_vr,
      isupdateable = 'Y',
      isselectioncolumn = 'Y',
      seqno = 175,
      entitytype = 'Ab_ERP',
      ad_column_uu = COALESCE(ad_column_uu, v_col_uu),
      updated = NOW()
    WHERE ad_column_id = v_col;
  END IF;

  SELECT ad_field_id INTO v_field FROM ad_field
  WHERE ad_tab_id = v_tab AND ad_column_id = v_col;
  IF v_field IS NULL THEN
    SELECT ad_field_id INTO v_field FROM ad_field
    WHERE ad_field_uu = v_field_uu AND ad_tab_id = v_tab;
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
      'Purchase Order', 'Y', v_tab, v_col,
      'Y', 0, 'N', 65, 'N',
      'N', 'N', 'N', 'Ab_ERP',
      'Y', 65, 1, 2, 1, v_field_uu
    );
  ELSE
    UPDATE ad_field SET
      ad_column_id = v_col,
      name = 'Purchase Order',
      isdisplayed = 'Y',
      isreadonly = 'N',
      seqno = 65,
      isdisplayedgrid = 'Y',
      seqnogrid = 65,
      ad_field_uu = COALESCE(ad_field_uu, v_field_uu),
      updated = NOW()
    WHERE ad_field_id = v_field;
  END IF;

  RAISE NOTICE 'SAW019 PO link ready (ref=% valrule=% col=%)', v_ref, v_vr, v_col;
END $$;
