SET search_path TO adempiere;

SELECT f.name, c.columnname, f.isreadonly, f.readonlylogic, f.displaylogic,
       c.isupdateable, c.readonlylogic AS col_rol
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Activity Audit Review' AND t.name = 'Reviews'
  AND c.columnname IN ('ReviewStatus','IsReviewed','ReviewNotes','IsFollowUpRequired','MatchedTerms')
ORDER BY f.seqno;

SELECT t.name, t.isreadonly, t.readonlylogic, t.whereclause, t.ad_table_id
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Activity Audit Review';

-- Role column access excludes?
SELECT r.name, ca.isreadonly, ca.isexclude, c.columnname
FROM ad_column_access ca
JOIN ad_role r ON r.ad_role_id = ca.ad_role_id
JOIN ad_column c ON c.ad_column_id = ca.ad_column_id
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'AbERP_ActivityAuditReview';
