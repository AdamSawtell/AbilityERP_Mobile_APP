SET search_path TO adempiere;

SELECT c.columnname, c.ad_reference_id, c.ad_process_id, p.value AS process_value, p.name AS process_name,
       c.isupdateable, c.iscolumnencrypted, c.columnsql
FROM ad_column c
LEFT JOIN ad_process p ON p.ad_process_id = c.ad_process_id
WHERE c.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename='AbERP_ActivityAuditReview')
  AND (c.columnname IN ('Processing','AbERP_OpenActivity','Processed') OR c.ad_process_id IS NOT NULL OR c.columnsql IS NOT NULL)
ORDER BY c.columnname;

-- Any toolbar buttons
SELECT tb.name, tb.componentname, tb.isactive, p.value
FROM ad_toolbarbutton tb
LEFT JOIN ad_process p ON p.ad_process_id = tb.ad_process_id
JOIN ad_tab t ON t.ad_tab_id = tb.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Activity Audit Review';
