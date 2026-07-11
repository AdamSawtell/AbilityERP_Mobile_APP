-- Re-enable Related Info panels on Staff Rostering Info.
-- Links (already defined):
--   Rostered Shift       → BP User Rostered Shift (user contact)
--   Credentials Assigned → BP User Credentials Assigned (user contact)
--   BP User Alerts       → via C_BPartner_ID
-- Parent key AD_User_ID (1000143) and C_BPartner_ID (1000236) must stay active.

SET search_path TO adempiere;

DO $$
DECLARE
  v_iw NUMERIC;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf';

  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'AD_InfoWindow UU 2b4ab146-0809-47c6-96f3-8b841d60a6bf not found';
  END IF;

  -- Ensure parent link columns exist/active
  UPDATE ad_infocolumn SET isactive = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infocolumn_id IN (1000143, 1000236)
    AND ad_infowindow_id = v_iw;

  UPDATE ad_inforelated SET
    isactive = 'Y',
    seqno = CASE ad_inforelated_id
      WHEN 1000000 THEN 10
      WHEN 1000001 THEN 20
      WHEN 1000002 THEN 30
      ELSE seqno
    END,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_inforelated_id IN (1000000, 1000001, 1000002);

  -- Related Info Windows must be valid/active
  UPDATE ad_infowindow SET isactive = 'Y', isvalid = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id IN (1000025, 1000026, 1000038);

  RAISE NOTICE 'Related Info re-enabled for AD_InfoWindow_ID=%', v_iw;
END $$;
