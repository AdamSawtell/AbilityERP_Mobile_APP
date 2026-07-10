SET search_path TO adempiere;
SELECT f.seqno, f.name, f.isreadonly, c.columnname, t.issinglerow
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
ORDER BY f.seqno;
