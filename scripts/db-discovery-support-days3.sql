-- SAW009 discovery round 3
SET search_path TO adempiere;

-- 1) Service Booking window structure
SELECT w.ad_window_id, w.ad_window_uu, w.name, tab.ad_tab_id, tab.ad_tab_uu, tab.name AS tab_name,
       tab.seqno, t.tablename
FROM ad_window w
JOIN ad_tab tab ON tab.ad_window_id = w.ad_window_id
JOIN ad_table t ON t.ad_table_id = tab.ad_table_id
WHERE w.name ILIKE '%Service Booking%' OR w.name ILIKE '%Booking%'
ORDER BY w.name, tab.seqno;

-- 2) Fields on Service Booking tabs that mention day / start / end / pattern
SELECT w.name AS window_name, tab.name AS tab_name, t.tablename, f.name AS field_name,
       c.columnname, c.ad_reference_id, c.ad_reference_value_id, rv.name AS ref_value_name,
       f.ad_field_uu, f.isdisplayed, f.seqno
FROM ad_field f
JOIN ad_tab tab ON tab.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
JOIN ad_table t ON t.ad_table_id = tab.ad_table_id
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
LEFT JOIN ad_reference rv ON rv.ad_reference_id = c.ad_reference_value_id
WHERE w.name ILIKE '%Service Booking%'
ORDER BY tab.seqno, f.seqno;

-- 3) Full list values for 14 Day Roster Period
SELECT r.ad_reference_id, r.ad_reference_uu, r.name,
       lv.value, lv.name AS list_name, lv.description, lv.ad_ref_list_uu, lv.isactive
FROM ad_reference r
JOIN ad_ref_list lv ON lv.ad_reference_id = r.ad_reference_id
WHERE r.ad_reference_id = 1001957
ORDER BY lv.value::int NULLS LAST, lv.value;

-- 4) How Support_Start_Day is populated on shifts (sample)
SELECT aberp_rostered_shift_id, aberp_support_start_day, aberp_support_end_day,
       aberp_rosterstartday, aberp_rosterendday
FROM aberp_rostered_shift
WHERE aberp_support_start_day IS NOT NULL
LIMIT 20;

-- 5) C_OrderLine link to service pattern + any day-like data on order lines
SELECT ol.c_orderline_id, ol.aberp_servicepattern_id,
       sp.aberp_rosterstartday, sp.aberp_rosterendday,
       ol.datepromised, ol.qtyentered, ol.priceentered
FROM c_orderline ol
JOIN aberp_servicepattern sp ON sp.aberp_servicepattern_id = ol.aberp_servicepattern_id
WHERE ol.isactive = 'Y'
LIMIT 20;

-- 6) Does C_Order have support day columns?
SELECT t.tablename, c.columnname, c.ad_reference_id, c.ad_reference_value_id, rv.name
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
LEFT JOIN ad_reference rv ON rv.ad_reference_id = c.ad_reference_value_id
WHERE t.tablename IN ('C_Order', 'C_OrderLine')
  AND (c.columnname ILIKE '%day%' OR c.columnname ILIKE '%roster%')
ORDER BY t.tablename, c.columnname;

-- 7) Reference used by weekday-only displays?
SELECT DISTINCT aberp_support_start_day, aberp_support_end_day, count(*)
FROM aberp_rostered_shift
WHERE aberp_support_start_day IS NOT NULL
GROUP BY 1, 2
ORDER BY 1, 2
LIMIT 50;
