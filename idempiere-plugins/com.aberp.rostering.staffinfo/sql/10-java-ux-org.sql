-- Wire Staff Info Java UX + keep AbilityERP shifts/staff off org *.
-- Callouts register via OSGi IColumnCalloutFactory (no AD_Column.callout string required).
-- Info panel registers via OSGi IInfoFactory (no InfoFactoryClass required).

SET search_path TO adempiere;

-- Re-apply org migration for any new org-0 rows
DO $$
DECLARE
  v_client NUMERIC;
  v_org NUMERIC;
  n_shift INT;
  n_staff INT;
BEGIN
  SELECT ad_client_id INTO v_client FROM ad_client WHERE name = 'AbilityERP' AND isactive = 'Y' LIMIT 1;
  IF v_client IS NULL THEN
    RAISE NOTICE 'AbilityERP client not found — skip org fix';
    RETURN;
  END IF;

  SELECT ad_org_id INTO v_org
  FROM ad_org
  WHERE ad_client_id = v_client AND isactive = 'Y' AND ad_org_id > 0
  ORDER BY ad_org_id
  LIMIT 1;

  IF v_org IS NULL THEN
    RAISE NOTICE 'No non-zero org for AbilityERP — skip org fix';
    RETURN;
  END IF;

  UPDATE aberp_rostered_shift SET
    ad_org_id = v_org, updated = NOW(), updatedby = 100
  WHERE ad_client_id = v_client AND ad_org_id = 0;
  GET DIAGNOSTICS n_shift = ROW_COUNT;

  UPDATE aberp_rostered_shiftstaff SET
    ad_org_id = v_org, updated = NOW(), updatedby = 100
  WHERE ad_client_id = v_client AND ad_org_id = 0;
  GET DIAGNOSTICS n_staff = ROW_COUNT;

  RAISE NOTICE 'Org harden client=% org=% shifts=% staff=%', v_client, v_org, n_shift, n_staff;
END $$;

-- BEFORE trigger: new/updated staff lines inherit parent shift org when still *
CREATE OR REPLACE FUNCTION aberp_shiftstaff_sync_org_from_shift()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_org NUMERIC;
BEGIN
  IF COALESCE(NEW.ad_org_id, 0) > 0 THEN
    RETURN NEW;
  END IF;
  IF COALESCE(NEW.aberp_rostered_shift_id, 0) <= 0 THEN
    RETURN NEW;
  END IF;
  SELECT ad_org_id INTO v_org
  FROM aberp_rostered_shift
  WHERE aberp_rostered_shift_id = NEW.aberp_rostered_shift_id;
  IF COALESCE(v_org, 0) > 0 THEN
    NEW.ad_org_id := v_org;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS aberp_shiftstaff_sync_org_trg ON aberp_rostered_shiftstaff;
CREATE TRIGGER aberp_shiftstaff_sync_org_trg
  BEFORE INSERT OR UPDATE OF ad_org_id, aberp_rostered_shift_id
  ON aberp_rostered_shiftstaff
  FOR EACH ROW
  EXECUTE FUNCTION aberp_shiftstaff_sync_org_from_shift();

-- Help text for Java-enhanced find/fill
UPDATE ad_infowindow SET
  help = 'Find: type part of a name (wildcards auto-added, e.g. Fraser → %Fraser%). From Shift Employee, staff on approved leave overlapping the shift dates and staff already on an overlapping shift are hidden. On Approved Leave (CURRENT_DATE) remains an extra filter. Business Partner stamps from contact on pick/save. Prefer non-* org on Shift so Employee Search stays editable.',
  description = 'Fast staff picker for Shift Employee fill (lean User+BP). Auto-% Like, shift-date leave/overlap when opened from Shift.',
  updated = NOW(),
  updatedby = 100
WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf';

-- Keep contact searchable; allow org stamp from callout/parent when still *
UPDATE ad_column SET
  isalwaysupdateable = 'Y',
  updated = NOW(),
  updatedby = 100
WHERE ad_column_id IN (
  SELECT c.ad_column_id
  FROM ad_column c
  JOIN ad_table t ON t.ad_table_id = c.ad_table_id
  WHERE t.tablename = 'AbERP_Rostered_ShiftStaff'
    AND c.columnname IN ('AbERP_User_Contact_ID', 'AD_Org_ID')
);
