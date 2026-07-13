-- SAW016: edit restrictions, zoom, entity type, roles, location list for employees
\echo === Field readonly / displaylogic on leave ===
SELECT f.name, c.columnname, f.isreadonly, f.displaylogic, f.readonlylogic, c.readonlylogic AS col_ro
FROM ad_field f
JOIN ad_column c ON c.ad_column_id=f.ad_column_id
WHERE f.ad_tab_id=1000265
  AND (f.isreadonly='Y' OR COALESCE(f.displaylogic,'')<>'' OR COALESCE(f.readonlylogic,'')<>'' OR COALESCE(c.readonlylogic,'')<>'');

\echo === Callouts on leave ===
SELECT columnname, callout FROM ad_column c
JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE t.tablename='AbERP_Unavailability_Leave' AND COALESCE(callout,'')<>'';

\echo === Submit leave process details ===
SELECT * FROM ad_process WHERE value='SUBMIT_LEAVE';
SELECT columnname, name, seqno FROM ad_process_para WHERE ad_process_id=1000052 ORDER BY seqno;

\echo === Entity types ===
SELECT entitytype, name FROM ad_entitytype WHERE entitytype ILIKE '%aberp%' OR entitytype ILIKE '%hco%' OR entitytype='U' LIMIT 20;

\echo === Distinct employee partner locations count ===
SELECT COUNT(DISTINCT u.c_bpartner_location_id) AS loc_count
FROM ad_user u
JOIN c_bpartner bp ON bp.c_bpartner_id=u.c_bpartner_id
WHERE u.isactive='Y' AND u.c_bpartner_location_id IS NOT NULL
  AND (bp.isemployee='Y' OR u.aberp_isagencystaff='Y');

\echo === Roles Admin / AbilityERP Admin ===
SELECT ad_role_id, name, ad_client_id, ad_role_uu FROM ad_role
WHERE name IN ('Admin','AbilityERP Admin','System Administrator','Rostering Officer')
ORDER BY ad_client_id, name;

\echo === Menu tree parent Rostering ===
SELECT tn.node_id, tn.parent_id, m.name, m.ad_menu_uu
FROM ad_treenode tn
JOIN ad_menu m ON m.ad_menu_id=tn.node_id
WHERE tn.ad_tree_id=(SELECT ad_tree_id FROM ad_tree WHERE treetype='MM' AND ad_client_id=0 LIMIT 1)
  AND (m.name='Rostering' OR tn.parent_id=1000101)
ORDER BY tn.seqno
LIMIT 30;

\echo === Sample overlap query Jan 2027 ===
SELECT COUNT(*) FROM aberp_unavailability_leave ul
WHERE ul.isactive='Y'
  AND ul.startdate::date <= DATE '2027-01-31'
  AND ul.enddate::date >= DATE '2027-01-01';

SELECT ul.aberp_approverstatus, COUNT(*)
FROM aberp_unavailability_leave ul
WHERE ul.isactive='Y'
  AND ul.startdate::date <= CURRENT_DATE + 120
  AND ul.enddate::date >= CURRENT_DATE - 30
GROUP BY 1;
