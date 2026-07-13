SELECT r.name, r.ad_tree_menu_id, t.name AS tree_name
FROM ad_role r
LEFT JOIN ad_tree t ON t.ad_tree_id=r.ad_tree_menu_id
WHERE r.name IN ('Admin','AbilityERP Admin','System Administrator');

SELECT tn.parent_id, pm.name AS parent, m.name, m.ad_menu_id
FROM ad_treenodemm tn
JOIN ad_menu m ON m.ad_menu_id=tn.node_id
LEFT JOIN ad_menu pm ON pm.ad_menu_id=tn.parent_id
WHERE m.name LIKE 'Leave Planning%';

-- Cache Reset process value
SELECT value, name FROM ad_process WHERE name ILIKE '%cache%reset%' OR value ILIKE '%Cache%Reset%';
