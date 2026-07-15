-- =============================================================================
-- SAW019 — Prefer open-to-invoice Purchase Orders in Search / val rule
-- Tighten AbERP Purchase Order table ref + vendor val rule.
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_ref_uu CONSTANT TEXT := '19a0190c-c0d4-4f01-8e15-000000000001';
  v_vr_uu CONSTANT TEXT := '19a0190d-c0d4-4f01-8e15-000000000001';
  v_open_po TEXT :=
    'EXISTS (SELECT 1 FROM C_OrderLine ol WHERE ol.C_Order_ID=C_Order.C_Order_ID '
    || 'AND ol.IsActive=''Y'' AND ol.QtyOrdered > COALESCE(ol.QtyInvoiced,0))';
  v_ref_where TEXT;
  v_vr_code TEXT;
  v_ref INTEGER;
  v_vr INTEGER;
BEGIN
  v_ref_where :=
    'C_Order.IsSOTrx=''N'' AND C_Order.DocStatus IN (''CO'',''CL'') AND ' || v_open_po;
  v_vr_code :=
    'C_Order.IsSOTrx=''N'' AND C_Order.DocStatus IN (''CO'',''CL'') AND C_Order.IsActive=''Y'' '
    || 'AND (@C_BPartner_ID@=0 OR C_Order.C_BPartner_ID=@C_BPartner_ID@) AND ' || v_open_po;

  SELECT ad_reference_id INTO v_ref FROM ad_reference WHERE ad_reference_uu = v_ref_uu;
  IF v_ref IS NULL THEN
    SELECT ad_reference_id INTO v_ref FROM ad_reference WHERE name = 'AbERP Purchase Order' LIMIT 1;
  END IF;
  IF v_ref IS NULL THEN
    RAISE EXCEPTION 'SAW019: AbERP Purchase Order reference missing — run 14-add-po-link.sql first';
  END IF;

  UPDATE ad_ref_table SET
    whereclause = v_ref_where,
    updated = NOW()
  WHERE ad_reference_id = v_ref;

  SELECT ad_val_rule_id INTO v_vr FROM ad_val_rule WHERE ad_val_rule_uu = v_vr_uu;
  IF v_vr IS NULL THEN
    SELECT ad_val_rule_id INTO v_vr FROM ad_val_rule WHERE name = 'AbERP PO by Vendor (Capture)' LIMIT 1;
  END IF;
  IF v_vr IS NULL THEN
    RAISE EXCEPTION 'SAW019: AbERP PO by Vendor (Capture) val rule missing — run 14-add-po-link.sql first';
  END IF;

  UPDATE ad_val_rule SET
    code = v_vr_code,
    description = 'Open (qty) purchase orders for the capture vendor (or all open POs if vendor blank)',
    updated = NOW()
  WHERE ad_val_rule_id = v_vr;
END $$;
