SET search_path TO adempiere;

-- 1) Skip Dates window / tabs / tables
SELECT w.ad_window_id, w.name AS window_name, w.ad_window_uu,
       t.ad_tab_id, t.name AS tab_name, t.seqno, t.ad_tab_uu,
       tb.ad_table_id, tb.tablename, tb.ad_table_uu
FROM ad_window w
JOIN ad_tab t ON t.ad_window_id = w.ad_window_id
JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
WHERE w.name ILIKE '%Skip%Date%'
   OR tb.tablename ILIKE '%skip%date%'
   OR tb.tablename ILIKE 'aberp_date%'
   OR w.name ILIKE '%AbERP_Skip%'
ORDER BY w.name, t.seqno;

-- 2) Tables matching skip/dates
SELECT ad_table_id, tablename, name, ad_table_uu
FROM ad_table
WHERE tablename ILIKE '%skip%'
   OR tablename ILIKE 'aberp_date%'
   OR name ILIKE '%Skip%Date%'
ORDER BY tablename;

-- 3) Copy-related processes
SELECT ad_process_id, value, name, classname, copyfromprocess, ad_process_uu, entitytype
FROM ad_process
WHERE name ILIKE '%copy%'
   OR value ILIKE '%copy%'
   OR classname ILIKE '%Copy%'
   OR copyfromprocess = 'Y'
ORDER BY name;

-- 4) Service Booking window processes / buttons
SELECT w.name AS window_name, t.name AS tab_name, f.name AS field_name,
       c.columnname, c.ad_reference_id, p.value AS process_value, p.name AS process_name,
       p.classname, p.copyfromprocess
FROM ad_window w
JOIN ad_tab t ON t.ad_window_id = w.ad_window_id
JOIN ad_field f ON f.ad_tab_id = t.ad_tab_id
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
LEFT JOIN ad_process p ON p.ad_process_id = c.ad_process_id
WHERE w.name = 'Service Booking'
  AND (c.ad_reference_id = 28 OR p.ad_process_id IS NOT NULL OR f.name ILIKE '%copy%')
ORDER BY t.seqno, f.seqno;
