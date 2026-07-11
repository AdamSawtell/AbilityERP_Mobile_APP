-- Add Paid (IsPaid) search criteria to Notification SR Invoice Send Info
-- AD_InfoWindow_UU = 8fb1cd46-ed81-4cb9-8b83-7662caed9e62 (ID 1000032)
--
-- Mirrors core Invoice Info (200003):
--   * Display column: Yes-No (20) — shows Paid in the result grid
--   * Criteria column: List (17) + _YesNo (319) — Yes / No / blank (no filter)
-- Uses existing C_Invoice.IsPaid via FROM alias i (fromclause = 'C_Invoice i').
-- No default — blank means both paid and unpaid.

SET search_path TO adempiere;

DO $$
DECLARE
  v_iw NUMERIC;
  v_element NUMERIC := 1402; -- AD_Element IsPaid / Paid
  v_uu_display CONSTANT VARCHAR := 'a8f3c2e1-9b47-4d6a-8e15-2c7f9a1b4d03';
  v_uu_criteria CONSTANT VARCHAR := 'b7e4d3f2-0c58-4e7b-9f26-3d8a0b2c5e14';
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '8fb1cd46-ed81-4cb9-8b83-7662caed9e62';

  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'AD_InfoWindow UU 8fb1cd46-ed81-4cb9-8b83-7662caed9e62 not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM ad_infowindow
    WHERE ad_infowindow_id = v_iw
      AND fromclause ILIKE '%C_Invoice%i%'
  ) THEN
    RAISE EXCEPTION 'AD_InfoWindow % FROM clause does not expose C_Invoice alias i', v_iw;
  END IF;

  -- Display: Paid in result grid (Yes-No)
  IF EXISTS (SELECT 1 FROM ad_infocolumn WHERE ad_infocolumn_uu = v_uu_display) THEN
    UPDATE ad_infocolumn SET
      name = 'Paid',
      description = 'The document is paid (C_Invoice.IsPaid)',
      help = 'Shows whether the invoice is paid. Filter with the Paid search parameter (Yes / No / blank).',
      ad_infowindow_id = v_iw,
      entitytype = 'Ab_ERP',
      selectclause = 'i.IsPaid',
      seqno = 135,
      isdisplayed = 'Y',
      isquerycriteria = 'N',
      ad_element_id = v_element,
      ad_reference_id = 20,
      ad_reference_value_id = NULL,
      columnname = 'IsPaid',
      queryoperator = '=',
      queryfunction = NULL,
      isidentifier = 'N',
      seqnoselection = 0,
      defaultvalue = NULL,
      ismandatory = 'N',
      iskey = 'N',
      isreadonly = 'Y',
      ishideinfocolumn = 'N',
      ismultiselectcriteria = 'N',
      isactive = 'Y',
      iscentrallymaintained = 'Y',
      updated = NOW(),
      updatedby = 100
    WHERE ad_infocolumn_uu = v_uu_display;
  ELSE
    INSERT INTO ad_infocolumn (
      ad_infocolumn_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, help, ad_infowindow_id, entitytype, selectclause, seqno,
      isdisplayed, isquerycriteria, ad_element_id, ad_reference_id, ad_infocolumn_uu,
      ad_reference_value_id, columnname, queryoperator, isidentifier, seqnoselection,
      defaultvalue, ismandatory, iskey, isreadonly, ishideinfocolumn, ismultiselectcriteria,
      iscentrallymaintained
    ) VALUES (
      nextid((SELECT ad_sequence_id::integer FROM ad_sequence WHERE name = 'AD_InfoColumn' AND istableid = 'Y' LIMIT 1), 'N'::varchar),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Paid', 'The document is paid (C_Invoice.IsPaid)',
      'Shows whether the invoice is paid. Filter with the Paid search parameter (Yes / No / blank).',
      v_iw, 'Ab_ERP', 'i.IsPaid', 135,
      'Y', 'N', v_element, 20, v_uu_display,
      NULL, 'IsPaid', '=', 'N', 0,
      NULL, 'N', 'N', 'Y', 'N', 'N',
      'Y'
    );
  END IF;

  -- Criteria: Paid Yes / No / blank (List _YesNo) — blank = no payment-status filter
  IF EXISTS (SELECT 1 FROM ad_infocolumn WHERE ad_infocolumn_uu = v_uu_criteria) THEN
    UPDATE ad_infocolumn SET
      name = 'Paid',
      description = 'The document is paid (C_Invoice.IsPaid)',
      help = 'Yes = paid only (IsPaid=Y). No = unpaid only (IsPaid=N). Leave blank to include both.',
      ad_infowindow_id = v_iw,
      entitytype = 'Ab_ERP',
      selectclause = 'i.IsPaid',
      seqno = 145,
      isdisplayed = 'N',
      isquerycriteria = 'Y',
      ad_element_id = v_element,
      ad_reference_id = 17,
      ad_reference_value_id = 319, -- _YesNo
      columnname = 'IsPaid',
      queryoperator = '=',
      queryfunction = NULL,
      isidentifier = 'N',
      seqnoselection = 95,
      defaultvalue = NULL,
      ismandatory = 'N',
      iskey = 'N',
      isreadonly = 'N',
      ishideinfocolumn = 'N',
      ismultiselectcriteria = 'N',
      isactive = 'Y',
      iscentrallymaintained = 'Y',
      updated = NOW(),
      updatedby = 100
    WHERE ad_infocolumn_uu = v_uu_criteria;
  ELSE
    INSERT INTO ad_infocolumn (
      ad_infocolumn_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, help, ad_infowindow_id, entitytype, selectclause, seqno,
      isdisplayed, isquerycriteria, ad_element_id, ad_reference_id, ad_infocolumn_uu,
      ad_reference_value_id, columnname, queryoperator, isidentifier, seqnoselection,
      defaultvalue, ismandatory, iskey, isreadonly, ishideinfocolumn, ismultiselectcriteria,
      iscentrallymaintained
    ) VALUES (
      nextid((SELECT ad_sequence_id::integer FROM ad_sequence WHERE name = 'AD_InfoColumn' AND istableid = 'Y' LIMIT 1), 'N'::varchar),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Paid', 'The document is paid (C_Invoice.IsPaid)',
      'Yes = paid only (IsPaid=Y). No = unpaid only (IsPaid=N). Leave blank to include both.',
      v_iw, 'Ab_ERP', 'i.IsPaid', 145,
      'N', 'Y', v_element, 17, v_uu_criteria,
      319, 'IsPaid', '=', 'N', 95,
      NULL, 'N', 'N', 'N', 'N', 'N',
      'Y'
    );
  END IF;

  UPDATE ad_infowindow SET
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw;

  RAISE NOTICE 'Paid filter added to AD_InfoWindow_ID=% (display %, criteria %)',
    v_iw, v_uu_display, v_uu_criteria;
END $$;
