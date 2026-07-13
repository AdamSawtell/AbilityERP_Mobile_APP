SET search_path TO adempiere;

SELECT c.columnname, c.istoolbarbutton, c.ad_process_id, p.value, p.classname
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
LEFT JOIN ad_process p ON p.ad_process_id = c.ad_process_id
WHERE t.tablename = 'AbERP_Skip_Dates' AND c.columnname = 'AbERP_CopyDatesFrom';

SELECT f.name, f.isdisplayed, f.istoolbarbutton, f.seqno, f.isactive
FROM ad_field f
WHERE f.ad_field_uu = '15a01504-c0d4-4f01-8e15-000000000004'
   OR f.name = 'Copy Dates From';

SELECT r.name, pa.isreadwrite
FROM ad_process_access pa
JOIN ad_process p ON p.ad_process_id = pa.ad_process_id
JOIN ad_role r ON r.ad_role_id = pa.ad_role_id
WHERE p.value = 'AbERP_SkipDates_CopyDatesFrom'
ORDER BY r.name;

-- Compare Order CopyFrom field config
SELECT f.name, f.isdisplayed, f.istoolbarbutton AS field_tb, c.istoolbarbutton AS col_tb, c.columnname
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Service Booking' AND t.name = 'Service Booking' AND c.columnname = 'CopyFrom';
