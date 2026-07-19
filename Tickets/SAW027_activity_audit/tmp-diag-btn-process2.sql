SET search_path TO adempiere;
SELECT c.columnname, c.ad_reference_id, c.ad_process_id, p.value AS process_value,
       c.isupdateable, c.columnsql, c.defaultvalue
FROM ad_column c
LEFT JOIN ad_process p ON p.ad_process_id = c.ad_process_id
WHERE c.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename='AbERP_ActivityAuditReview')
  AND (c.columnname IN ('Processing','AbERP_OpenActivity','Processed') OR c.ad_process_id IS NOT NULL OR COALESCE(c.columnsql,'') <> '')
ORDER BY c.columnname;
