SET search_path TO adempiere;
\pset pager off

\echo '=== TIMESHEET STATUS LIST ==='
SELECT DISTINCT s.r_status_id, s.name, s.value, s.isactive
FROM r_status s
JOIN r_requesttype rt ON rt.r_requesttype_id = s.r_requesttype_id
WHERE rt.name ILIKE '%timesheet%' OR s.name ILIKE '%approv%' OR s.value ILIKE '%approv%'
ORDER BY s.name
LIMIT 40;

\echo '=== R_STATUS FOR PROCESS REF ==='
SELECT ad_reference_id, name FROM ad_reference WHERE name ILIKE '%status%' LIMIT 20;

\echo '=== PROCESS DETAIL ==='
SELECT ad_process_id, name, classname, accesslevel, isactive, isreport, isbetafunctionality
FROM ad_process WHERE ad_process_id=1000383;

\echo '=== USERS FOR TEST ==='
SELECT u.ad_user_id, u.name, u.email, bp.c_bpartner_id, bp.name AS bp_name, bp.isemployee
FROM ad_user u
LEFT JOIN c_bpartner bp ON bp.c_bpartner_id = u.c_bpartner_id
WHERE u.isactive='Y' AND u.ad_client_id=1000002
  AND (bp.isemployee='N' OR bp.isemployee='Y')
ORDER BY bp.isemployee NULLS LAST, u.name
LIMIT 20;

\echo '=== TIMESHEET TABLE REQUIRED COLS ==='
SELECT c.column_name, c.is_nullable, c.column_default, c.data_type
FROM information_schema.columns c
WHERE c.table_schema='adempiere' AND c.table_name='aberp_timesheetandexpenses'
  AND c.is_nullable='NO'
ORDER BY c.column_name;

\echo '=== EXISTING ROW FULL ==='
SELECT * FROM aberp_timesheetandexpenses LIMIT 1;

\echo '=== MENU PATH ==='
SELECT m.ad_menu_id, m.name, m.action, m.ad_infowindow_id
FROM ad_menu m
WHERE m.ad_infowindow_id=1000033 OR m.name ILIKE '%Timesheet Approval%';
