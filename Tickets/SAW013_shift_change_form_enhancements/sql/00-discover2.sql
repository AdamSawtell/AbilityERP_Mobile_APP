-- SAW013 discovery round 2
\echo === WINDOW by Shift Change name / menu ===
SELECT w.ad_window_id, w.name, w.ad_window_uu, w.entitytype
FROM ad_window w
WHERE w.name ILIKE '%Shift%Change%'
   OR w.name ILIKE '%Shift Change%'
   OR w.name ILIKE '%Change Request%'
   OR w.name ILIKE '%Forms%'
ORDER BY w.name;

\echo === MENU Shift Change ===
SELECT m.ad_menu_id, m.name, m.action, m.ad_window_id, m.ad_process_id, m.ad_menu_uu
FROM ad_menu m
WHERE m.name ILIKE '%Shift%Change%'
   OR m.name ILIKE '%Shift Change%'
   OR m.name ILIKE '%Forms and Approval%'
ORDER BY m.name;

\echo === TABS for AbERP_ShiftChange table ===
SELECT w.ad_window_id, w.name AS window_name, tab.ad_tab_id, tab.name AS tab_name,
       tab.ad_tab_uu, tab.seqno, tab.tablevel, tab.whereclause,
       tab.ad_column_id, pc.columnname AS link_column,
       tab.parent_column_id, ppc.columnname AS parent_column
FROM ad_tab tab
JOIN ad_table t ON t.ad_table_id = tab.ad_table_id
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
LEFT JOIN ad_column pc ON pc.ad_column_id = tab.ad_column_id
LEFT JOIN ad_column ppc ON ppc.ad_column_id = tab.parent_column_id
WHERE t.tablename = 'AbERP_ShiftChange'
ORDER BY w.ad_window_id, tab.seqno;

\echo === CHILD TABS under Shift Change windows ===
SELECT w.ad_window_id, w.name AS window_name, tab.ad_tab_id, tab.name, tab.tablevel,
       t.tablename, tab.whereclause, tab.ad_column_id, c.columnname AS link_col,
       tab.parent_column_id, pc.columnname AS parent_col
FROM ad_tab tab
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
JOIN ad_table t ON t.ad_table_id = tab.ad_table_id
LEFT JOIN ad_column c ON c.ad_column_id = tab.ad_column_id
LEFT JOIN ad_column pc ON pc.ad_column_id = tab.parent_column_id
WHERE tab.ad_window_id IN (
  SELECT DISTINCT tab2.ad_window_id
  FROM ad_tab tab2
  JOIN ad_table t2 ON t2.ad_table_id = tab2.ad_table_id
  WHERE t2.tablename = 'AbERP_ShiftChange'
)
ORDER BY w.ad_window_id, tab.seqno;

\echo === COLUMNS AbERP_ShiftChange ===
SELECT c.ad_column_id, c.columnname, c.name, c.ad_reference_id, c.ad_reference_value_id,
       c.columnsql IS NOT NULL AS has_columnsql,
       LEFT(COALESCE(c.columnsql,''), 120) AS columnsql,
       c.isupdateable, c.ismandatory, c.ad_process_id, c.ad_column_uu, c.fieldlength
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'AbERP_ShiftChange'
ORDER BY c.columnname;

\echo === PHYSICAL columns on aberp_shiftchange ===
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'adempiere' AND table_name = 'aberp_shiftchange'
ORDER BY ordinal_position;

\echo === PROCESSES related ===
SELECT p.ad_process_id, p.value, p.name, p.classname, p.ad_process_uu, p.entitytype
FROM ad_process p
WHERE p.name ILIKE '%Shift Change%'
   OR p.name ILIKE '%Create Request%'
   OR p.value ILIKE '%ShiftChange%'
   OR p.value ILIKE '%CreateRequest%'
   OR p.classname ILIKE '%ShiftChange%'
   OR p.classname ILIKE '%CreateRequest%'
ORDER BY p.name;

\echo === Button columns on ShiftChange ===
SELECT c.ad_column_id, c.columnname, c.ad_reference_id, c.ad_process_id, p.name AS process_name,
       c.istoolbarbutton, c.ad_column_uu
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
LEFT JOIN ad_process p ON p.ad_process_id = c.ad_process_id
WHERE t.tablename = 'AbERP_ShiftChange'
  AND (c.ad_reference_id = 28 OR c.ad_process_id IS NOT NULL OR c.columnname ILIKE '%Request%' OR c.columnname ILIKE '%Status%');
