-- SAW010 functional check: query shape + sample break values
-- Does not mutate AD. Safe to re-run.

SET search_path TO adempiere;
\pset pager off

\echo '=== SAMPLE QUERY SHAPE (mirrors Info Window SELECT list) ==='
SELECT
  t.AbERP_User_Contact_ID,
  t.StartDate AS StartDateFrom,
  t.EndDate AS EndDateFrom,
  t.AbERP_Shift_Type_ID,
  t.AbERP_Break_Start,
  t.AbERP_Break_End,
  t.AbERP_MasterLocation_ID,
  t.Description,
  t.R_Status_ID,
  bp.Supervisor_ID,
  t.AbERP_TimesheetAndExpenses_ID
FROM AbERP_TimesheetAndExpenses t
LEFT OUTER JOIN ad_user u ON (t.AbERP_User_Contact_ID = u.ad_user_id AND u.IsActive='Y')
LEFT OUTER JOIN C_BPartner bp ON (bp.C_BPartner_ID=u.C_BPartner_ID AND bp.IsActive='Y')
WHERE t.IsActive = 'Y'
ORDER BY t.StartDate
LIMIT 20;

\echo '=== BREAK COVERAGE ==='
SELECT
  COUNT(*) AS rows_active,
  COUNT(t.AbERP_Break_Start) AS with_break_start,
  COUNT(*) FILTER (WHERE t.AbERP_Break_Start IS NULL) AS without_break
FROM AbERP_TimesheetAndExpenses t
WHERE t.IsActive = 'Y';

\echo '=== HIDDEN COLUMNS STILL QUERYABLE (approval key) ==='
SELECT t.AbERP_TimesheetAndExpenses_ID, t.AbERP_User_Contact_ID, u.name
FROM AbERP_TimesheetAndExpenses t
LEFT JOIN ad_user u ON u.ad_user_id = t.AbERP_User_Contact_ID
WHERE t.IsActive = 'Y'
LIMIT 5;
