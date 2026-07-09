SET search_path TO adempiere;

SELECT s.aberp_rostered_shift_id, s.documentno, s.starttime, s.endtime,
       st.name AS shift_type, ml.name AS location, ss.aberp_requestshift
FROM aberp_rostered_shiftstaff ss
JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id = ss.aberp_rostered_shift_id
LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
WHERE ss.isactive='Y' AND s.isactive='Y'
AND (ss.c_bpartner_staff_id = 1000155 OR ss.aberp_user_contact_id = 1000107)
ORDER BY s.starttime DESC NULLS LAST
LIMIT 8;

SELECT s.aberp_rostered_shift_id, s.documentno, s.starttime, s.endtime,
       st.name AS shift_type, ml.name AS location
FROM aberp_rostered_shift s
LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
WHERE s.isactive='Y'
AND NOT EXISTS (
  SELECT 1 FROM aberp_rostered_shiftstaff ss 
  WHERE ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id 
    AND ss.isactive='Y' AND ss.c_bpartner_staff_id IS NOT NULL
)
ORDER BY s.starttime DESC NULLS LAST
LIMIT 8;

SELECT name, currentnext FROM ad_sequence WHERE name ILIKE '%rostered%shift%';
