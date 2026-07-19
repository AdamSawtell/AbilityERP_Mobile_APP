SET search_path TO adempiere;

-- Review rows
SELECT aberp_activityauditreview_id, ad_client_id, ad_org_id, isactive,
       c_contactactivity_id, matchedterms, reviewstatus, isreviewed
FROM aberp_activityauditreview
ORDER BY created DESC LIMIT 10;

-- Tab where / access
SELECT t.ad_tab_id, t.name, t.whereclause, t.ad_table_id, t.isactive,
       w.name AS window_name, w.ad_window_uu
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Activity Audit Review' OR t.ad_tab_uu = '27a02751-c0d4-4f01-8e15-000000000001';

-- Grid fields
SELECT f.name, c.columnname, f.isdisplayed, f.isdisplayedgrid, f.seqnogrid, f.isactive
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
WHERE t.ad_tab_uu = '27a02751-c0d4-4f01-8e15-000000000001'
ORDER BY COALESCE(f.seqnogrid, f.seqno);

-- Window access for Admin roles
SELECT r.name, wa.isreadwrite
FROM ad_window_access wa
JOIN ad_role r ON r.ad_role_id = wa.ad_role_id
JOIN ad_window w ON w.ad_window_id = wa.ad_window_id
WHERE w.name = 'Activity Audit Review';
