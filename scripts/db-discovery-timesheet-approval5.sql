SET search_path TO adempiere;
\pset pager off

\echo '=== PROCESS PARA ==='
SELECT columnname, ad_reference_id, ad_reference_value_id, ad_val_rule_id, defaultvalue
FROM ad_process_para WHERE ad_process_id=1000383;

\echo '=== STATUS APPROVE-LIKE ==='
SELECT r_status_id, name, value, isactive FROM r_status
WHERE name ILIKE '%approv%' OR value ILIKE '%approv%' OR name ILIKE '%timesheet%'
LIMIT 40;

\echo '=== ADMIN USERS ==='
SELECT ad_user_id, name, value, isactive FROM ad_user
WHERE name ILIKE '%super%' OR ad_user_id IN (100, 1000000) OR name ILIKE '%sawtell%' OR value ILIKE '%GardenAdmin%'
LIMIT 20;

\echo '=== EMPLOYEE USERS ==='
SELECT u.ad_user_id, u.name, bp.isemployee
FROM ad_user u
JOIN c_bpartner bp ON bp.c_bpartner_id = u.c_bpartner_id
WHERE u.isactive='Y' AND u.ad_client_id=1000002 AND bp.isemployee='Y'
LIMIT 10;

\echo '=== AGENCY-LIKE USERS (non-employee with contact) ==='
SELECT u.ad_user_id, u.name, bp.name AS bp_name, bp.isemployee
FROM ad_user u
JOIN c_bpartner bp ON bp.c_bpartner_id = u.c_bpartner_id
WHERE u.isactive='Y' AND u.ad_client_id=1000002 AND bp.isemployee='N'
  AND u.name NOT ILIKE '%office%' AND u.name NOT ILIKE '%property%'
LIMIT 10;

\echo '=== SHIFT TYPES ==='
SELECT aberp_shift_type_id, name FROM aberp_shift_type WHERE isactive='Y' LIMIT 5;

\echo '=== INFOWINDOW ISVALID / OTHER ==='
SELECT isvalid, isshowindashboard, isloadpagemaxqueryrecords FROM ad_infowindow WHERE ad_infowindow_id=1000033;
