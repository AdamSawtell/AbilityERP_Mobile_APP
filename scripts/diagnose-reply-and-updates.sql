SET search_path TO adempiere;

-- Process recent runs
SELECT pi.ad_pinstance_id, p.value, pi.created, pi.isprocessing, pi.result, LEFT(pi.errormsg, 200) AS err
FROM ad_pinstance pi
JOIN ad_process p ON p.ad_process_id = pi.ad_process_id
WHERE p.value IN ('ROSTERING_CHAT_REPLY', 'ROSTERING_CHAT_CLOSE')
ORDER BY pi.created DESC
LIMIT 10;

-- Standard Request Updates tab: how does link work?
SELECT w.name, t.name, t.ad_column_id, t.parent_column_id, t.whereclause, t.tablevel,
       tb.tablename
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
WHERE w.name = 'Request' AND t.name ILIKE '%update%';

-- R_Request_ID column ids
SELECT 'R_Request.R_Request_ID' AS which, c.ad_column_id
FROM ad_column c JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
WHERE tb.tablename = 'R_Request' AND c.columnname = 'R_Request_ID'
UNION ALL
SELECT 'R_RequestUpdate.R_Request_ID', c.ad_column_id
FROM ad_column c JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
WHERE tb.tablename = 'R_RequestUpdate' AND c.columnname = 'R_Request_ID';

-- Is R_Request_ID field on Updates tab?
SELECT f.name, c.columnname, f.isdisplayed, f.isdisplayedgrid
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Updates';

-- Process params / showhelp
SELECT p.value, p.showhelp, pp.name, pp.columnname, pp.defaultvalue, pp.seqno
FROM ad_process p
LEFT JOIN ad_process_para pp ON pp.ad_process_id = p.ad_process_id AND pp.isactive = 'Y'
WHERE p.value = 'ROSTERING_CHAT_REPLY';
