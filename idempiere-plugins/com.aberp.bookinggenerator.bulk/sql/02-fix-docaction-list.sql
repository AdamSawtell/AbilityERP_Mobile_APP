-- SAW017 — DocAction must use BookingGen_DocList (includes DR), not _Document Action (135).
SET search_path TO adempiere;

DO $$
DECLARE
  v_ref INTEGER;
BEGIN
  SELECT ad_reference_id INTO v_ref FROM ad_reference
  WHERE ad_reference_uu = '285220bc-9749-4c4b-978d-4674fad038cd'
     OR name = 'BookingGen_DocList'
  LIMIT 1;
  IF v_ref IS NULL THEN
    RAISE EXCEPTION 'BookingGen_DocList reference missing';
  END IF;

  UPDATE ad_process_para pp
  SET ad_reference_value_id = v_ref,
      defaultvalue = COALESCE(NULLIF(pp.defaultvalue, ''), 'DR'),
      updated = NOW(),
      updatedby = 100
  FROM ad_process p
  WHERE p.ad_process_id = pp.ad_process_id
    AND p.ad_process_uu = '17a01701-b017-4017-8017-000000000001'
    AND pp.columnname = 'DocAction';

  UPDATE ad_process_para pp
  SET ismandatory = 'N',
      updated = NOW(),
      updatedby = 100
  FROM ad_process p
  WHERE p.ad_process_id = pp.ad_process_id
    AND p.ad_process_uu = '17a01701-b017-4017-8017-000000000001'
    AND pp.columnname IN ('AbERP_IncludeIrregular', 'AbERP_IncludeSTR', 'AbERP_ForceInvoiceRule');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Bulk Generate Bookings DocAction para missing';
  END IF;
END $$;
