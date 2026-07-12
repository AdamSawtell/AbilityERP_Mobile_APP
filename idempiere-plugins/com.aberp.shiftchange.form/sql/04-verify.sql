SET search_path TO adempiere;

\echo === columns ===
SELECT c.columnname, c.isupdateable, c.columnsql IS NULL AS no_columnsql, c.ad_reference_id
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'AbERP_ShiftChange'
  AND c.columnname IN ('R_Status_ID','AbERP_RequestSubmitted','AbERP_CreateShiftChangeRequest');

\echo === fields ===
SELECT f.name, c.columnname, f.isreadonly, f.displaylogic, f.seqno
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab tab ON tab.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
WHERE w.name = 'HCO Forms and Approvals' AND tab.tablevel = 0
  AND c.columnname IN ('R_Status_ID','AbERP_RequestSubmitted','AbERP_CreateShiftChangeRequest')
ORDER BY f.seqno;

\echo === triggers ===
SELECT tgname, tgenabled FROM pg_trigger
WHERE tgname LIKE 'aberp_shiftchange%'
ORDER BY 1;

\echo === sample backfill ===
SELECT sc.documentno, sc.aberp_requestsubmitted, ss.name AS status_name
FROM aberp_shiftchange sc
LEFT JOIN r_status ss ON ss.r_status_id = sc.r_status_id
WHERE sc.documentno = '1003753';

\echo === mismatch after backfill ===
SELECT COUNT(*) AS still_mismatch
FROM aberp_shiftchange sc
JOIN LATERAL (
  SELECT r.r_status_id FROM r_request r
  WHERE r.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename='AbERP_ShiftChange')
    AND r.record_id = sc.aberp_shiftchange_id AND r.isactive='Y'
  ORDER BY r.r_request_id DESC LIMIT 1
) r ON TRUE
WHERE sc.r_status_id IS DISTINCT FROM r.r_status_id;
