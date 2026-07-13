SET search_path TO adempiere;
\echo === package_imp recent ===
SELECT ad_package_imp_id, name, pk_status, processed, created::date FROM ad_package_imp ORDER BY created DESC LIMIT 20;
\echo === stuck ===
SELECT ad_package_imp_id, name, pk_status, processed FROM ad_package_imp WHERE processed='N';
\echo === support location window ===
SELECT ad_window_id, name, ad_window_uu FROM ad_window WHERE name ILIKE '%Support Location%';
\echo === view ===
SELECT to_regclass('adempiere.hco_cred_missing_staff_v') AS view_exists;
\echo === hco elements sample ===
SELECT columnname, name FROM ad_element WHERE columnname ILIKE 'hco_%' OR name ILIKE '%Primary Department%' ORDER BY 1 LIMIT 40;
\echo === support location table ===
SELECT ad_table_id, tablename, ad_table_uu FROM ad_table WHERE tablename ILIKE '%Support_Location%' OR tablename ILIKE 'hco_%';
