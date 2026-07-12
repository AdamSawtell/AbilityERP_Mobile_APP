SET search_path TO adempiere;
\pset pager off

\echo '=== TIMESHEET COUNTS ==='
SELECT COUNT(*) AS all_rows,
       COUNT(*) FILTER (WHERE isactive='Y') AS active,
       COUNT(aberp_break_start) AS with_break_start,
       COUNT(*) FILTER (WHERE aberp_break_start IS NULL) AS without_break,
       COUNT(DISTINCT aberp_user_contact_id) AS distinct_users
FROM aberp_timesheetandexpenses;

\echo '=== APPROVED STATUS COLUMN ==='
SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='aberp_timesheetandexpenses'
  AND (column_name ILIKE '%approv%' OR column_name ILIKE '%status%' OR column_name='r_status_id');

\echo '=== STATUS VALUES USED ==='
SELECT s.r_status_id, s.name, COUNT(*) 
FROM aberp_timesheetandexpenses t
LEFT JOIN r_status s ON s.r_status_id = t.r_status_id
GROUP BY s.r_status_id, s.name
ORDER BY COUNT(*) DESC
LIMIT 20;

\echo '=== SAMPLE MIXED ROWS ==='
SELECT t.aberp_timesheetandexpenses_id, t.startdate, t.enddate,
       t.aberp_break_start, t.aberp_break_end, t.aberp_break_included,
       t.aberp_user_contact_id, u.name AS user_name, bp.name AS bp_name, bp.isemployee,
       t.r_status_id, st.name AS status_name, t.isactive
FROM aberp_timesheetandexpenses t
LEFT JOIN ad_user u ON u.ad_user_id = t.aberp_user_contact_id
LEFT JOIN c_bpartner bp ON bp.c_bpartner_id = u.c_bpartner_id
LEFT JOIN r_status st ON st.r_status_id = t.r_status_id
ORDER BY t.startdate DESC NULLS LAST
LIMIT 15;

\echo '=== AGENCY VS EMPLOYEE ==='
SELECT COALESCE(bp.isemployee,'?') AS isemployee, COUNT(*)
FROM aberp_timesheetandexpenses t
LEFT JOIN ad_user u ON u.ad_user_id = t.aberp_user_contact_id
LEFT JOIN c_bpartner bp ON bp.c_bpartner_id = u.c_bpartner_id
GROUP BY COALESCE(bp.isemployee,'?');

\echo '=== INFOPROCESS DETAIL ==='
SELECT * FROM ad_infoprocess WHERE ad_infowindow_id=1000033;

\echo '=== ISKEY ON INFO WINDOW ==='
SELECT columnname, name, iskey, isidentifier, isdisplayed, selectclause
FROM ad_infocolumn WHERE ad_infowindow_id=1000033 AND (iskey='Y' OR columnname ILIKE '%Timesheet%');

\echo '=== EXISTING BREAK INFOCOLS ANYWHERE ==='
SELECT iw.name, ic.columnname, ic.name, ic.selectclause, ic.ad_reference_id, ic.seqno
FROM ad_infocolumn ic
JOIN ad_infowindow iw ON iw.ad_infowindow_id=ic.ad_infowindow_id
WHERE ic.columnname ILIKE '%Break%' OR ic.name ILIKE '%Break%';
