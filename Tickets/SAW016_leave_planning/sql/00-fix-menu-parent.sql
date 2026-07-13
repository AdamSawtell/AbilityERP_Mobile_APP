-- Move Leave Planning menu to root like other leave menus (parent -1)
UPDATE ad_treenodemm SET parent_id = -1, seqno = 9990, updated = NOW()
WHERE node_id = (SELECT ad_menu_id FROM ad_menu WHERE ad_menu_uu = '16a01605-c0d4-4f01-8e15-000000000001')
  AND ad_tree_id = 10;

-- Put report menu in tree too
INSERT INTO ad_treenodemm (ad_tree_id, node_id, parent_id, seqno, ad_client_id, ad_org_id, created, createdby, updated, updatedby, isactive)
SELECT 10, m.ad_menu_id, -1, 9991, 0, 0, NOW(), 100, NOW(), 100, 'Y'
FROM ad_menu m
WHERE m.ad_menu_uu = '16a01605-c0d4-4f01-8e15-000000000002'
  AND NOT EXISTS (SELECT 1 FROM ad_treenodemm tn WHERE tn.node_id = m.ad_menu_id AND tn.ad_tree_id = 10);

SELECT tn.parent_id, m.name FROM ad_treenodemm tn
JOIN ad_menu m ON m.ad_menu_id=tn.node_id
WHERE m.name LIKE 'Leave Planning%';
