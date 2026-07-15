-- =============================================================================
-- SAW023 — verify skeleton
-- =============================================================================
SET search_path TO adempiere;

SELECT 'tables' AS check, COUNT(*) AS n
FROM information_schema.tables
WHERE table_schema='adempiere'
  AND table_name IN ('aberp_compliancerule','aberp_complianceresult','aberp_compliancesnapshot')
UNION ALL
SELECT 'view', COUNT(*)
FROM information_schema.views
WHERE table_schema='adempiere' AND table_name='aberp_compliancedashboard'
UNION ALL
SELECT 'ad_tables', COUNT(*)
FROM ad_table
WHERE tablename IN ('AbERP_ComplianceRule','AbERP_ComplianceResult','AbERP_ComplianceSnapshot','AbERP_ComplianceDashboard')
UNION ALL
SELECT 'windows', COUNT(*)
FROM ad_window
WHERE name IN ('Compliance Summary','Compliance Rules') AND entitytype='Ab_ERP'
UNION ALL
SELECT 'summary_tabs', COUNT(*)
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id=t.ad_window_id
WHERE w.ad_window_uu='23a02305-c0d4-4f01-8e15-000000000001'
UNION ALL
SELECT 'dashboard_row', COUNT(*)
FROM aberp_compliancedashboard
UNION ALL
SELECT 'seed_snaps', COUNT(*)
FROM aberp_compliancesnapshot
WHERE aberp_compliancesnapshot_uu LIKE '23a02380-%';
