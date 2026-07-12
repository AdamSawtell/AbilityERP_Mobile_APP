-- Re-enable Related Info panels on Staff Rostering Info (portable).
-- Resolve Info Window / parent key columns / related rows by UU —
-- never hardcode seed AD_InfoColumn_ID / AD_InfoRelated_ID.
--
-- IMPORTANT: do NOT activate every ColumnName=C_BPartner_ID row.
-- HCO has an extra Multi Select "Support Receiver Needs" with the same
-- ColumnName; turning it active rebuilds ChosenMultipleSelection with -1
-- → ZK "non-negative only" on ReQuery (esp. with All/Any).

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

  -- Parent key columns for Related Info — by owned UU only
  UPDATE ad_infocolumn SET isactive = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu IN (
      '3402dcb1-ec9b-46b3-a8a6-8248b89cc4f4', -- AD_User_ID (key)
      '42578105-dbb8-4f51-9e53-8af7e5073997'  -- C_BPartner_ID (display BP for Related Info)
    );
  GET DIAGNOSTICS n = ROW_COUNT;
  RAISE NOTICE 'Parent InfoColumns activated: %', n;

  -- Kill Multi Select / leftover needs columns that recreate -1 Intboxes
  UPDATE ad_infocolumn SET
    isactive = 'N',
    isquerycriteria = 'N',
    isdisplayed = 'N',
    seqnoselection = 0,
    defaultvalue = NULL,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND (
      ad_reference_id = 200138 -- Multi Select Table
      OR ad_infocolumn_uu IN (
        '40d550c2-4088-412d-8774-f2d2b2cd9247', -- Support Receiver Needs (Multi Select C_BPartner_ID)
        '492b6870-a7b3-43f8-a9bd-7abf7b9efb49', -- Support Location Needs
        'c4ab6130-0d64-4ce0-8be8-e6f7af56a98b', -- Position Needs
        '40c40fdf-d0a1-4076-951f-f35e3deb463b', -- Rostered Shift Needs
        '32efe3e4-4853-4656-bc45-a6e6672890ca', -- Credentials
        '3916bb24-c7be-4f78-96ee-77a711fba800', -- Master Location
        'bf6693b4-56dd-4c1b-836d-3c0f517aad9d', -- Shift Status
        'ac0d418c-4aac-44fa-bc50-eb57ff978875'  -- Employee Status
      )
    );
  GET DIAGNOSTICS n = ROW_COUNT;
  RAISE NOTICE 'Multi Select / needs columns deactivated: %', n;

  -- Re-enable Related Info rows on this window
  UPDATE ad_inforelated SET
    isactive = 'Y',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND (
      ad_inforelated_uu IN (
        '9b6e8a01-4852-44dc-ab15-44bfd2c57164',
        '5011cf7a-1456-4807-9c34-3ad3413b98b8',
        'a0a79770-93ff-4f44-9d0f-4c7125895fd3'
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

  UPDATE ad_infowindow child SET
    isactive = 'Y',
    isvalid = 'Y',
    updated = NOW(),
    updatedby = 100
  FROM ad_inforelated ir
  WHERE ir.ad_infowindow_id = v_iw
    AND child.ad_infowindow_id = ir.relatedinfo_id
    AND ir.isactive = 'Y';

  RAISE NOTICE 'Related Info re-enabled for AD_InfoWindow_ID=%', v_iw;
END $$;
