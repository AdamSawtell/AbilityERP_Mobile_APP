SET search_path TO adempiere;

SELECT column_name, column_default
FROM information_schema.columns
WHERE table_schema = 'adempiere' AND table_name = 'aberp_rostered_shift'
ORDER BY ordinal_position;

SELECT * FROM aberp_rostered_shift
WHERE aberp_isshowingasavailable = 'Y' AND isactive = 'Y'
ORDER BY aberp_rostered_shift_id DESC LIMIT 1;
