-- SAW013 follow-on: CreateRequestFromTemplate process params
SET search_path TO adempiere;

\echo === Process ===
SELECT p.ad_process_id, p.name, p.value, p.classname, p.ad_process_uu, p.entitytype
FROM ad_process p
WHERE p.value ILIKE '%CreateRequestFromTemplate%'
   OR p.name ILIKE '%Create Request From Template%'
   OR p.classname ILIKE '%CreateRequestFromTemplate%';

\echo === Process parameters ===
SELECT pp.seqno, pp.name, c.columnname, pp.isactive, pp.ismandatory,
       pp.defaultvalue, pp.displaylogic, pp.readonlylogic,
       pp.ad_reference_id, pp.ad_val_rule_id, pp.ad_reference_value_id,
       pp.ad_process_para_uu, pp.fieldlength
FROM ad_process_para pp
JOIN ad_process p ON p.ad_process_id = pp.ad_process_id
LEFT JOIN ad_element e ON e.ad_element_id = pp.ad_element_id
LEFT JOIN ad_column c ON c.ad_column_id = (
  SELECT ad_column_id FROM ad_column WHERE ad_element_id = pp.ad_element_id LIMIT 1
)
WHERE p.value = 'CreateRequestFromTemplate'
   OR p.name ILIKE '%Create Request From Template%'
ORDER BY pp.seqno;

\echo === Para columns (raw) ===
SELECT column_name FROM information_schema.columns
WHERE table_name = 'ad_process_para'
  AND column_name ILIKE '%default%' OR (table_name='ad_process_para' AND column_name ILIKE '%logic%')
ORDER BY 1;

SELECT pp.seqno, pp.name, pp.columnname, pp.defaultvalue, pp.displaylogic, pp.readonlylogic,
       pp.ad_reference_id, r.name AS ref_name, pp.ad_val_rule_id,
       vr.name AS valrule_name, left(vr.code,200) AS valrule_code
FROM ad_process_para pp
JOIN ad_process p ON p.ad_process_id = pp.ad_process_id
LEFT JOIN ad_reference r ON r.ad_reference_id = pp.ad_reference_id
LEFT JOIN ad_val_rule vr ON vr.ad_val_rule_id = pp.ad_val_rule_id
WHERE p.value = 'CreateRequestFromTemplate'
ORDER BY pp.seqno;

\echo === Button column process link ===
SELECT c.columnname, c.ad_process_id, p.name, p.value, p.classname
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
LEFT JOIN ad_process p ON p.ad_process_id = c.ad_process_id
WHERE t.tablename = 'AbERP_ShiftChange'
  AND c.columnname = 'AbERP_CreateShiftChangeRequest';
