SET search_path TO adempiere;

SELECT ss.* FROM aberp_rostered_shiftstaff ss LIMIT 1;

SELECT c_bpartner_staff_id, COUNT(*) 
FROM aberp_rostered_shiftstaff 
WHERE isactive='Y' 
GROUP BY c_bpartner_staff_id 
ORDER BY COUNT(*) DESC LIMIT 5;

SELECT s.aberp_rostered_shift_id, s.documentno, s.starttime, s.endtime,
       st.name AS shift_type, ml.name AS location, ss.c_bpartner_staff_id
FROM aberp_rostered_shiftstaff ss
JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id = ss.aberp_rostered_shift_id
LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
WHERE ss.isactive='Y' AND s.isactive='Y'
ORDER BY s.starttime DESC NULLS LAST
LIMIT 5;

SELECT tablename FROM ad_sequence WHERE name LIKE '%Rostered_ShiftStaff%' OR name LIKE '%ShiftStaff%';
