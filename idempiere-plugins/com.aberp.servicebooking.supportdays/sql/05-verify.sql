-- SAW009 verify
SET search_path TO adempiere;

SELECT c.columnname, c.ad_column_uu, c.ad_reference_id, c.ad_reference_value_id, r.name AS list_name
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
LEFT JOIN ad_reference r ON r.ad_reference_id = c.ad_reference_value_id
WHERE t.tablename = 'C_OrderLine'
  AND c.columnname IN ('AbERP_Support_Start_Day', 'AbERP_Support_End_Day')
ORDER BY c.columnname;

SELECT f.name, f.ad_field_uu, f.seqno, f.isdisplayed, c.columnname
FROM ad_field f
JOIN ad_tab tab ON tab.ad_tab_id = f.ad_tab_id
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE tab.ad_tab_uu = '8b044105-bc30-4f81-b0d6-a45835d82f98'
  AND c.columnname IN ('AbERP_Support_Start_Day', 'AbERP_Support_End_Day')
ORDER BY f.seqno;

SELECT tgname FROM pg_trigger
WHERE tgname = 'tr_aberp_c_orderline_copy_pattern_days';

-- Sample resolve: pattern day → list name (what WebUI should show)
SELECT sp.aberp_servicepattern_id,
       sp.aberp_rosterstartday AS start_value, rs.name AS start_display,
       sp.aberp_rosterendday AS end_value, re.name AS end_display
FROM aberp_servicepattern sp
LEFT JOIN ad_ref_list rs ON rs.ad_reference_id = (
  SELECT ad_reference_id FROM ad_reference WHERE ad_reference_uu = '5ec1b0b5-7ce8-43dc-bf9d-77bc2d7afbbd'
) AND rs.value = sp.aberp_rosterstartday
LEFT JOIN ad_ref_list re ON re.ad_reference_id = (
  SELECT ad_reference_id FROM ad_reference WHERE ad_reference_uu = '5ec1b0b5-7ce8-43dc-bf9d-77bc2d7afbbd'
) AND re.value = sp.aberp_rosterendday
WHERE sp.isactive = 'Y'
ORDER BY sp.aberp_servicepattern_id
LIMIT 10;
