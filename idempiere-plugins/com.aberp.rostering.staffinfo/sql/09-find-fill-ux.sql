-- AbERP Staff Rostering Info — find/fill UX polish (post smoke).
-- 1) Leave filter must be editable (was IsReadOnly=Y by mistake)
-- 2) Hide key ID from result grid noise
-- 3) Name/Value indexes for Like searches at scale
-- 4) Sync C_BPartner_ID from picked contact on ShiftStaff save (SQL-only, no Java)
-- 5) Put User Name first in criteria tab order

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

  -- Criteria must be editable (pack left several IsReadOnly=Y)
  UPDATE ad_infocolumn SET
    isreadonly = 'N',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND isactive = 'Y'
    AND isquerycriteria = 'Y';

  -- Criteria order: User Name first (high-use find), then key/BP/filters
  UPDATE ad_infocolumn SET seqnoselection = 10, updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw AND columnname = 'Name' AND isactive = 'Y';
  UPDATE ad_infocolumn SET seqnoselection = 20, updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw AND columnname = 'Value' AND isactive = 'Y';
  UPDATE ad_infocolumn SET seqnoselection = 30, updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw AND columnname = 'BP_Name' AND isactive = 'Y';
  UPDATE ad_infocolumn SET seqnoselection = 40, updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw AND columnname = 'IsEmployee' AND isactive = 'Y';
  UPDATE ad_infocolumn SET seqnoselection = 50, updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw AND columnname = 'AbERP_isagencystaff' AND isactive = 'Y';
  UPDATE ad_infocolumn SET seqnoselection = 60, updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw AND columnname = 'AbERP_Gender_ID' AND isactive = 'Y';
  UPDATE ad_infocolumn SET seqnoselection = 70, updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw AND columnname = 'BP_C_Job_ID' AND isactive = 'Y';
  UPDATE ad_infocolumn SET seqnoselection = 80, updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw AND columnname = 'AbERP_OnApprovedLeave' AND isactive = 'Y';

  -- Like finds: keep Upper; iDempiere does not always auto-wrap %, so Help documents it.
  -- Also clear QueryFunction only if you prefer case-sensitive auto-% (not used here).

  -- Key must stay IsDisplayed=Y (IsHideInInfoColumn hides it). IsDisplayed=N breaks ZK keyView.
  UPDATE ad_infocolumn SET
    isdisplayed = 'Y',
    ishideinfocolumn = 'Y',
    iskey = 'Y',
    ad_reference_id = 11,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND columnname = 'AD_User_ID'
    AND isactive = 'Y';

  -- Identifier for Search display text after pick
  UPDATE ad_infocolumn SET
    isidentifier = 'Y',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND columnname = 'Name'
    AND isactive = 'Y';

  UPDATE ad_infowindow SET
    help = 'Find: put User Name first (e.g. %Fraser% or Fraser%). Search Key / BP Name also use % wildcards. Employee defaults Yes. On Approved Leave defaults N (hide). Related Info: Rostered Shift, Credentials, Alerts. Business Partner (virtual) refreshes from the contact on save; c_bpartner_staff_id is stamped by trigger.',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw;

  RAISE NOTICE 'Find/fill UX polish applied on AD_InfoWindow_ID=%', v_iw;
END $$;

-- Name / Value indexes (small today; protects Like finds as staff grows)
CREATE INDEX IF NOT EXISTS ad_user_name_upper_idx
  ON ad_user (upper(name::text));

CREATE INDEX IF NOT EXISTS ad_user_value_upper_idx
  ON ad_user (upper(value::text));

CREATE INDEX IF NOT EXISTS c_bpartner_name_upper_idx
  ON c_bpartner (upper(name::text));

-- Stamp BP staff from picked contact on ShiftStaff save (SQL-only, no Java)
-- Physical column is c_bpartner_staff_id (AD may label it Business Partner).
CREATE OR REPLACE FUNCTION aberp_shiftstaff_sync_bp_from_contact()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_bp NUMERIC;
BEGIN
  IF NEW.aberp_user_contact_id IS NOT NULL AND NEW.aberp_user_contact_id > 0 THEN
    IF TG_OP = 'INSERT'
       OR NEW.aberp_user_contact_id IS DISTINCT FROM OLD.aberp_user_contact_id
       OR COALESCE(NEW.c_bpartner_staff_id, 0) <= 0 THEN
      SELECT u.c_bpartner_id INTO v_bp
      FROM ad_user u
      WHERE u.ad_user_id = NEW.aberp_user_contact_id;
      IF v_bp IS NOT NULL AND v_bp > 0 THEN
        NEW.c_bpartner_staff_id := v_bp;
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS aberp_shiftstaff_sync_bp_trg ON aberp_rostered_shiftstaff;
CREATE TRIGGER aberp_shiftstaff_sync_bp_trg
  BEFORE INSERT OR UPDATE OF aberp_user_contact_id, c_bpartner_staff_id
  ON aberp_rostered_shiftstaff
  FOR EACH ROW
  EXECUTE FUNCTION aberp_shiftstaff_sync_bp_from_contact();

-- Backfill existing staff rows missing BP staff
UPDATE aberp_rostered_shiftstaff ss
SET c_bpartner_staff_id = u.c_bpartner_id,
    updated = NOW(),
    updatedby = 100
FROM ad_user u
WHERE u.ad_user_id = ss.aberp_user_contact_id
  AND COALESCE(ss.aberp_user_contact_id, 0) > 0
  AND COALESCE(ss.c_bpartner_staff_id, 0) <= 0
  AND COALESCE(u.c_bpartner_id, 0) > 0;
