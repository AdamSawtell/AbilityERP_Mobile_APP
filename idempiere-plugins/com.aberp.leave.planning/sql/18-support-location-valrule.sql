-- =============================================================================
-- SAW016 — Service Location criteria = active Support Locations only
-- Mirrors Support Location window tab where: AbERP_Support_Location.IsActive='Y'
-- (blank criteria still = all locations in the leave query)
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_iw INTEGER;
  v_val INTEGER;
  v_code TEXT :=
    'C_BPartner_Location.C_BPartner_Location_ID IN ('
    || 'SELECT C_BPartner_Location_ID FROM AbERP_Support_Location '
    || 'WHERE IsActive=''Y'' AND C_BPartner_Location_ID IS NOT NULL)';
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001';
  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'SAW016: Leave Planning Info Window UU 16a016iw-… missing';
  END IF;

  SELECT ad_val_rule_id INTO v_val
  FROM ad_val_rule
  WHERE ad_val_rule_uu = '16a01606-c0d4-4f01-8e15-000000000001';
  IF v_val IS NULL THEN
    RAISE EXCEPTION 'SAW016: location val rule UU 16a01606-… missing';
  END IF;

  UPDATE ad_val_rule SET
    name = 'AbERP Leave Planning Support Locations',
    description = 'Active Support Locations only (same filter as Support Location window)',
    code = v_code,
    updated = NOW(),
    updatedby = 100
  WHERE ad_val_rule_id = v_val;

  UPDATE ad_infocolumn SET
    name = 'Service Location',
    description = 'Optional. Active Support Locations only; leave blank for all.',
    help = 'Lookup lists active Support Locations (Support Location window filter). Blank = all locations.',
    ad_val_rule_id = v_val,
    ismultiselectcriteria = 'N',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '16a016ic-0003-4f01-8e15-000000000001';

  RAISE NOTICE 'SAW016: Service Location val rule → active Support Locations (val=%)', v_val;
END $$;

SELECT vr.name, vr.code,
       (SELECT COUNT(*) FROM aberp_support_location WHERE isactive = 'Y') AS active_support_locations
FROM ad_val_rule vr
WHERE vr.ad_val_rule_uu = '16a01606-c0d4-4f01-8e15-000000000001';
