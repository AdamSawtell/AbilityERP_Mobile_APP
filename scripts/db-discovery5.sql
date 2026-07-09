SET search_path TO adempiere;

SELECT COUNT(*) FROM aberp_rostered_shiftstaff WHERE c_bpartner_staff_id = 1000155;
SELECT COUNT(*) FROM aberp_rostered_shiftstaff WHERE aberp_user_contact_id = 1000107;

SELECT COUNT(*) AS open_v2 FROM aberp_rostered_shift s
WHERE s.isactive='Y'
AND NOT EXISTS (
  SELECT 1 FROM aberp_rostered_shiftstaff ss 
  WHERE ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id 
    AND ss.isactive='Y' 
    AND ss.c_bpartner_staff_id IS NOT NULL
);

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
AND s.starttime >= NOW() - INTERVAL '30 days'
ORDER BY s.starttime ASC NULLS LAST
LIMIT 10;

-- Current roster: all active shifts in next 14 days
SELECT s.aberp_rostered_shift_id, s.documentno, s.starttime, s.endtime,
       st.name AS shift_type, ml.name AS location,
       bp.name AS staff_name
FROM aberp_rostered_shift s
LEFT JOIN aberp_shift_type st ON st.aberp_shift_type_id = s.aberp_shift_type_id
LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = s.aberp_masterlocation_id
LEFT JOIN aberp_rostered_shiftstaff ss ON ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id AND ss.isactive='Y'
LEFT JOIN c_bpartner bp ON bp.c_bpartner_id = ss.c_bpartner_staff_id
WHERE s.isactive='Y' AND s.starttime >= NOW() - INTERVAL '7 days'
ORDER BY s.starttime ASC
LIMIT 10;

SELECT currentnext FROM ad_sequence WHERE name = 'Rostered_ShiftStaff';
