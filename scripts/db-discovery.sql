-- Profile
\d ad_user
\d c_bpartner
\d c_bpartner_location
\d c_location

-- Shifts
\d aberp_rostered_shift
\d aberp_rostered_shiftstaff
\d aberp_shift_type
\d aberp_masterlocation

-- Open shift status values
SELECT r_status_id, name FROM r_status WHERE name ILIKE '%open%' OR name ILIKE '%available%' LIMIT 20;
SELECT DISTINCT r_status_id FROM aberp_rostered_shift WHERE r_status_id IS NOT NULL LIMIT 20;

-- Shift staff sample
SELECT column_name FROM information_schema.columns WHERE table_name = 'aberp_rostered_shiftstaff' ORDER BY ordinal_position;

-- Credentials
\d aberp_credentialassignment
\d aberp_credentials
\d aberp_credentialstype
\d aberp_credentialscategory

-- Leave
\d aberp_unavailability_leave
\d aberp_unavailability_type

-- Roster templates
\d aberp_rostered_shifttemplate
\d aberp_rostered_shifttemplateline

-- Sample data counts for worker 1000155 (Ella Williams c_bpartner)
SELECT COUNT(*) AS my_shifts FROM aberp_rostered_shiftstaff WHERE c_bpartner_staff_id = 1000155;
SELECT COUNT(*) AS open_shifts FROM aberp_rostered_shift LIMIT 1;
