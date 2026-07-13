-- SAW016 verify
SET search_path TO adempiere;

\echo === Physical table ===
SELECT COUNT(*) AS planning_cols FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='aberp_leave_planning';

\echo === AD table / window / tabs ===
SELECT t.tablename, t.ad_table_uu FROM ad_table t WHERE t.tablename IN ('AbERP_Leave_Planning','aberp_leave_planning_rv');
SELECT w.name, w.ad_window_uu FROM ad_window w WHERE w.name = 'Leave Planning';
SELECT tab.name, tab.seqno, tab.whereclause IS NOT NULL AS has_where, tab.isinsertrecord
FROM ad_tab tab JOIN ad_window w ON w.ad_window_id=tab.ad_window_id
WHERE w.name='Leave Planning' ORDER BY tab.seqno;

\echo === Menu / access ===
SELECT m.name, m.action, m.ad_menu_uu FROM ad_menu m WHERE m.name IN ('Leave Planning','Leave Planning Report');
SELECT r.name, wa.isreadwrite
FROM ad_window_access wa
JOIN ad_window w ON w.ad_window_id=wa.ad_window_id
JOIN ad_role r ON r.ad_role_id=wa.ad_role_id
WHERE w.name='Leave Planning' AND r.name IN ('Admin','AbilityERP Admin')
ORDER BY r.name;

\echo === Report ===
SELECT p.value, p.name, p.isreport FROM ad_process p WHERE p.value='AbERP_LeavePlanning_Report';

\echo === Overlap smoke (All Locations, next 90 days) ===
SELECT COUNT(*) AS matching_leave
FROM aberp_unavailability_leave ul
WHERE ul.isactive='Y'
  AND ul.startdate::date <= (CURRENT_DATE + 90)
  AND ul.enddate::date >= CURRENT_DATE;
