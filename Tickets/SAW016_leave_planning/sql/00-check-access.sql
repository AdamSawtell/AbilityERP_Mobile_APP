SELECT r.name, r.ad_client_id, wa.isreadwrite, wa.isactive
FROM ad_window_access wa
JOIN ad_role r ON r.ad_role_id=wa.ad_role_id AND r.ad_client_id=wa.ad_client_id
JOIN ad_window w ON w.ad_window_id=wa.ad_window_id
WHERE w.name='Leave Planning'
ORDER BY r.name;

SELECT m.ad_menu_id, m.name, m.isactive, m.action, m.ad_window_id, tn.parent_id, tn.ad_tree_id
FROM ad_menu m
LEFT JOIN ad_treenodemm tn ON tn.node_id=m.ad_menu_id
WHERE m.name LIKE 'Leave Planning%';
