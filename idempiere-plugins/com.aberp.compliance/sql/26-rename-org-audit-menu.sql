-- SAW024-26 — interim: renamed window menu to Organisation Audit (superseded by 27)
-- Prefer sql/27-restore-org-audit-menu.sql: folder = Organisation Audit, leaf = Audit Hub.
SET search_path TO adempiere;

UPDATE ad_menu SET
  name = 'Organisation Audit',
  description = 'NDIS Organisation Audit hub — Employee KPIs and Open Findings',
  updated = NOW()
WHERE ad_menu_uu = '23a02331-c0d4-4f01-8e15-000000000001'
   OR (action = 'W' AND issummary = 'N' AND name = 'NDIS Audit Tool'
       AND ad_window_id = (SELECT ad_window_id FROM ad_window WHERE name = 'NDIS Audit Tool' LIMIT 1));

SELECT m.name, m.action, m.issummary, p.name AS parent
FROM ad_menu m
LEFT JOIN ad_treenodemm tn ON tn.node_id = m.ad_menu_id
LEFT JOIN ad_menu p ON p.ad_menu_id = tn.parent_id
WHERE m.ad_menu_uu IN (
  '23a02330-c0d4-4f01-8e15-000000000001',
  '23a02331-c0d4-4f01-8e15-000000000001'
) OR m.name IN ('Organisation Audit','NDIS Audit Tool');
