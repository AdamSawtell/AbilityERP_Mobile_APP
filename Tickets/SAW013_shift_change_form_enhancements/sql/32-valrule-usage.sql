SET search_path TO adempiere;

\echo === Who uses val rule R_Request Template ===
SELECT 'process_para' AS src, p.value AS owner, pp.columnname, pp.name
FROM ad_process_para pp
JOIN ad_process p ON p.ad_process_id = pp.ad_process_id
WHERE pp.ad_val_rule_id = 1000069
UNION ALL
SELECT 'column', t.tablename, c.columnname, c.name
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE c.ad_val_rule_id = 1000069
UNION ALL
SELECT 'field', w.name, c.columnname, f.name
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab tb ON tb.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = tb.ad_window_id
WHERE f.ad_val_rule_id = 1000069;

\echo === Find template request jar ===
-- just a placeholder; jar search is shell

\echo === Test context default SQL ===
-- Simulate for Additional Shift type on 1003729
SELECT r.r_request_id, r.documentno, rt.name
FROM r_request r
JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
WHERE r.isactive = 'Y' AND r.istemplate = 'Y'
  AND r.r_requesttype_id = (SELECT r_requesttype_id FROM aberp_shiftchange WHERE documentno = '1003729')
ORDER BY r.created DESC
FETCH FIRST 1 ROWS ONLY;
