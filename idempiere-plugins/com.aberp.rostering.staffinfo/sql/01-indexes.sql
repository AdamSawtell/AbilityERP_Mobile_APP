-- AbERP Staff Rostering Info — performance indexes
-- Safe to re-run. Supports EXISTS eligibility checks on the rewritten Info Window.

SET search_path TO adempiere;

CREATE INDEX IF NOT EXISTS aberp_shiftstaff_user_contact_active
  ON aberp_rostered_shiftstaff (aberp_user_contact_id)
  WHERE isactive = 'Y' AND COALESCE(aberp_user_contact_id, 0) > 0;

CREATE INDEX IF NOT EXISTS aberp_credassign_user_contact_active
  ON aberp_credentialassignment (aberp_user_contact_id)
  WHERE isactive = 'Y' AND COALESCE(aberp_user_contact_id, 0) > 0;

CREATE INDEX IF NOT EXISTS aberp_unavail_leave_user_active
  ON aberp_unavailability_leave (aberp_user_contact_id)
  WHERE isactive = 'Y' AND COALESCE(aberp_user_contact_id, 0) > 0;

CREATE INDEX IF NOT EXISTS aberp_unavail_leave_dates_active
  ON aberp_unavailability_leave (startdate, enddate)
  WHERE isactive = 'Y';

CREATE INDEX IF NOT EXISTS aberp_rostered_shift_active_nontemplate_dates
  ON aberp_rostered_shift (startdate, enddate)
  WHERE isactive = 'Y' AND COALESCE(aberp_isshiftrosteredtemplate, 'N') = 'N';

-- Protect Upper(Like) name/key finds as staff volume grows
CREATE INDEX IF NOT EXISTS ad_user_name_upper_idx
  ON ad_user (upper(name::text));

CREATE INDEX IF NOT EXISTS ad_user_value_upper_idx
  ON ad_user (upper(value::text));

CREATE INDEX IF NOT EXISTS c_bpartner_name_upper_idx
  ON c_bpartner (upper(name::text));
