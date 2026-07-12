-- SAW009 discovery: Support Start/End Day vs Service Pattern day display
SET search_path TO adempiere;

-- 1) C_OrderLine columns for support days
SELECT c.columnname, c.ad_column_id, c.ad_column_uu, c.ad_reference_id, c.ad_reference_value_id,
       c.ad_val_rule_id, c.fkconstraintname, c.isautocomplete, c.columnsql, c.fieldlength,
       c.ad_element_id, e.name AS element_name, e.printname,
       r.name AS ref_name, rv.name AS ref_value_name
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
LEFT JOIN ad_element e ON e.ad_element_id = c.ad_element_id
LEFT JOIN ad_reference r ON r.ad_reference_id = c.ad_reference_id
LEFT JOIN ad_reference rv ON rv.ad_reference_id = c.ad_reference_value_id
WHERE t.tablename = 'C_OrderLine'
  AND c.columnname ILIKE '%Support%Day%';

-- 2) AbERP_ServicePattern day-related columns
SELECT c.columnname, c.ad_column_id, c.ad_column_uu, c.ad_reference_id, c.ad_reference_value_id,
       c.ad_val_rule_id, c.columnsql, c.fieldlength, c.isidentifier, c.seqno,
       r.name AS ref_name, rv.name AS ref_value_name
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
LEFT JOIN ad_reference r ON r.ad_reference_id = c.ad_reference_id
LEFT JOIN ad_reference rv ON rv.ad_reference_id = c.ad_reference_value_id
WHERE t.tablename ILIKE '%ServicePattern%'
ORDER BY c.columnname;

-- 3) Identifier columns on AbERP_ServicePattern
SELECT c.columnname, c.isidentifier, c.seqno, c.ad_reference_id, c.columnsql
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'AbERP_ServicePattern'
  AND (c.isidentifier = 'Y' OR c.columnname ILIKE '%day%' OR c.columnname ILIKE '%name%' OR c.columnname ILIKE '%seq%')
ORDER BY c.isidentifier DESC, c.seqno NULLS LAST, c.columnname;

-- 4) Fields on Service Booking Line window for support days
SELECT w.name AS window_name, tab.name AS tab_name, f.name AS field_name, f.ad_field_uu,
       c.columnname, f.displaylogic, f.isdisplayed, f.seqno
FROM ad_field f
JOIN ad_tab tab ON tab.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE c.columnname IN ('AbERP_Support_Start_Day', 'AbERP_Support_End_Day')
ORDER BY w.name, tab.name, f.seqno;

-- 5) Fields on Booking Generator / Service Pattern for day display
SELECT w.name AS window_name, tab.name AS tab_name, f.name AS field_name, f.ad_field_uu,
       c.columnname, c.ad_reference_id, c.ad_reference_value_id, c.columnsql, f.isdisplayed
FROM ad_field f
JOIN ad_tab tab ON tab.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE (w.name ILIKE '%Booking Generator%' OR w.name ILIKE '%Service Pattern%' OR tab.name ILIKE '%Service Pattern%')
  AND (c.columnname ILIKE '%day%' OR c.columnname ILIKE '%name%' OR f.name ILIKE '%day%')
ORDER BY w.name, tab.seqno, f.seqno;

-- 6) Sample AbERP_ServicePattern rows (day columns)
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'adempiere' AND table_name = 'aberp_servicepattern'
ORDER BY ordinal_position;

-- 7) Sample C_OrderLine support day values
SELECT ol.c_orderline_id, ol.aberp_support_start_day, ol.aberp_support_end_day,
       ol.aberp_servicepattern_id,
       sp.aberp_servicepattern_id AS sp_id
FROM c_orderline ol
LEFT JOIN aberp_servicepattern sp ON sp.aberp_servicepattern_id = ol.aberp_servicepattern_id
WHERE ol.aberp_support_start_day IS NOT NULL
LIMIT 20;
