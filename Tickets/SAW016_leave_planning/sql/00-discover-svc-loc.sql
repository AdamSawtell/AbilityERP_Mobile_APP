-- SAW016: what is "service location" for employees?
\echo === MasterLocation vs Support Location vs BP Location labels ===
SELECT t.tablename, t.name FROM ad_table t
WHERE t.tablename IN ('AbERP_MasterLocation','AbERP_Support_Location','C_BPartner_Location');

\echo === Employee contract location ===
SELECT c.columnname, c.name, c.ad_reference_id
FROM ad_column c JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE t.tablename='AbERP_Employee_Contract'
ORDER BY c.columnname;

\echo === Sample: user location name ===
SELECT u.ad_user_id, u.name, u.value AS emp_no, bpl.name AS bp_loc_name, bpl.c_bpartner_location_id,
       ml.name AS master_loc, ml.aberp_masterlocation_id
FROM ad_user u
LEFT JOIN c_bpartner_location bpl ON bpl.c_bpartner_location_id=u.c_bpartner_location_id
LEFT JOIN aberp_masterlocation ml ON ml.c_bpartner_location_id=u.c_bpartner_location_id
WHERE u.isactive='Y' AND u.c_bpartner_location_id IS NOT NULL
LIMIT 15;

\echo === How many users map to MasterLocation via BP loc ===
SELECT COUNT(*) AS users, COUNT(ml.aberp_masterlocation_id) AS with_master
FROM ad_user u
LEFT JOIN aberp_masterlocation ml ON ml.c_bpartner_location_id=u.c_bpartner_location_id AND ml.isactive='Y'
WHERE u.isactive='Y' AND u.c_bpartner_location_id IS NOT NULL;

\echo === MasterLocation structure ===
SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='aberp_masterlocation'
ORDER BY ordinal_position;

\echo === Windows/fields named Service Location ===
SELECT w.name AS window, f.name AS field, c.columnname, t.tablename
FROM ad_field f
JOIN ad_column c ON c.ad_column_id=f.ad_column_id
JOIN ad_tab tab ON tab.ad_tab_id=f.ad_tab_id
JOIN ad_window w ON w.ad_window_id=tab.ad_window_id
JOIN ad_table t ON t.ad_table_id=tab.ad_table_id
WHERE f.name ILIKE '%service location%' OR f.name ILIKE '%working location%'
   OR f.name ILIKE '%partner location%' OR (f.name ILIKE '%location%' AND t.tablename ILIKE '%user%')
ORDER BY f.name, w.name
LIMIT 40;

\echo === Menu folder Ability ERP ===
SELECT m.name, m.ad_menu_id, m.ad_window_id, m.ad_menu_uu
FROM ad_menu m
WHERE m.name ILIKE '%leave%' OR m.name ILIKE '%unavail%' OR m.name ILIKE '%roster%'
ORDER BY m.name LIMIT 40;

\echo === nextid sequences of interest ===
SELECT name, currentnext FROM ad_sequence
WHERE name IN ('AD_Window','AD_Table','AD_Tab','AD_Column','AD_Field','AD_Menu','AD_Process','AD_Reference')
ORDER BY 1;
