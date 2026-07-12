-- SAW009 discovery round 2: Service Booking Line day columns + list values
SET search_path TO adempiere;

-- 1) All C_OrderLine columns with day/roster/support/pattern
SELECT c.columnname, c.ad_column_id, c.ad_column_uu, c.ad_reference_id, c.ad_reference_value_id,
       c.ad_val_rule_id, c.columnsql, c.fieldlength,
       r.name AS ref_name, rv.name AS ref_value_name
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
LEFT JOIN ad_reference r ON r.ad_reference_id = c.ad_reference_id
LEFT JOIN ad_reference rv ON rv.ad_reference_id = c.ad_reference_value_id
WHERE t.tablename = 'C_OrderLine'
  AND (c.columnname ILIKE '%day%' OR c.columnname ILIKE '%roster%' OR c.columnname ILIKE '%support%'
       OR c.columnname ILIKE '%pattern%' OR c.columnname ILIKE '%aberp%')
ORDER BY c.columnname;

-- 2) Service Booking window tabs/fields with day
SELECT w.name AS window_name, tab.name AS tab_name, tab.tablename, f.name AS field_name,
       c.columnname, c.ad_reference_id, c.ad_reference_value_id, rv.name AS ref_value_name,
       f.ad_field_uu, f.isdisplayed, f.seqno
FROM ad_field f
JOIN ad_tab tab ON tab.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
LEFT JOIN ad_reference rv ON rv.ad_reference_id = c.ad_reference_value_id
WHERE w.name ILIKE '%Service Booking%'
  AND (c.columnname ILIKE '%day%' OR f.name ILIKE '%day%' OR c.columnname ILIKE '%roster%' OR f.name ILIKE '%start%' OR f.name ILIKE '%end%')
ORDER BY tab.seqno, f.seqno;

-- 3) Reference list 14 Day Roster Period values (what Service Pattern shows)
SELECT r.ad_reference_id, r.ad_reference_uu, r.name,
       lv.value, lv.name AS list_name, lv.description, lv.ad_ref_list_uu, lv.seqno, lv.isactive
FROM ad_reference r
JOIN ad_ref_list lv ON lv.ad_reference_id = r.ad_reference_id
WHERE r.ad_reference_id = 1001957 OR r.name ILIKE '%14 Day Roster%' OR r.name ILIKE '%Roster Period%'
ORDER BY r.name, lv.seqno, lv.value;

-- 4) Where is AbERP_Support_Start_Day defined (which table)?
SELECT t.tablename, c.columnname, c.ad_column_uu, c.ad_reference_id, c.ad_reference_value_id,
       rv.name AS ref_value_name, c.columnsql
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
LEFT JOIN ad_reference rv ON rv.ad_reference_id = c.ad_reference_value_id
WHERE c.columnname IN ('AbERP_Support_Start_Day', 'AbERP_Support_End_Day',
                       'AbERP_RosterStartDay', 'AbERP_RosterEndDay')
ORDER BY t.tablename, c.columnname;

-- 5) Sample service pattern day values
SELECT aberp_servicepattern_id, aberp_rosterstartday, aberp_rosterendday, description, m_product_id
FROM aberp_servicepattern
WHERE isactive = 'Y'
ORDER BY aberp_bookinggenerator_id, aberp_rosterstartday
LIMIT 40;

-- 6) Any other day lists (Weekday only vs numbered)
SELECT r.ad_reference_id, r.ad_reference_uu, r.name, COUNT(lv.*) AS list_count,
       string_agg(lv.value || '=' || lv.name, ', ' ORDER BY lv.seqno, lv.value) AS sample_values
FROM ad_reference r
LEFT JOIN ad_ref_list lv ON lv.ad_reference_id = r.ad_reference_id AND lv.isactive = 'Y'
WHERE r.name ILIKE '%day%' OR r.name ILIKE '%weekday%' OR r.name ILIKE '%roster%'
GROUP BY r.ad_reference_id, r.ad_reference_uu, r.name
ORDER BY r.name;
