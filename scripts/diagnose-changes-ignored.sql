SET search_path TO adempiere;

SELECT 'tab' AS t, t.name, t.isreadonly, t.isinsertrecord, t.issinglerow, t.isadvancedtab
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat'
ORDER BY t.seqno;

SELECT 'field' AS t, f.name, c.columnname, f.isreadonly, f.isupdateable, f.isdisplayed,
       c.isupdateable AS col_upd, c.isalwaysupdateable, c.ismandatory
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat' AND f.isdisplayed = 'Y'
ORDER BY f.seqno;

-- Window access
SELECT r.name, wa.isreadwrite, wa.isactive
FROM ad_window_access wa
JOIN ad_window w ON w.ad_window_id = wa.ad_window_id
JOIN ad_role r ON r.ad_role_id = wa.ad_role_id
WHERE w.name = 'Rostering Chat' AND wa.isactive = 'Y';
