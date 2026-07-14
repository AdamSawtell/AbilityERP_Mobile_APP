-- =============================================================================
-- SAW016 — (legacy) Harden flags after location work
-- UX for criteria display types is owned by sql/25-restore-criteria-dropdowns.sql.
-- This script only clears Multi Select leftovers; do NOT set Search(30) here.
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_iw INTEGER;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001';
  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'SAW016: Leave Planning Info Window missing';
  END IF;

  UPDATE ad_infocolumn SET
    ismultiselectcriteria = 'N',
    defaultvalue = NULL,
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND COALESCE(ismultiselectcriteria, 'N') = 'Y';

  -- Ensure Support Location label if column present (display type set in 25)
  UPDATE ad_infocolumn SET
    name = 'Support Location',
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND columnname IN ('C_BPartner_Location_ID', 'AbERP_LP_ServiceLocation');

  RAISE NOTICE 'SAW016: multiselect cleared; run sql/25 for dropdown display types';
END $$;
