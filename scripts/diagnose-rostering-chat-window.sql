SET search_path TO adempiere;

-- Chat tab fields
SELECT f.seqno, f.name, f.isdisplayed, f.isdisplayedgrid, c.columnname
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
ORDER BY f.seqno;

-- Updates tab config
SELECT t.ad_tab_id, t.name, t.tablevel, t.ad_column_id, t.parent_column_id,
       tc.columnname AS tab_link_col, pc.columnname AS parent_col,
       t.isreadonly, t.isinsertrecord
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
LEFT JOIN ad_column tc ON tc.ad_column_id = t.ad_column_id
LEFT JOIN ad_column pc ON pc.ad_column_id = t.parent_column_id
WHERE w.name = 'Rostering Chat';

-- Updates tab fields
SELECT f.seqno, f.name, f.isdisplayed, c.columnname
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Updates'
ORDER BY f.seqno;

-- Button columns
SELECT c.columnname, c.ad_reference_id, r.name AS ref_name, c.ad_process_id, p.value AS process_value
FROM ad_column c
JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id AND tb.tablename = 'R_Request'
LEFT JOIN ad_reference r ON r.ad_reference_id = c.ad_reference_id
LEFT JOIN ad_process p ON p.ad_process_id = c.ad_process_id
WHERE c.columnname IN ('AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat');

-- Message history for thread 1000088
SELECT ru.r_requestupdate_id, ru.created, u.name AS author, LEFT(ru.result, 80) AS result_preview
FROM r_requestupdate ru
LEFT JOIN ad_user u ON u.ad_user_id = ru.createdby
WHERE ru.r_request_id = 1000088 AND ru.isactive = 'Y'
ORDER BY ru.created;
