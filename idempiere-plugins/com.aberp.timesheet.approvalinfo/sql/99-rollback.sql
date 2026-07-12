-- SAW010 rollback: restore Timesheet Approval Info column visibility; remove Break columns.
-- Does not delete physical AbERP_Break_* table columns.

SET search_path TO adempiere;

DO $$
DECLARE
  v_iw NUMERIC;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4';

  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'Rollback abort: Timesheet Approval Info Window UU not found';
  END IF;

  DELETE FROM ad_infocolumn
  WHERE ad_infocolumn_uu IN (
    'c4e8a1b2-5d6f-4a7c-9e01-2b3d4f5a6c70', -- Break Start
    'd5f9b2c3-6e70-4b8d-a012-3c4e5f6a7b81'  -- Break End
  );

  -- Restore prior displayed flags
  UPDATE ad_infocolumn SET isdisplayed = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu IN (
      '39fb0ffb-58e5-46e7-8966-48b2fb223b86', -- Shift Cost
      '6f1c18f1-43b5-4cab-8f13-8d5960c602cd', -- Name
      '750b7e9f-1299-49c6-8477-616de3c4b0de', -- Employee
      '890d8791-326b-4092-beb5-9046587d7556', -- Activity
      '61e09e5f-222b-4bb6-bb29-ae8fb785f4e9'  -- Business Partner
    );

  UPDATE ad_infowindow SET updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw;

  RAISE NOTICE 'SAW010 rolled back on Info Window %', v_iw;
END $$;
