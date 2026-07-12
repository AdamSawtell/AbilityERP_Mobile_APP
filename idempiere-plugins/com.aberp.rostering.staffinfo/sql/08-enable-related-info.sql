-- Re-enable Related Info panels on Staff Rostering Info (portable).
-- Resolve Info Window / parent key columns / related rows by UU or name —
-- never hardcode seed AD_InfoColumn_ID / AD_InfoRelated_ID / related IW IDs.
--
-- Typical links (names may vary slightly by client):
--   Current/Next Roster Period Shifts, Credentials Assigned, BP User Alerts,
--   Employee Leave — parent keys AD_User_ID and C_BPartner_ID must stay active.

SET search_path TO adempiere;

DO $$
DECLARE
  v_iw NUMERIC;
  n INT;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf';

  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'AD_InfoWindow UU 2b4ab146-0809-47c6-96f3-8b841d60a6bf not found';
  END IF;

  -- Parent key columns for Related Info (by UU when known; else ColumnName on this IW)
  UPDATE ad_infocolumn SET isactive = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND (
      ad_infocolumn_uu IN (
        '3402dcb1-ec9b-46b3-a8a6-8248b89cc4f4', -- AD_User_ID (key)
        '42578105-dbb8-4f51-9e53-8af7e5073997'  -- C_BPartner_ID (display BP)
      )
      OR columnname IN ('AD_User_ID', 'C_BPartner_ID')
    );
  GET DIAGNOSTICS n = ROW_COUNT;
  RAISE NOTICE 'Parent InfoColumns activated: %', n;

  -- Re-enable Related Info rows on this window (all Ab_ERP links; keep HCO extras)
  UPDATE ad_inforelated SET
    isactive = 'Y',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND (
      ad_inforelated_uu IN (
        '9b6e8a01-4852-44dc-ab15-44bfd2c57164', -- Current Roster Period Shifts
        '5011cf7a-1456-4807-9c34-3ad3413b98b8', -- Credentials Assigned
        'a0a79770-93ff-4f44-9d0f-4c7125895fd3'  -- BP User Alerts
      )
      OR name IN (
        'Current Roster Period Shifts',
        'Credentials Assigned',
        'BP User Alerts',
        'Rostered Shift'
      )
    );
  GET DIAGNOSTICS n = ROW_COUNT;
  RAISE NOTICE 'Related Info rows activated: %', n;

  -- Related Info Windows must be valid/active (resolve via relatedinfo_id → UU/name)
  UPDATE ad_infowindow child SET
    isactive = 'Y',
    isvalid = 'Y',
    updated = NOW(),
    updatedby = 100
  FROM ad_inforelated ir
  WHERE ir.ad_infowindow_id = v_iw
    AND child.ad_infowindow_id = ir.relatedinfo_id
    AND ir.isactive = 'Y';
  GET DIAGNOSTICS n = ROW_COUNT;
  RAISE NOTICE 'Related Info Windows validated: %', n;

  RAISE NOTICE 'Related Info re-enabled for AD_InfoWindow_ID=%', v_iw;
END $$;
