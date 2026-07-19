SET search_path TO adempiere;

SELECT f.seqno, f.name, c.columnname, f.isreadonly AS field_ro, c.isupdateable AS col_upd, f.isdisplayed
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Activity Audit Terms' AND t.name = 'Audit Terms'
ORDER BY f.seqno;

SELECT t.name, t.isreadonly, t.isinsertrecord
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Activity Audit Terms';

SELECT r.name, wa.isreadwrite
FROM ad_window_access wa
JOIN ad_role r ON r.ad_role_id = wa.ad_role_id
JOIN ad_window w ON w.ad_window_id = wa.ad_window_id
WHERE w.name = 'Activity Audit Terms';
