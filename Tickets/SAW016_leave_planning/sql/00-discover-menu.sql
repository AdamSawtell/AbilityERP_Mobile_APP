SELECT tn.parent_id, pm.name AS parent_name, m.name, m.ad_menu_id, m.ad_menu_uu, m.ad_window_id
FROM ad_treenodemm tn
JOIN ad_menu m ON m.ad_menu_id=tn.node_id
LEFT JOIN ad_menu pm ON pm.ad_menu_id=tn.parent_id
WHERE m.name ILIKE '%unavail%' OR m.name ILIKE '%leave%'
ORDER BY m.name;
