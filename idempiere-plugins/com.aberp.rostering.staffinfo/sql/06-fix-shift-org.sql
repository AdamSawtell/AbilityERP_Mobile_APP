-- Harden rostered shifts (and staff lines) off AD_Org_ID=0 (*) when needed.
-- Org-0 detail tabs present as fully read-only in WebUI (no Search/More on Employee),
-- so Shift → Employee → staff picker cannot open.
--
-- Portable: prefers AbilityERP seed client when present; otherwise skips data move
-- (HCO / other clients keep their org model). Always ensures AbERP_User_Contact_ID
-- is AlwaysUpdateable so Search stays editable when the parent org is valid.

SET search_path TO adempiere;

DO $$
DECLARE
  v_client NUMERIC;
  v_org NUMERIC;
  n_shift INT;
  n_staff INT;
BEGIN
  SELECT ad_client_id INTO v_client FROM ad_client WHERE name = 'AbilityERP' AND isactive = 'Y' LIMIT 1;
  IF v_client IS NULL THEN
    RAISE NOTICE 'AbilityERP client not found — skip org-* data move (other-client / HCO OK)';
  ELSE
    SELECT ad_org_id INTO v_org
    FROM ad_org
    WHERE ad_client_id = v_client AND isactive = 'Y' AND ad_org_id > 0
    ORDER BY ad_org_id
    LIMIT 1;

    IF v_org IS NULL THEN
      RAISE NOTICE 'No non-zero org for AbilityERP client % — skip org data move', v_client;
    ELSE
      UPDATE aberp_rostered_shift SET
        ad_org_id = v_org,
        updated = NOW(),
        updatedby = 100
      WHERE ad_client_id = v_client AND ad_org_id = 0;
      GET DIAGNOSTICS n_shift = ROW_COUNT;

      UPDATE aberp_rostered_shiftstaff SET
        ad_org_id = v_org,
        updated = NOW(),
        updatedby = 100
      WHERE ad_client_id = v_client AND ad_org_id = 0;
      GET DIAGNOSTICS n_staff = ROW_COUNT;

      RAISE NOTICE 'Org fix client=% org=% shifts=% staff=%', v_client, v_org, n_shift, n_staff;
    END IF;
  END IF;
END $$;

-- Ensure Employee Search field stays editable on new/existing lines (More button)
UPDATE ad_column SET
  isalwaysupdateable = 'Y',
  updated = NOW(),
  updatedby = 100
WHERE ad_column_id = (
  SELECT c.ad_column_id
  FROM ad_column c
  JOIN ad_table t ON t.ad_table_id = c.ad_table_id
  WHERE t.tablename = 'AbERP_Rostered_ShiftStaff'
    AND c.columnname = 'AbERP_User_Contact_ID'
);
