SET search_path TO adempiere;
SELECT w.name, t.name, c.columnname, f.isdisplayed, f.seqno, f.ad_field_uu
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name LIKE 'Activity Audit%' AND c.columnname = 'IsActive'
ORDER BY 1,2;
