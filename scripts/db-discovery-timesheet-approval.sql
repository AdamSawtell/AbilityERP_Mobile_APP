SET search_path TO adempiere;
\pset pager off

\echo '=== INFO WINDOW ==='
SELECT ad_infowindow_id, ad_infowindow_uu, name, ad_table_id, isvalid, isactive,
       orderbyclause, maxqueryrecords, processing, ad_infowindow_uu
FROM ad_infowindow
WHERE ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4'
   OR ad_infowindow_id = 1000033
   OR name ILIKE '%Timesheet Approval%';

\echo '=== TABLE ==='
SELECT t.ad_table_id, t.tablename, t.name, t.isview
FROM ad_infowindow iw
JOIN ad_table t ON t.ad_table_id = iw.ad_table_id
WHERE iw.ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4';

\echo '=== FROM CLAUSE ==='
SELECT fromclause FROM ad_infowindow
WHERE ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4';

\echo '=== OTHER CLAUSES ==='
SELECT whereclause, otherfromclause, orderbyclause
FROM ad_infowindow
WHERE ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4';

\echo '=== INFO COLUMNS ==='
SELECT seqnoselection, seqno, ad_infocolumn_id, ad_infocolumn_uu, columnname, name,
       selectclause, isquerycriteria, isdisplayed, isdisplayedselection,
       ismandatory, iskey, isidentifier, ishideinfocolumn, isactive,
       ad_reference_id, ad_reference_value_id, queryoperator, queryfunction,
       ad_element_id, entitytype
FROM ad_infocolumn
WHERE ad_infowindow_id = (
  SELECT ad_infowindow_id FROM ad_infowindow
  WHERE ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4'
)
ORDER BY COALESCE(seqnoselection,0), seqno;

\echo '=== PROCESSES LINKED TO INFO WINDOW ==='
SELECT p.ad_process_id, p.ad_process_uu, p.name, p.classname, p.procedurename, p.value,
       ip.ad_infoprocess_id, ip.seqno, ip.layouttype, ip.isactive
FROM ad_infoprocess ip
JOIN ad_process p ON p.ad_process_id = ip.ad_process_id
WHERE ip.ad_infowindow_id = (
  SELECT ad_infowindow_id FROM ad_infowindow
  WHERE ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4'
)
ORDER BY ip.seqno;

\echo '=== APPROVE PROCESS BY NAME ==='
SELECT ad_process_id, ad_process_uu, name, value, classname, procedurename, isactive
FROM ad_process
WHERE name ILIKE '%Timesheet%Approved%'
   OR name ILIKE '%Set Timesheet%'
   OR value ILIKE '%Timesheet%Approved%'
   OR classname ILIKE '%Timesheet%';

\echo '=== BREAK-RELATED COLUMNS IN DB ==='
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'adempiere'
  AND (
    column_name ILIKE '%break%'
    OR column_name ILIKE '%Break%'
  )
ORDER BY table_name, column_name;

\echo '=== BREAK-RELATED AD COLUMNS ==='
SELECT t.tablename, c.columnname, c.name, c.ad_reference_id, c.ad_column_uu, c.isactive
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE c.columnname ILIKE '%Break%'
   OR c.name ILIKE '%Break%'
ORDER BY t.tablename, c.columnname;
