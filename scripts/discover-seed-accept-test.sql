SET search_path TO adempiere;

-- Employees (support workers) for test REQ responses
SELECT u.ad_user_id, u.name, u.c_bpartner_id, bp.name AS bp_name
FROM ad_user u
JOIN c_bpartner bp ON bp.c_bpartner_id = u.c_bpartner_id
JOIN ad_user_roles ur ON ur.ad_user_id = u.ad_user_id AND ur.isactive = 'Y'
JOIN ad_role r ON r.ad_role_id = ur.ad_role_id
WHERE r.name = 'Support Worker' AND u.isactive = 'Y' AND u.ad_client_id = 1000002
ORDER BY u.name
LIMIT 10;

-- Sample existing responselog row
SELECT * FROM aberp_rosteredresponselog WHERE isactive = 'Y' ORDER BY created DESC LIMIT 1;

-- Required NOT NULL columns without defaults on shift + responselog
SELECT table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'adempiere'
  AND table_name IN ('aberp_rostered_shift', 'aberp_rosteredresponselog', 'aberp_rostered_shiftstaff')
  AND is_nullable = 'NO' AND column_default IS NULL
ORDER BY table_name, ordinal_position;

-- Sequences
SELECT name, currentnext FROM ad_sequence
WHERE name ILIKE '%Rostered%Shift%' OR name ILIKE '%Response%'
ORDER BY name;

-- Current pay period
SELECT aberp_pr_period_id, name, startdate, enddate
FROM aberp_pr_period WHERE isactive = 'Y' AND startdate <= CURRENT_DATE AND enddate >= CURRENT_DATE
ORDER BY startdate DESC LIMIT 1;
