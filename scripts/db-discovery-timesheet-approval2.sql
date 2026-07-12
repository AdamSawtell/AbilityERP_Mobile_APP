SET search_path TO adempiere;
\pset pager off

\echo '=== WHERE CLAUSE ==='
SELECT whereclause FROM ad_infowindow
WHERE ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4';

\echo '=== AD_INFOCOLUMN COLS AVAILABLE ==='
SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='ad_infocolumn'
ORDER BY ordinal_position;

\echo '=== INFO COLUMNS ==='
SELECT seqnoselection, seqno, ad_infocolumn_id, ad_infocolumn_uu, columnname, name,
       selectclause, isquerycriteria, isdisplayed,
       ismandatory, iskey, isidentifier, ishideinfocolumn, isactive,
       ad_reference_id, ad_reference_value_id, queryoperator, queryfunction,
       ad_element_id, entitytype
FROM ad_infocolumn
WHERE ad_infowindow_id = (
  SELECT ad_infowindow_id FROM ad_infowindow
  WHERE ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4'
)
ORDER BY COALESCE(seqnoselection,0), seqno;

\echo '=== SHIFT TYPE COLUMN SEQ ==='
SELECT seqno, columnname, name, selectclause, isdisplayed, isquerycriteria
FROM ad_infocolumn
WHERE ad_infowindow_id = 1000033
  AND (name ILIKE '%Shift Type%' OR columnname ILIKE '%Shift%Type%' OR selectclause ILIKE '%Shift%Type%');

\echo '=== TARGET REMOVE COLUMNS ==='
SELECT seqno, ad_infocolumn_id, ad_infocolumn_uu, columnname, name, selectclause,
       isdisplayed, isquerycriteria, iskey, isidentifier, ishideinfocolumn, isactive
FROM ad_infocolumn
WHERE ad_infowindow_id = 1000033
  AND (
    name IN ('Shift Cost','Name','Employee','Activity')
    OR columnname IN ('ShiftCost','Name','Employee','Activity')
    OR name ILIKE '%Shift Cost%'
    OR name ILIKE '%Employee%'
    OR name ILIKE '%Activity%'
    OR name ILIKE '%Business Partner%'
    OR name ILIKE '%Agency%'
    OR columnname ILIKE '%BPartner%'
    OR columnname ILIKE '%User%'
  )
ORDER BY seqno;

\echo '=== PROCESS PARA ==='
SELECT pp.ad_process_para_id, pp.columnname, pp.name, pp.ad_reference_id, pp.seqno, pp.ismandatory
FROM ad_process_para pp
WHERE pp.ad_process_id = 1000383
ORDER BY pp.seqno;

\echo '=== SAMPLE BREAK DATA ==='
SELECT COUNT(*) AS total,
       COUNT(aberp_break_start) AS with_break_start,
       COUNT(aberp_break_end) AS with_break_end,
       COUNT(*) FILTER (WHERE aberp_break_start IS NOT NULL AND aberp_break_end IS NOT NULL) AS with_both
FROM aberp_timesheetandexpenses
WHERE isactive='Y';

\echo '=== SAMPLE ROWS WITH BREAKS ==='
SELECT aberp_timesheetandexpenses_id, startdate, enddate,
       aberp_break_start, aberp_break_end, aberp_break_included,
       aberp_user_contact_id, c_bpartner_id, aberp_timesheet_approved
FROM aberp_timesheetandexpenses
WHERE aberp_break_start IS NOT NULL
ORDER BY startdate DESC
LIMIT 5;

\echo '=== TIMESHEET TABLE KEY COLS ==='
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='aberp_timesheetandexpenses'
  AND (
    column_name ILIKE '%user%'
    OR column_name ILIKE '%bpartner%'
    OR column_name ILIKE '%agency%'
    OR column_name ILIKE '%employee%'
    OR column_name ILIKE '%approved%'
    OR column_name ILIKE '%shift%'
    OR column_name ILIKE '%break%'
    OR column_name ILIKE '%activity%'
    OR column_name ILIKE '%cost%'
    OR column_name = 'name'
  )
ORDER BY column_name;

\echo '=== AD ELEMENTS FOR BREAK ==='
SELECT ad_element_id, columnname, name, ad_element_uu
FROM ad_element
WHERE columnname IN ('AbERP_Break_Start','AbERP_Break_End','BreakStart','BreakEnd')
   OR name IN ('Break Start','Break End');
