-- SAW017 — Yes/No process paras must use display type Yes-No (20), not list _YesNo (319).
-- Using 319 as ad_reference_id makes WebUI show raw Y/N textboxes instead of Yes/No controls.
SET search_path TO adempiere;

DO $$
DECLARE
  v_ref INTEGER;
BEGIN
  SELECT ad_reference_id INTO v_ref FROM ad_reference WHERE name = 'Yes-No' LIMIT 1;
  IF v_ref IS NULL THEN
    v_ref := 20;
  END IF;

  UPDATE ad_process_para pp
  SET ad_reference_id = v_ref,
      ad_reference_value_id = NULL,
      updated = NOW(),
      updatedby = 100
  FROM ad_process p
  WHERE p.ad_process_id = pp.ad_process_id
    AND p.ad_process_uu = '17a01701-b017-4017-8017-000000000001'
    AND pp.columnname IN ('AbERP_IncludeIrregular', 'AbERP_IncludeSTR', 'AbERP_ForceInvoiceRule');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Bulk Generate Bookings Yes/No paras missing';
  END IF;
END $$;
