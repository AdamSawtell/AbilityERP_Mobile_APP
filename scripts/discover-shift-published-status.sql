SET search_path TO adempiere;

SELECT column_name FROM information_schema.columns
WHERE table_name = 'aberp_rostered_shift' AND column_name ILIKE '%status%'
ORDER BY 1;

SELECT r_status_id, name, value, r_statuscategory_id
FROM r_status
WHERE name ILIKE '%publish%' OR value ILIKE '%publish%';

SELECT rs.r_status_id, rs.name, rs.value, sc.name AS category
FROM r_status rs
JOIN r_statuscategory sc ON sc.r_statuscategory_id = rs.r_statuscategory_id
WHERE sc.name ILIKE '%shift%' OR sc.name ILIKE '%roster%' OR rs.name ILIKE '%shift%'
ORDER BY sc.name, rs.name;
