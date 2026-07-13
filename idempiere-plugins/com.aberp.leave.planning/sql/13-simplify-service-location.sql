-- =============================================================================
-- SAW016 — Replace weird Multi Select Service Locations with optional single lookup
-- Blank = all locations. Multi Select Table + All/Any is cramped and can emit -1.
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_iw INTEGER;
  v_val_loc INTEGER;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001';
  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'SAW016: Leave Planning Info Window missing';
  END IF;

  SELECT ad_val_rule_id INTO v_val_loc
  FROM ad_val_rule
  WHERE ad_val_rule_uu = '16a01606-c0d4-4f01-8e15-000000000001';
  IF v_val_loc IS NULL THEN
    RAISE EXCEPTION 'SAW016: location val rule missing';
  END IF;

  UPDATE ad_infocolumn SET
    name = 'Service Location',
    description = 'Optional. Leave blank for all locations (role/org security still applies).',
    help = 'Pick one Partner Location to narrow results, or leave blank for all.',
    ad_reference_id = 19, -- Table Direct
    ad_reference_value_id = NULL,
    ad_val_rule_id = v_val_loc,
    ismultiselectcriteria = 'N',
    queryoperator = '=',
    isquerycriteria = 'Y',
    isdisplayed = 'N',
    ismandatory = 'N',
    seqnoselection = 30,
    selectclause = 'u.C_BPartner_Location_ID',
    columnname = 'C_BPartner_Location_ID',
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '16a016ic-0003-4f01-8e15-000000000001';

  UPDATE ad_infowindow SET
    help = 'Static query page: set Planning Start/End, optional Service Location (blank = all), then Search. '
      || 'Results refresh from the query — no planning document to save. '
      || 'Zoom a leave row to submit/approve with existing processes. '
      || 'For multi-location export, use Leave Planning Report or run Search per location.',
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw;

  RAISE NOTICE 'SAW016: Service Location simplified to optional Table Direct on InfoWindow %', v_iw;
END $$;
