-- =============================================================================
-- SAW016 — Restore criteria as dropdowns (not Search / Info Windows)
-- Symptom: Unavailability Type + Employee + Support Location opened Info lookups.
-- Cause: sql/24 set Search(30); Employee was Search from 11-info seed.
-- Target: Table Direct (19) / Table (18) comboboxes like leave record fields.
-- Non-neg Intbox: rely on JAR sanitize/hide All-Any (not Search).
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_iw INTEGER;
  v_val INTEGER;
  v_ref_user INTEGER := 110; -- AD_User (Table) — stable core
  v_ref_approver INTEGER;
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
    RAISE EXCEPTION 'SAW016: Support Location val rule missing (run 18 first)';
  END IF;

  SELECT ad_reference_id INTO v_ref_approver
  FROM ad_reference
  WHERE name = 'AbERP_ApproverStatus_List'
  LIMIT 1;

  -- Support Location: Table Direct dropdown + active Support Location val rule
  UPDATE ad_infocolumn SET
    name = 'Support Location',
    ad_reference_id = 19,              -- Table Direct
    ad_reference_value_id = NULL,
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

  -- Approver Status: List dropdown (unchanged intent)
  IF v_ref_approver IS NOT NULL THEN
    UPDATE ad_infocolumn SET
      ad_reference_id = 17,
      ad_reference_value_id = v_ref_approver,
      ismultiselectcriteria = 'N',
      updated = NOW(), updatedby = 100
    WHERE ad_infowindow_id = v_iw
      AND columnname = 'AbERP_ApproverStatus'
      AND isquerycriteria = 'Y';
  END IF;

  -- Unavailability Type: Table ref dropdown (qualified WHERE) — not Search, not bare Table Direct
  SELECT ad_reference_id INTO v_ref_type
  FROM ad_reference
  WHERE name = 'AbERP Leave Planning Unavailability Type'
  ORDER BY ad_reference_id DESC
  LIMIT 1;
  IF v_ref_type IS NOT NULL THEN
    UPDATE ad_infocolumn SET
      ad_reference_id = 18,
      ad_reference_value_id = v_ref_type,
      ismultiselectcriteria = 'N',
      defaultvalue = NULL,
      updated = NOW(), updatedby = 100
    WHERE ad_infowindow_id = v_iw
      AND columnname = 'AbERP_Unavailability_Type_ID'
      AND isquerycriteria = 'Y';
  ELSE
    UPDATE ad_infocolumn SET
      ad_reference_id = 19,
      ad_reference_value_id = NULL,
      ismultiselectcriteria = 'N',
      defaultvalue = NULL,
      updated = NOW(), updatedby = 100
    WHERE ad_infowindow_id = v_iw
      AND columnname = 'AbERP_Unavailability_Type_ID'
      AND isquerycriteria = 'Y';
  END IF;

  -- Employee: Table dropdown on AD_User — NOT Search Info (1000191)
  UPDATE ad_infocolumn SET
    ad_reference_id = 18,              -- Table
    ad_reference_value_id = v_ref_user,
    ismultiselectcriteria = 'N',
    defaultvalue = NULL,
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND columnname = 'AbERP_User_Contact_ID'
    AND isquerycriteria = 'Y';

  -- Grid Supervisor stays Search (display lookup only) — leave alone

  RAISE NOTICE 'SAW016: criteria restored to dropdowns (Support Loc 19, Type 19, Employee 18/AD_User)';
END $$;

SELECT ic.columnname, ic.name, ic.ad_reference_id, r.name AS display_type,
       ic.ad_reference_value_id, rv.name AS refval, ic.isquerycriteria
FROM ad_infocolumn ic
JOIN ad_infowindow iw ON iw.ad_infowindow_id = ic.ad_infowindow_id
LEFT JOIN ad_reference r ON r.ad_reference_id = ic.ad_reference_id
LEFT JOIN ad_reference rv ON rv.ad_reference_id = ic.ad_reference_value_id
WHERE iw.ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001'
  AND ic.isquerycriteria = 'Y'
ORDER BY ic.seqnoselection, ic.seqno;
