-- =============================================================================
-- SAW016 — Fix Leave Planning Info: Service Locations + criteria layout
-- Root cause of "tiny box": Multi Select Table (200138) had no AD_Reference_Value
-- (needs Table ref C_BPartner Location = 159). Also drop bogus name criteria.
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_iw INTEGER;
  v_val_loc INTEGER;
  v_ref_bpl INTEGER := 159; -- C_BPartner Location (stable core Table reference)
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001';
  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'SAW016: Leave Planning Info Window UU 16a016iw-… missing — run 11-info-window.sql first';
  END IF;

  SELECT ad_val_rule_id INTO v_val_loc
  FROM ad_val_rule
  WHERE ad_val_rule_uu = '16a01606-c0d4-4f01-8e15-000000000001';
  IF v_val_loc IS NULL THEN
    RAISE EXCEPTION 'SAW016: location val rule UU 16a01606-… missing';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_reference WHERE ad_reference_id = v_ref_bpl AND name = 'C_BPartner Location') THEN
    RAISE EXCEPTION 'SAW016: core reference C_BPartner Location (159) missing';
  END IF;

  -- Service Locations: Multi Select Table + table ref + employee-location val rule
  UPDATE ad_infocolumn SET
    ad_reference_id = 200138,
    ad_reference_value_id = v_ref_bpl,
    ad_val_rule_id = v_val_loc,
    ismultiselectcriteria = 'Y',
    queryoperator = '<<<',
    isquerycriteria = 'Y',
    isdisplayed = 'N',
    ismandatory = 'N',
    seqnoselection = 30,
    name = 'Service Locations',
    description = 'Multi-select Partner Locations. Leave blank = all locations (role/org security still applies).',
    help = 'Pick one or more service locations, or leave empty for all. Results refresh on Search.',
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '16a016ic-0003-4f01-8e15-000000000001';

  IF NOT FOUND THEN
    UPDATE ad_infocolumn SET
      ad_reference_id = 200138,
      ad_reference_value_id = v_ref_bpl,
      ad_val_rule_id = v_val_loc,
      ismultiselectcriteria = 'Y',
      queryoperator = '<<<',
      isquerycriteria = 'Y',
      isdisplayed = 'N',
      seqnoselection = 30,
      updated = NOW(), updatedby = 100
    WHERE ad_infowindow_id = v_iw
      AND columnname = 'C_BPartner_Location_ID'
      AND isquerycriteria = 'Y';
  END IF;

  -- Result-grid location name only (do not use as a second location criteria)
  UPDATE ad_infocolumn SET
    isquerycriteria = 'N',
    queryoperator = NULL,
    seqnoselection = 0,
    isdisplayed = 'Y',
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '16a016ic-0010-4f01-8e15-000000000001';

  -- Criteria order (static query strip)
  UPDATE ad_infocolumn SET seqnoselection = 10, updated = NOW()
  WHERE ad_infowindow_id = v_iw AND ad_infocolumn_uu = '16a016ic-0001-4f01-8e15-000000000001';
  UPDATE ad_infocolumn SET seqnoselection = 20, updated = NOW()
  WHERE ad_infowindow_id = v_iw AND ad_infocolumn_uu = '16a016ic-0002-4f01-8e15-000000000001';
  UPDATE ad_infocolumn SET seqnoselection = 40, updated = NOW()
  WHERE ad_infowindow_id = v_iw AND ad_infocolumn_uu = '16a016ic-0004-4f01-8e15-000000000001';
  UPDATE ad_infocolumn SET seqnoselection = 50, updated = NOW()
  WHERE ad_infowindow_id = v_iw AND ad_infocolumn_uu = '16a016ic-0005-4f01-8e15-000000000001';
  UPDATE ad_infocolumn SET seqnoselection = 60, updated = NOW()
  WHERE ad_infowindow_id = v_iw AND ad_infocolumn_uu = '16a016ic-0006-4f01-8e15-000000000001';

  UPDATE ad_infowindow SET
    help = 'Static query page: set Planning Start/End, optional Service Locations (blank = all), then Search. '
      || 'Results and any Related summary tabs refresh from the query — there is no planning document to save. '
      || 'Zoom a leave row to submit/approve with existing processes.',
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw;

  RAISE NOTICE 'SAW016: Service Locations Multi Select fixed (ref value=159) on InfoWindow %', v_iw;
END $$;
