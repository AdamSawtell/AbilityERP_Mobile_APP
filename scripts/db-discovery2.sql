SET search_path TO adempiere;

-- Shift columns
SELECT column_name FROM information_schema.columns 
WHERE table_schema='adempiere' AND table_name='aberp_rostered_shift' 
AND column_name IN ('date','start_time','end_time','r_status_id','aberp_shift_type_id','aberp_masterlocation_id','documentno','aberp_rostered_shift_id')
ORDER BY column_name;

SELECT column_name FROM information_schema.columns 
WHERE table_schema='adempiere' AND table_name='aberp_rostered_shiftstaff'
ORDER BY ordinal_position;

-- Status values for shifts
SELECT rs.r_status_id, rs.name, COUNT(*) 
FROM aberp_rostered_shift s
JOIN r_status rs ON rs.r_status_id = s.r_status_id
GROUP BY rs.r_status_id, rs.name
ORDER BY COUNT(*) DESC
LIMIT 15;

-- Open shifts: shifts with no staff OR specific status
SELECT COUNT(*) AS total_shifts FROM aberp_rostered_shift WHERE isactive='Y';
SELECT COUNT(*) AS shifts_no_staff FROM aberp_rostered_shift s
WHERE s.isactive='Y'
AND NOT EXISTS (
  SELECT 1 FROM aberp_rostered_shiftstaff ss 
  WHERE ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id AND ss.isactive='Y'
);

-- Sample open shift
SELECT s.aberp_rostered_shift_id, s.documentno, s.date, s.start_time, s.end_time, s.r_status_id,
       st.name AS shift_type, ml.name AS location
FROM aberp_rostered_shift s
LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
WHERE s.isactive='Y'
AND NOT EXISTS (
  SELECT 1 FROM aberp_rostered_shiftstaff ss 
  WHERE ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id AND ss.isactive='Y'
)
LIMIT 3;

-- My shifts for Ella (1000155)
SELECT s.aberp_rostered_shift_id, s.documentno, s.date, s.start_time, s.end_time,
       st.name AS shift_type, ml.name AS location
FROM aberp_rostered_shiftstaff ss
JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id = ss.aberp_rostered_shift_id
LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
WHERE ss.c_bpartner_staff_id = 1000155 AND ss.isactive='Y' AND s.isactive='Y'
ORDER BY s.date DESC NULLS LAST
LIMIT 5;

-- Profile for Ella
SELECT bp.c_bpartner_id, bp.value, bp.name, bp.aberp_first_name, bp.aberp_last_name, bp.aberp_preferred_name,
       bp.phone, bp.email, u.name AS login_name
FROM c_bpartner bp
JOIN ad_user u ON u.c_bpartner_id = bp.c_bpartner_id
WHERE bp.c_bpartner_id = 1000155;

-- Credentials
SELECT column_name FROM information_schema.columns 
WHERE table_schema='adempiere' AND table_name='aberp_credentialassignment'
ORDER BY ordinal_position;

SELECT ca.aberp_credentialassignment_id, c.name AS credential, c.aberp_expirydate, ct.name AS type_name
FROM aberp_credentialassignment ca
JOIN aberp_credentials c ON c.aberp_credentials_id = ca.aberp_credentials_id
LEFT JOIN aberp_credentialstype ct ON ct.aberp_credentialstype_id = c.aberp_credentialstype_id
WHERE ca.c_bpartner_id = 1000155 AND ca.isactive='Y'
LIMIT 5;

-- Leave
SELECT column_name FROM information_schema.columns 
WHERE table_schema='adempiere' AND table_name='aberp_unavailability_leave'
ORDER BY ordinal_position;

SELECT * FROM aberp_unavailability_leave WHERE c_bpartner_id = 1000155 LIMIT 3;

-- Roster template
SELECT COUNT(*) FROM aberp_rostered_shifttemplate WHERE isactive='Y';
