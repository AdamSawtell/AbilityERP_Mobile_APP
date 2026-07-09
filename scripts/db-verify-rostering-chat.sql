-- Verify Rostering Chat window install
SET search_path TO adempiere;

SELECT 'Window' AS check_type, w.ad_window_id, w.name, w.isactive
FROM ad_window w WHERE w.name = 'Rostering Chat';

SELECT 'Tabs' AS check_type, t.name, t.tablevel, t.isreadonly, t.isinsertrecord, t.whereclause
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat'
ORDER BY t.seqno;

SELECT 'Header fields' AS check_type, f.name, c.columnname, f.isdisplayed, f.isdisplayedgrid, f.isreadonly, f.seqno
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat' AND f.isactive = 'Y'
ORDER BY f.seqno;

SELECT 'Updates fields' AS check_type, f.name, c.columnname, f.isreadonly, f.seqno
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Updates' AND f.isactive = 'Y'
ORDER BY f.seqno;

SELECT 'Processes' AS check_type, p.value, p.name, p.classname
FROM ad_process p
WHERE p.value IN ('ROSTERING_CHAT_REPLY', 'ROSTERING_CHAT_CLOSE');

SELECT 'Access' AS check_type, p.value, r.name AS role_name, pa.isreadwrite
FROM ad_process_access pa
JOIN ad_process p ON p.ad_process_id = pa.ad_process_id
JOIN ad_role r ON r.ad_role_id = pa.ad_role_id
WHERE p.value IN ('ROSTERING_CHAT_REPLY', 'ROSTERING_CHAT_CLOSE') AND pa.isactive = 'Y'
ORDER BY p.value, r.name;

SELECT 'Menu' AS check_type, m.ad_menu_id, m.name, m.seqno, m.parent_id, w.name AS window_name
FROM ad_menu m
LEFT JOIN ad_window w ON w.ad_window_id = m.ad_window_id
WHERE m.name = 'Rostering Chat';

SELECT 'Sample threads' AS check_type, r.r_request_id, r.documentno, r.summary, rs.name AS status,
       u.name AS worker, r.lastresult, r.datelastaction
FROM r_request r
LEFT JOIN r_status rs ON rs.r_status_id = r.r_status_id
LEFT JOIN ad_user u ON u.ad_user_id = r.ad_user_id
WHERE r.aberp_rostered_shift_id IS NULL AND r.isactive = 'Y'
ORDER BY r.datelastaction DESC NULLS LAST, r.updated DESC
LIMIT 10;
