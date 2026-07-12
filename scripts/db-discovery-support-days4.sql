-- SAW009 discovery round 4: generator + identifiers + weekday lists
SET search_path TO adempiere;

-- 1) AbERP_ServicePattern table identifiers / display
SELECT c.columnname, c.isidentifier, c.seqno, c.iskey, c.isselectioncolumn, c.ad_reference_id, c.ad_reference_value_id
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'AbERP_ServicePattern'
ORDER BY c.isidentifier DESC, c.seqno, c.columnname;

-- 2) Table reference for AbERP_ServicePattern search on C_OrderLine
SELECT c.columnname, c.ad_reference_id, c.ad_reference_value_id, rv.name, rv.ad_reference_uu,
       rt.ad_table_id, tb.tablename, rt.ad_display, dc.columnname AS display_col,
       rt.whereclause, rt.orderbyclause
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
LEFT JOIN ad_reference rv ON rv.ad_reference_id = c.ad_reference_value_id
LEFT JOIN ad_ref_table rt ON rt.ad_reference_id = rv.ad_reference_id
LEFT JOIN ad_table tb ON tb.ad_table_id = rt.ad_table_id
LEFT JOIN ad_column dc ON dc.ad_column_id = rt.ad_display
WHERE t.tablename = 'C_OrderLine' AND c.columnname = 'AbERP_ServicePattern_ID';

-- 3) Booking generator process
SELECT p.ad_process_id, p.ad_process_uu, p.name, p.classname, p.procedurename, p.value
FROM ad_process p
WHERE p.name ILIKE '%booking%' OR p.classname ILIKE '%booking%' OR p.value ILIKE '%booking%'
ORDER BY p.name;

-- 4) Elements for Support Start/End Day
SELECT e.ad_element_id, e.ad_element_uu, e.columnname, e.name, e.printname
FROM ad_element e
WHERE e.columnname IN ('AbERP_Support_Start_Day','AbERP_Support_End_Day','AbERP_RosterStartDay','AbERP_RosterEndDay')
ORDER BY e.columnname;

-- 5) Any weekday-only reference list
SELECT r.ad_reference_id, r.ad_reference_uu, r.name, lv.value, lv.name AS list_name
FROM ad_reference r
JOIN ad_ref_list lv ON lv.ad_reference_id = r.ad_reference_id
WHERE (r.name ILIKE '%week%day%' OR r.name ILIKE 'Weekday%' OR r.name = 'Weekdays'
       OR (lv.name IN ('Monday','Tuesday','Wednesday') AND lv.value IN ('1','2','3','Monday')))
ORDER BY r.name, lv.value
LIMIT 80;

-- 6) Advanced search bookings view columns for days
SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='aberp_orderline_adv_search_v'
  AND (column_name ILIKE '%day%' OR column_name ILIKE '%pattern%' OR column_name ILIKE '%roster%')
ORDER BY 1;

-- 7) Sample: resolve pattern day list names
SELECT sp.aberp_servicepattern_id, sp.aberp_rosterstartday, rs.name AS start_name,
       sp.aberp_rosterendday, re.name AS end_name
FROM aberp_servicepattern sp
LEFT JOIN ad_ref_list rs ON rs.ad_reference_id = 1001957 AND rs.value = sp.aberp_rosterstartday
LEFT JOIN ad_ref_list re ON re.ad_reference_id = 1001957 AND re.value = sp.aberp_rosterendday
WHERE sp.isactive='Y'
LIMIT 20;

-- 8) Count order lines with service pattern link
SELECT COUNT(*) AS ol_with_pattern FROM c_orderline WHERE aberp_servicepattern_id IS NOT NULL;
SELECT COUNT(*) AS ol_total FROM c_orderline WHERE isactive='Y';

-- 9) Does list go past 15? Any 28-day list?
SELECT r.ad_reference_id, r.name, COUNT(*) 
FROM ad_reference r JOIN ad_ref_list lv ON lv.ad_reference_id=r.ad_reference_id
WHERE r.name ILIKE '%day%' OR r.name ILIKE '%roster%' OR r.name ILIKE '%pattern%'
GROUP BY 1,2 ORDER BY 2;
