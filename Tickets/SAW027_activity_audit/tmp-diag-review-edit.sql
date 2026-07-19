SET search_path TO adempiere;

-- Field + column updateability on Reviews tab
SELECT f.seqno, f.name, c.columnname,
       f.isreadonly AS field_ro, c.isupdateable AS col_upd,
       f.isdisplayed, f.isalwaysupdateable
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Activity Audit Review' AND t.name = 'Reviews'
ORDER BY f.seqno;

SELECT t.name, t.isreadonly AS tab_ro, t.isinsertrecord, t.isadvancedtab,
       w.windowtype, w.issotrx
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Activity Audit Review';

-- Role access
SELECT r.name, wa.isreadwrite, wa.isactive
FROM ad_window_access wa
JOIN ad_role r ON r.ad_role_id = wa.ad_role_id
JOIN ad_window w ON w.ad_window_id = wa.ad_window_id
WHERE w.name = 'Activity Audit Review'
ORDER BY r.name;

-- Table access
SELECT r.name, ta.isreadonly, ta.isexclude, ta.iscanexport, ta.iscanreport
FROM ad_table_access ta
JOIN ad_role r ON r.ad_role_id = ta.ad_role_id
JOIN ad_table t ON t.ad_table_id = ta.ad_table_id
WHERE t.tablename = 'AbERP_ActivityAuditReview'
ORDER BY r.name;

SELECT tablename, isdeleteable, isview, accesslevel
FROM ad_table WHERE tablename = 'AbERP_ActivityAuditReview';
