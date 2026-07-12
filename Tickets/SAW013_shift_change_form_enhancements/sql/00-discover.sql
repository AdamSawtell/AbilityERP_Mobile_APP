-- SAW013 discovery: AbERP_ShiftChange ↔ R_Request
\echo === TABLE AbERP_ShiftChange ===
SELECT t.ad_table_id, t.tablename, t.ad_table_uu, t.isview, t.entitytype
FROM ad_table t
WHERE lower(t.tablename) LIKE '%shiftchange%'
   OR lower(t.tablename) LIKE '%shift_change%'
   OR t.tablename ILIKE 'AbERP_Shift%';

\echo === WINDOW AbERP_ShiftChange ===
SELECT w.ad_window_id, w.name, w.ad_window_uu, w.entitytype
FROM ad_window w
WHERE w.name ILIKE '%Shift Change%'
   OR w.name ILIKE '%ShiftChange%'
   OR w.ad_window_id = 1000008;

\echo === TABS on window ===
SELECT tab.ad_tab_id, tab.name, tab.ad_tab_uu, tab.ad_table_id, t.tablename,
       tab.seqno, tab.tablevel, tab.whereclause, tab.ad_column_id, tab.parent_column_id
FROM ad_tab tab
JOIN ad_table t ON t.ad_table_id = tab.ad_table_id
WHERE tab.ad_window_id IN (
  SELECT ad_window_id FROM ad_window
  WHERE name ILIKE '%Shift Change%' OR ad_window_id = 1000008
)
ORDER BY tab.seqno;

\echo === COLUMNS on AbERP_ShiftChange (status / request related) ===
SELECT c.ad_column_id, c.columnname, c.name, c.ad_reference_id, c.ad_reference_value_id,
       c.iscolumnsql, c.columnsql, c.isupdateable, c.ismandatory, c.ad_column_uu, c.fieldlength
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename ILIKE 'AbERP_ShiftChange'
ORDER BY c.columnname;

\echo === ALL AbERP_ShiftChange columns (brief) ===
SELECT c.columnname, c.ad_reference_id, LEFT(COALESCE(c.columnsql,''),80) AS columnsql,
       c.iscolumnsql, c.isupdateable
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename ILIKE 'AbERP_ShiftChange'
ORDER BY c.columnname;

\echo === FIELDS on main Shift Change tab ===
SELECT f.ad_field_id, f.name, c.columnname, f.displaylogic, f.isreadonly, f.isdisplayed,
       f.seqno, f.ad_field_uu
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab tab ON tab.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
WHERE (w.name ILIKE '%Shift Change%' OR w.ad_window_id = 1000008)
  AND tab.tablevel = 0
ORDER BY f.seqno;

\echo === PROCESS buttons / Create Request ===
SELECT p.ad_process_id, p.value, p.name, p.classname, p.ad_process_uu,
       c.columnname, c.ad_column_id
FROM ad_process p
LEFT JOIN ad_column c ON c.ad_process_id = p.ad_process_id
LEFT JOIN ad_table t ON t.ad_table_id = c.ad_table_id AND t.tablename ILIKE 'AbERP_ShiftChange'
WHERE p.name ILIKE '%Create Request%'
   OR p.value ILIKE '%ShiftChange%'
   OR p.name ILIKE '%Shift Change%'
   OR p.classname ILIKE '%ShiftChange%'
   OR p.value ILIKE '%CreateRequest%';

\echo === R_Request link columns pointing at ShiftChange ===
SELECT c.columnname, c.ad_reference_id, c.ad_reference_value_id, c.fktable_id,
       t.tablename, c.columnsql, c.iscolumnsql
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'R_Request'
  AND (
    c.columnname ILIKE '%ShiftChange%'
    OR c.columnname ILIKE '%Record_ID%'
    OR c.columnname = 'AD_Table_ID'
    OR c.columnname ILIKE '%AbERP%'
  )
ORDER BY c.columnname;

\echo === Sample AbERP_ShiftChange rows + linked requests ===
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'adempiere' AND table_name = 'aberp_shiftchange'
ORDER BY ordinal_position;
