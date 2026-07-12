-- SAW013 discovery round 3: request link, status, fields, duplicates
\echo === R_Request sample linked to ShiftChange ===
SELECT t.ad_table_id, t.ad_table_uu
FROM ad_table t WHERE t.tablename = 'AbERP_ShiftChange';

\echo === Linked requests count / status ===
SELECT r.r_request_id, r.documentno, r.record_id, r.ad_table_id,
       r.r_status_id, s.name AS status_name, s.value AS status_value,
       r.r_requesttype_id, rt.name AS request_type,
       r.created, r.processed, r.isinactive
FROM r_request r
LEFT JOIN r_status s ON s.r_status_id = r.r_status_id
LEFT JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
WHERE r.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_ShiftChange')
ORDER BY r.created DESC
LIMIT 20;

\echo === Duplicate requests per ShiftChange ===
SELECT r.record_id, COUNT(*) AS req_count,
       array_agg(r.r_request_id ORDER BY r.created) AS request_ids,
       array_agg(r.documentno ORDER BY r.created) AS docnos
FROM r_request r
WHERE r.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_ShiftChange')
  AND r.isactive = 'Y'
GROUP BY r.record_id
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC
LIMIT 20;

\echo === ShiftChange status vs request status mismatch ===
SELECT sc.aberp_shiftchange_id, sc.documentno,
       sc.r_status_id AS sc_status_id, ss.name AS sc_status,
       r.r_request_id, r.r_status_id AS req_status_id, rs.name AS req_status
FROM aberp_shiftchange sc
LEFT JOIN LATERAL (
  SELECT * FROM r_request r
  WHERE r.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_ShiftChange')
    AND r.record_id = sc.aberp_shiftchange_id
    AND r.isactive = 'Y'
  ORDER BY r.created DESC
  LIMIT 1
) r ON TRUE
LEFT JOIN r_status ss ON ss.r_status_id = sc.r_status_id
LEFT JOIN r_status rs ON rs.r_status_id = r.r_status_id
WHERE r.r_request_id IS NOT NULL
ORDER BY sc.aberp_shiftchange_id DESC
LIMIT 25;

\echo === Fields on main tab (status / button / request) ===
SELECT f.ad_field_id, f.name, c.columnname, f.seqno, f.isdisplayed, f.isreadonly,
       f.displaylogic, f.ad_field_uu, f.entitytype
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE f.ad_tab_id = 1000284
  AND (
    c.columnname IN ('R_Status_ID','AbERP_CreateShiftChangeRequest','R_RequestType_ID','R_Resolution_ID','DocumentNo','Summary')
    OR c.columnname ILIKE '%Request%'
    OR c.columnname ILIKE '%Status%'
    OR c.columnname ILIKE '%Submit%'
  )
ORDER BY f.seqno;

\echo === All displayed fields on main tab ===
SELECT f.seqno, f.name, c.columnname, f.isreadonly, f.displaylogic, f.isdisplayed
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE f.ad_tab_id = 1000284 AND f.isdisplayed = 'Y'
ORDER BY f.seqno;

\echo === R_Status reference / validation ===
SELECT c.ad_column_id, c.columnname, c.ad_reference_id, c.ad_val_rule_id, v.name AS valrule, v.code
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
LEFT JOIN ad_val_rule v ON v.ad_val_rule_id = c.ad_val_rule_id
WHERE t.tablename IN ('AbERP_ShiftChange','R_Request')
  AND c.columnname = 'R_Status_ID';

\echo === Process params CreateRequestFromTemplate ===
SELECT pp.ad_process_para_id, pp.columnname, pp.name, pp.seqno, pp.ismandatory, pp.ad_reference_id
FROM ad_process_para pp
WHERE pp.ad_process_id = 1000051
ORDER BY pp.seqno;

\echo === Tab UUs ===
SELECT ad_tab_id, name, ad_tab_uu FROM ad_tab WHERE ad_tab_id IN (1000284,1000285,1000357);

\echo === Window UU ===
SELECT ad_window_id, name, ad_window_uu FROM ad_window WHERE ad_window_id = 1000137;
