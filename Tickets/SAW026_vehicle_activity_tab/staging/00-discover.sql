\pset pager off
SET search_path TO adempiere;

\echo 'Vehicle windows and tabs'
SELECT w.ad_window_id, w.ad_window_uu, w.name AS window_name,
       t.ad_tab_id, t.ad_tab_uu, t.name AS tab_name, t.seqno,
       tb.ad_table_id, tb.ad_table_uu, tb.tablename,
       c.columnname AS tab_link_column
FROM ad_window w
JOIN ad_tab t ON t.ad_window_id = w.ad_window_id
JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
LEFT JOIN ad_column c ON c.ad_column_id = t.ad_column_id
WHERE tb.tablename = 'AbERP_Vehicle'
   OR w.name ILIKE '%vehicle%'
ORDER BY w.name, t.seqno, t.ad_tab_id;

\echo 'Vehicle key and candidate Contact Activity columns'
SELECT tb.tablename, c.ad_column_id, c.ad_column_uu, c.columnname, c.name,
       c.ad_reference_id, c.ad_reference_value_id, c.iskey, c.isparent,
       e.ad_element_id, e.ad_element_uu
FROM ad_table tb
JOIN ad_column c ON c.ad_table_id = tb.ad_table_id
LEFT JOIN ad_element e ON e.ad_element_id = c.ad_element_id
WHERE tb.tablename IN ('AbERP_Vehicle', 'C_ContactActivity')
  AND (
    c.iskey = 'Y'
    OR c.columnname ILIKE '%Vehicle%'
    OR c.columnname IN ('ContactActivityType', 'C_BPartner_ID', 'AD_User_ID', 'AbERP_User_BP_ID')
  )
ORDER BY tb.tablename, c.columnname;

\echo 'Physical C_ContactActivity vehicle columns'
SELECT column_name, data_type, numeric_precision
FROM information_schema.columns
WHERE table_schema = 'adempiere'
  AND table_name = 'c_contactactivity'
  AND column_name ILIKE '%vehicle%';

\echo 'Activity tab templates'
SELECT w.ad_window_id, w.ad_window_uu, w.name AS window_name,
       t.ad_tab_id, t.ad_tab_uu, t.name AS tab_name, t.seqno,
       c.columnname AS link_column, COUNT(f.ad_field_id) AS field_count
FROM ad_window w
JOIN ad_tab t ON t.ad_window_id = w.ad_window_id
JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
LEFT JOIN ad_column c ON c.ad_column_id = t.ad_column_id
LEFT JOIN ad_field f ON f.ad_tab_id = t.ad_tab_id AND f.isactive = 'Y'
WHERE t.name = 'Activity'
  AND tb.tablename = 'C_ContactActivity'
GROUP BY w.ad_window_id, w.ad_window_uu, w.name,
         t.ad_tab_id, t.ad_tab_uu, t.name, t.seqno, c.columnname
ORDER BY w.name;

\echo 'Activity type reference values'
SELECT rl.ad_ref_list_id, rl.ad_ref_list_uu, rl.value, rl.name, rl.description
FROM ad_ref_list rl
JOIN ad_column c ON c.ad_reference_value_id = rl.ad_reference_id
JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
WHERE tb.tablename = 'C_ContactActivity'
  AND c.columnname = 'ContactActivityType'
  AND rl.value IN ('EM', 'ME', 'PC', 'CN', 'TA')
ORDER BY rl.value;

\echo 'Admin roles and Vehicle window access'
SELECT r.ad_role_id, r.ad_role_uu, r.name AS role_name,
       wa.ad_window_access_uu,
       wa.isactive, wa.isreadwrite
FROM ad_role r
CROSS JOIN ad_window w
LEFT JOIN ad_window_access wa
  ON wa.ad_role_id = r.ad_role_id
 AND wa.ad_window_id = w.ad_window_id
WHERE r.name IN ('AbilityERP Admin', 'Admin')
  AND w.name = 'Vehicle'
ORDER BY r.name;

\echo 'AD_Window_Access columns'
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'adempiere'
  AND table_name = 'ad_window_access'
ORDER BY ordinal_position;

\echo 'Activity parent-link field comparison'
SELECT w.name AS window_name, t.ad_tab_id, t.ad_column_id AS tab_link_column_id,
       c.columnname, c.isparent AS column_isparent,
       f.ad_field_id, f.defaultvalue, f.isdisplayed, f.isreadonly, f.ismandatory
FROM ad_window w
JOIN ad_tab t ON t.ad_window_id = w.ad_window_id
JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
JOIN ad_column c ON c.ad_column_id = t.ad_column_id
LEFT JOIN ad_field f
  ON f.ad_tab_id = t.ad_tab_id
 AND f.ad_column_id = t.ad_column_id
WHERE w.name IN ('Enquiry', 'Booking Generator', 'Vehicle')
  AND t.name = 'Activity'
  AND tb.tablename = 'C_ContactActivity'
ORDER BY w.name;
