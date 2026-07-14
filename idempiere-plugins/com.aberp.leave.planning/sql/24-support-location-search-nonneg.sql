-- =============================================================================
-- SAW016 — Kill Support Location "Only non-negative number is allowed"
-- Root: Table Direct Intbox holds -1 when blank / All-Any; ZK validates client-side
-- before server sanitizers run. Switch criteria to Search (Bandbox) + harden flags.
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_iw INTEGER;
  v_val INTEGER;
  v_ref_bpl INTEGER := 159; -- C_BPartner Location (stable core)
  v_ref_type INTEGER;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001';
  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'SAW016: Leave Planning Info Window missing';
  END IF;

  SELECT ad_val_rule_id INTO v_val
  FROM ad_val_rule
  WHERE ad_val_rule_uu = '16a01606-c0d4-4f01-8e15-000000000001';
  IF v_val IS NULL THEN
    RAISE EXCEPTION 'SAW016: Support Location val rule missing';
  END IF;

  SELECT ad_reference_id INTO v_ref_type
  FROM ad_reference
  WHERE name = 'AbERP Leave Planning Unavailability Type'
  ORDER BY ad_reference_id DESC
  LIMIT 1;

  -- Support Location: Search (30) not Table Direct (19) — avoids Intbox -1 popup
  UPDATE ad_infocolumn SET
    name = 'Support Location',
    ad_reference_id = 30,
    ad_reference_value_id = v_ref_bpl,
    ad_val_rule_id = v_val,
    ismultiselectcriteria = 'N',
    isquerycriteria = 'Y',
    isdisplayed = 'N',
    queryoperator = '=',
    defaultvalue = NULL,
    seqnoselection = 30,
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '16a016ic-0003-4f01-8e15-000000000001';

  -- Unavailability Type: Search if we have a Table ref (same Intbox risk when blank)
  IF v_ref_type IS NOT NULL THEN
    UPDATE ad_infocolumn SET
      ad_reference_id = 30,
      ad_reference_value_id = v_ref_type,
      ismultiselectcriteria = 'N',
      defaultvalue = NULL,
      updated = NOW(), updatedby = 100
    WHERE ad_infowindow_id = v_iw
      AND columnname = 'AbERP_Unavailability_Type_ID'
      AND isquerycriteria = 'Y';
  END IF;

  -- Display column label
  UPDATE ad_infocolumn SET
    name = 'Support Location',
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '16a016ic-0010-4f01-8e15-000000000001';

  -- No Multi Select leftovers on this Info Window
  UPDATE ad_infocolumn SET
    ismultiselectcriteria = 'N',
    defaultvalue = NULL,
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND COALESCE(ismultiselectcriteria, 'N') = 'Y';

  RAISE NOTICE 'SAW016: Support Location → Search(30)/ref 159; non-neg Intbox path removed';
END $$;

SELECT ic.columnname, ic.name, ic.ad_reference_id, ic.ad_reference_value_id,
       ic.ismultiselectcriteria, ic.isquerycriteria
FROM ad_infocolumn ic
JOIN ad_infowindow iw ON iw.ad_infowindow_id = ic.ad_infowindow_id
WHERE iw.ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001'
  AND ic.isquerycriteria = 'Y'
ORDER BY ic.seqnoselection, ic.seqno;
