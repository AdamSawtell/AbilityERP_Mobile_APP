SET search_path TO adempiere, public;

-- Post-install checks for Rostering Chat (agent / pack verify)
-- Expect non-empty rows for each section on a healthy deploy.

SELECT 'window' AS check_type, ad_window_id, name, isactive
FROM ad_window WHERE name = 'Rostering Chat';

SELECT 'tabs' AS check_type, t.name, t.ad_tabtype, t.issinglerow, t.whereclause
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat'
ORDER BY t.seqno;

SELECT 'processes' AS check_type, value, name, classname, isactive
FROM ad_process
WHERE value IN ('AbERP_RosteringChat_Send', 'AbERP_RosteringChat_Close')
ORDER BY value;

SELECT 'process_access' AS check_type, p.value, r.name AS role, pa.isreadwrite
FROM ad_process_access pa
JOIN ad_process p ON p.ad_process_id = pa.ad_process_id
JOIN ad_role r ON r.ad_role_id = pa.ad_role_id
WHERE p.value IN ('AbERP_RosteringChat_Send', 'AbERP_RosteringChat_Close')
  AND pa.isactive = 'Y'
ORDER BY p.value, r.name;

SELECT 'window_access' AS check_type, w.name AS window, r.name AS role, wa.isreadwrite
FROM ad_window_access wa
JOIN ad_window w ON w.ad_window_id = wa.ad_window_id
JOIN ad_role r ON r.ad_role_id = wa.ad_role_id
WHERE w.name = 'Rostering Chat' AND wa.isactive = 'Y'
ORDER BY r.name;

SELECT 'request_type' AS check_type, r_requesttype_id, name, isactive
FROM r_requesttype WHERE name = 'Rostering Chat';

SELECT 'rostering_officer_role' AS check_type, ad_role_id, name,
       CASE WHEN ad_role_id = 1000012 THEN 'OK matches hardcode' ELSE 'WARN ID != 1000012 — patch Chat Assigned SQL' END AS note
FROM ad_role WHERE name = 'Rostering Officer';

SELECT 'grid_fields' AS check_type, f.seqnogrid, f.name, c.columnname
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat' AND f.isdisplayedgrid = 'Y'
ORDER BY f.seqnogrid;

SELECT 'buttons' AS check_type, f.name, c.columnname, f.xposition, f.issameline, f.isdisplayedgrid
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname IN ('AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat')
ORDER BY f.xposition;

SELECT 'user_queries' AS check_type, name, isdefault, left(code, 80) AS code
FROM ad_userquery
WHERE ad_tab_id = (
  SELECT t.ad_tab_id FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
)
ORDER BY isdefault DESC, name;

SELECT 'menu' AS check_type, m.ad_menu_id, m.name, m.isactive
FROM ad_menu m WHERE m.name = 'Rostering Chat';
