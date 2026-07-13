SET search_path TO adempiere;

\echo === Val rule detail ===
SELECT ad_val_rule_id, ad_val_rule_uu, name, entitytype, code
FROM ad_val_rule WHERE ad_val_rule_id = 1000069 OR name ILIKE '%Request Template%';

\echo === Process para UU + details ===
SELECT pp.ad_process_para_id, pp.ad_process_para_uu, pp.columnname, pp.defaultvalue,
       pp.ad_val_rule_id, pp.ad_reference_id, pp.ad_reference_value_id
FROM ad_process_para pp
JOIN ad_process p ON p.ad_process_id = pp.ad_process_id
WHERE p.value = 'CreateRequestFromTemplate';

\echo === Table reference 341 ===
SELECT ad_reference_id, name, validationtype FROM ad_reference WHERE ad_reference_id = 341;
SELECT ad_ref_table_id, ad_table_id, ad_key, ad_display, whereclause, orderbyclause, isvaluedisplayed
FROM ad_ref_table WHERE ad_reference_id = 341;

\echo === Template requests by type (sample) ===
SELECT rt.name AS request_type, COUNT(*) AS template_count,
       MIN(r.documentno) AS sample_doc, MIN(r.r_request_id) AS sample_id
FROM r_request r
JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
WHERE r.istemplate = 'Y' AND r.isactive = 'Y'
GROUP BY rt.name
ORDER BY rt.name;

\echo === Templates for Additional Shift (1003729 type) ===
SELECT r.r_request_id, r.documentno, r.summary, rt.name, r.created
FROM r_request r
JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
WHERE r.istemplate = 'Y' AND r.isactive = 'Y'
  AND r.r_requesttype_id = (
    SELECT r_requesttype_id FROM aberp_shiftchange WHERE documentno = '1003729'
  )
ORDER BY r.created DESC
LIMIT 10;

\echo === Context: does ShiftChange have R_RequestType_ID in ctx when process runs? ===
SELECT c.columnname, c.ad_reference_id
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'AbERP_ShiftChange' AND c.columnname = 'R_RequestType_ID';
