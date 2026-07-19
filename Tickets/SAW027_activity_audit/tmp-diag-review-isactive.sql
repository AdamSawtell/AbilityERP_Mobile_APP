SET search_path TO adempiere;

SELECT t.ad_tab_id, t.name, t.ad_tab_uu, t.ad_table_id
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Activity Audit Review';

SELECT ad_column_id, columnname FROM ad_column
WHERE ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename='AbERP_ActivityAuditReview')
  AND columnname = 'IsActive';

SELECT f.ad_field_id, f.name, f.ad_field_uu, f.isdisplayed, f.seqno, c.columnname, f.ad_tab_id
FROM ad_field f
LEFT JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE f.ad_field_uu = '27a02751-f018-4f01-8e15-000000000001'
   OR f.ad_tab_id = 1000376 AND c.columnname = 'IsActive';

SELECT f.seqno, f.name, c.columnname, f.isdisplayed
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE f.ad_tab_id = 1000376
ORDER BY f.seqno;
