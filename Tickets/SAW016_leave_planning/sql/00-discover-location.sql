-- SAW016: employee-location relationship + similar multi-select patterns
\echo === TABLES mentioning location + employee/user ===
SELECT tablename FROM ad_table
WHERE tablename ILIKE '%location%' OR tablename ILIKE '%service%loc%'
   OR tablename ILIKE '%user%loc%' OR tablename ILIKE '%staff%loc%'
   OR tablename ILIKE '%employee%loc%'
ORDER BY 1;

\echo === AD_USER location columns ===
SELECT c.columnname, c.name, c.ad_reference_id, c.ad_reference_value_id
FROM ad_column c JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE upper(t.tablename)='AD_USER'
  AND (c.columnname ILIKE '%location%' OR c.columnname ILIKE '%org%' OR c.columnname ILIKE '%supervisor%')
ORDER BY c.columnname;

\echo === AbERP tables with location link ===
SELECT t.tablename, c.columnname, c.name, c.ad_reference_id
FROM ad_column c JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE t.tablename ILIKE 'AbERP%'
  AND c.columnname ILIKE '%location%'
ORDER BY t.tablename, c.columnname
LIMIT 80;

\echo === ChosenMultipleSelection usage ===
SELECT t.tablename, c.columnname, c.name, c.ad_reference_id, c.fieldlength
FROM ad_column c JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE c.ad_reference_id IN (200161, 200162, 200163) -- ChosenMultiple variants (IDs may differ)
   OR c.name ILIKE '%chosen%'
ORDER BY t.tablename LIMIT 40;

SELECT ad_reference_id, name FROM ad_reference WHERE name ILIKE '%chosen%' OR name ILIKE '%Multiple Selection%';

\echo === Planning / criteria windows ===
SELECT name, ad_window_uu, windowtype FROM ad_window
WHERE name ILIKE '%plan%' OR name ILIKE '%roster%' OR name ILIKE '%criteria%'
ORDER BY name LIMIT 40;
