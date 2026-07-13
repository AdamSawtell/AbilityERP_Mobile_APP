-- SAW018: post-packin verify
SET search_path TO adempiere;

\echo === recent SAW018 / hco packins ===
SELECT ad_package_imp_id, name, pk_status, processed, created
FROM ad_package_imp
WHERE name ILIKE '%hco_%'
   OR name ILIKE '%credentials%'
   OR name ILIKE '%supportlocation%'
   OR name ILIKE '%client_employee%'
ORDER BY created DESC
LIMIT 20;

\echo === view ===
SELECT to_regclass('adempiere.hco_cred_missing_staff_v') AS view_exists;

\echo === credentials table AD ===
SELECT ad_table_id, tablename, ad_table_uu
FROM ad_table
WHERE tablename = 'hco_cred_missing_staff_v'
   OR ad_table_uu = '598a7584-4c57-4c31-8ea5-3b393d3d1e68';

\echo === primary dept element ===
SELECT ad_element_id, columnname, name, ad_element_uu
FROM ad_element
WHERE ad_element_uu = 'daca9cb3-fe35-4193-95ff-dc99dc887692'
   OR columnname ILIKE 'hco_primarydept';

\echo === support location still same UU ===
SELECT ad_window_id, name, ad_window_uu
FROM ad_window
WHERE ad_window_uu = '6ef3c558-3ec8-4f0c-be40-89f35d8acebf';

\echo === stuck remaining ===
SELECT COUNT(*) AS stuck FROM ad_package_imp WHERE processed = 'N';
