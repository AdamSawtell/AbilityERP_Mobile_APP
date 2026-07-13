-- SAW016 discovery continued
\echo === LEAVE PROCESSES / BUTTONS ===
SELECT p.ad_process_id, p.value, p.name, p.classname, p.ad_process_uu
FROM ad_process p
WHERE p.name ILIKE '%leave%' OR p.value ILIKE '%leave%'
   OR p.name ILIKE '%unavail%' OR p.value ILIKE '%unavail%'
   OR p.classname ILIKE '%leave%' OR p.classname ILIKE '%unavail%'
ORDER BY p.value;

SELECT c.columnname, c.name, c.ad_reference_id, c.ad_process_id, p.value AS proc_value, p.name AS proc_name
FROM ad_column c
JOIN ad_table t ON t.ad_table_id=c.ad_table_id
LEFT JOIN ad_process p ON p.ad_process_id=c.ad_process_id
WHERE upper(t.tablename)=upper('AbERP_Unavailability_Leave')
  AND (c.ad_reference_id IN (28) OR c.ad_process_id IS NOT NULL OR c.columnname ILIKE '%submit%' OR c.columnname ILIKE '%approv%')
ORDER BY c.columnname;

\echo === STATUS REFS ===
SELECT c.columnname, c.ad_reference_id, c.ad_reference_value_id, r.name AS ref_name, r.validationtype
FROM ad_column c
JOIN ad_table t ON t.ad_table_id=c.ad_table_id
LEFT JOIN ad_reference r ON r.ad_reference_id=c.ad_reference_value_id
WHERE upper(t.tablename)=upper('AbERP_Unavailability_Leave')
  AND (c.columnname ILIKE '%status%' OR c.columnname ILIKE '%type%' OR c.columnname ILIKE '%approv%' OR c.columnname ILIKE '%submit%');

\echo === LIST VALUES for status refs ===
SELECT rl.ad_reference_id, r.name, rl.value, rl.name AS list_name, rl.isactive
FROM ad_ref_list rl
JOIN ad_reference r ON r.ad_reference_id=rl.ad_reference_id
WHERE rl.ad_reference_id IN (
  SELECT c.ad_reference_value_id FROM ad_column c
  JOIN ad_table t ON t.ad_table_id=c.ad_table_id
  WHERE upper(t.tablename)=upper('AbERP_Unavailability_Leave')
    AND c.ad_reference_value_id IS NOT NULL
)
ORDER BY rl.ad_reference_id, rl.value;

\echo === SAMPLE LEAVE ROWS ===
SELECT * FROM aberp_unavailability_leave ORDER BY updated DESC LIMIT 3;
