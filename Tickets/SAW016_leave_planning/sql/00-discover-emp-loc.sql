-- SAW016: employee <-> service location
\echo === AD_USER C_BPartner_Location usage sample ===
SELECT COUNT(*) AS users_with_loc FROM ad_user WHERE c_bpartner_location_id IS NOT NULL AND isactive='Y';
SELECT COUNT(*) AS users_multi_check FROM (
  SELECT ad_user_id FROM ad_user WHERE isactive='Y' AND c_bpartner_location_id IS NOT NULL
) x;

\echo === Is there employee-location M:N table? ===
SELECT t.tablename, c.columnname
FROM ad_table t JOIN ad_column c ON c.ad_table_id=t.ad_table_id
WHERE (t.tablename ILIKE '%user%support%' OR t.tablename ILIKE '%staff%loc%'
   OR t.tablename ILIKE '%employee%loc%' OR t.tablename ILIKE '%user%master%'
   OR t.tablename ILIKE '%loc%user%' OR t.tablename ILIKE '%aberp_user%')
ORDER BY 1,2;

\echo === AbERP_Support_Location structure ===
SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='aberp_support_location'
ORDER BY ordinal_position;

\echo === Link user to support location via BP location? ===
SELECT COUNT(*) AS leave_users,
  COUNT(DISTINCT u.c_bpartner_location_id) AS distinct_user_locs,
  COUNT(DISTINCT sl.aberp_support_location_id) AS matched_support_locs
FROM aberp_unavailability_leave l
JOIN ad_user u ON u.ad_user_id=l.aberp_user_contact_id
LEFT JOIN aberp_support_location sl ON sl.c_bpartner_location_id=u.c_bpartner_location_id;

\echo === Staff Rostering Info criteria columns ===
SELECT ic.columnname, ic.name, ic.isquerycriteria, ic.selectclause, ic.ad_reference_id
FROM ad_infocolumn ic
JOIN ad_infowindow iw ON iw.ad_infowindow_id=ic.ad_infowindow_id
WHERE iw.name ILIKE '%roster%' OR iw.name ILIKE '%employee%agency%'
ORDER BY iw.name, ic.seqno
LIMIT 60;

\echo === Employee Roster Period Summary window ===
SELECT w.name, t.name AS tab, tbl.tablename, t.whereclause, t.ad_tab_uu
FROM ad_window w
JOIN ad_tab t ON t.ad_window_id=w.ad_window_id
JOIN ad_table tbl ON tbl.ad_table_id=t.ad_table_id
WHERE w.name='Employee Roster Period Summary'
ORDER BY t.seqno;

\echo === REPORTS on leave ===
SELECT p.value, p.name, p.isreport, p.jasperreport FROM ad_process p
WHERE p.isreport='Y' AND (p.name ILIKE '%leave%' OR p.name ILIKE '%unavail%' OR p.value ILIKE '%leave%');

\echo === Approver status distribution ===
SELECT aberp_approverstatus, aberp_submitterstatus, COUNT(*)
FROM aberp_unavailability_leave GROUP BY 1,2 ORDER BY 1,2;

\echo === Users with same BP but different locations? Multiple locations pattern ===
SELECT columnname, name, fieldlength, ad_reference_id FROM ad_column c
JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE t.tablename='AD_User' AND (c.columnname ILIKE '%loc%' OR c.name ILIKE '%service%' OR c.name ILIKE '%support%');

\echo === HCO_Support_Plan_Health_Plans ChosenMultiple pattern ===
SELECT c.columnname, c.fieldlength, c.ad_reference_id, c.ad_reference_value_id, r.name
FROM ad_column c
LEFT JOIN ad_reference r ON r.ad_reference_id=c.ad_reference_value_id
WHERE c.columnname='HCO_Support_Plan_Health_Plans';
