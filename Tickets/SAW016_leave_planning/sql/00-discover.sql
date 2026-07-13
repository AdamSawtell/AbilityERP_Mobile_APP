-- SAW016 discovery: AbERP_Unavailability_Leave schema + window
\echo === TABLE COLUMNS ===
SELECT column_name, data_type, udt_name, is_nullable
FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name=lower('AbERP_Unavailability_Leave')
ORDER BY ordinal_position;

\echo === AD_TABLE / AD_COLUMN (key fields) ===
SELECT t.ad_table_id, t.tablename, t.name, t.ad_window_id, t.ad_table_uu
FROM ad_table t WHERE upper(t.tablename)=upper('AbERP_Unavailability_Leave');

SELECT c.columnname, c.name, c.ad_reference_id, c.ad_reference_value_id, c.ismandatory, c.isupdateable,
       c.isselectioncolumn, c.ad_val_rule_id, c.columnsql IS NOT NULL AS has_columnsql,
       c.ad_column_uu
FROM ad_column c
JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE upper(t.tablename)=upper('AbERP_Unavailability_Leave')
ORDER BY c.seqno, c.columnname;

\echo === WINDOWS / TABS ===
SELECT w.ad_window_id, w.name, w.ad_window_uu, w.windowtype, w.issotrx
FROM ad_window w
WHERE w.name ILIKE '%unavail%' OR w.name ILIKE '%leave%'
ORDER BY w.name;

SELECT w.name AS window_name, tab.name AS tab_name, tab.ad_tab_id, tab.ad_table_id, tab.seqno,
       tab.whereclause, tab.orderbyclause, tab.ad_tab_uu, tbl.tablename
FROM ad_tab tab
JOIN ad_window w ON w.ad_window_id=tab.ad_window_id
JOIN ad_table tbl ON tbl.ad_table_id=tab.ad_table_id
WHERE w.name ILIKE '%unavail%' OR w.name ILIKE '%leave%' OR upper(tbl.tablename)=upper('AbERP_Unavailability_Leave')
ORDER BY w.name, tab.seqno;
