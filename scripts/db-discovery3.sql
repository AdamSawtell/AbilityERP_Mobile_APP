SET search_path TO adempiere;

SELECT column_name FROM information_schema.columns 
WHERE table_schema='adempiere' AND table_name='aberp_rostered_shift' 
AND (column_name ILIKE '%date%' OR column_name ILIKE '%time%' OR column_name ILIKE '%start%' OR column_name ILIKE '%end%' OR column_name ILIKE '%day%')
ORDER BY column_name;

SELECT s.aberp_rostered_shift_id, s.documentno, s.startdate, s.enddate, s.starttime, s.endtime, s.r_status_id,
       st.name AS shift_type, ml.name AS location
FROM aberp_rostered_shift s
LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
WHERE s.isactive='Y'
AND NOT EXISTS (
  SELECT 1 FROM aberp_rostered_shiftstaff ss 
  WHERE ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id AND ss.isactive='Y'
)
LIMIT 5;

SELECT s.aberp_rostered_shift_id, s.documentno, s.startdate, s.enddate, s.starttime, s.endtime,
       st.name AS shift_type, ml.name AS location, ss.aberp_requestshift
FROM aberp_rostered_shiftstaff ss
JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id = ss.aberp_rostered_shift_id
LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
WHERE ss.c_bpartner_staff_id = 1000155 AND ss.isactive='Y' AND s.isactive='Y'
ORDER BY s.startdate DESC NULLS LAST
LIMIT 5;

SELECT ca.aberp_credentialassignment_id, c.name AS credential, ca.aberp_expirydate, ct.name AS type_name,
       cc.name AS category_name
FROM aberp_credentialassignment ca
JOIN aberp_credentials c ON c.aberp_credentials_id = ca.aberp_credentials_id
LEFT JOIN aberp_credentialstype ct ON ct.aberp_credentialstype_id = ca.aberp_credentialstype_id
LEFT JOIN aberp_credentialscategory cc ON cc.aberp_credentialscategory_id = ca.aberp_credentialscategory_id
WHERE ca.c_bpartner_staff_id = 1000155 AND ca.isactive='Y'
LIMIT 5;

SELECT l.aberp_unavailability_leave_id, l.startdate, l.enddate, l.note, l.aberp_submitterstatus, l.aberp_approverstatus,
       ut.name AS leave_type
FROM aberp_unavailability_leave l
LEFT JOIN aberp_unavailability_type ut ON ut.aberp_unavailability_type_id = l.aberp_unavailability_type_id
WHERE l.c_bpartner_staff_id = 1000155 AND l.isactive='Y'
ORDER BY l.startdate DESC
LIMIT 5;

SELECT t.aberp_rostered_shifttemplate_id, t.name, t.value
FROM aberp_rostered_shifttemplate t
WHERE t.isactive='Y'
LIMIT 5;

-- Address
SELECT loc.address1, loc.city, loc.postal, loc.regionname
FROM c_bpartner_location bpl
JOIN c_location loc ON loc.c_location_id = bpl.c_location_id
WHERE bpl.c_bpartner_id = 1000155 AND bpl.isactive='Y'
LIMIT 3;
