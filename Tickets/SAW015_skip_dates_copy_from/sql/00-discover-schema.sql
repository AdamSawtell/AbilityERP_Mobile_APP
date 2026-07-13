SET search_path TO adempiere;

-- Skip Dates header columns
SELECT c.columnname, c.ad_reference_id, r.name AS ref, c.fieldlength, c.iskey, c.ismandatory,
       c.isupdateable, c.ad_reference_value_id, c.columnsql IS NOT NULL AS is_virtual,
       c.ad_column_uu
FROM ad_column c
LEFT JOIN ad_reference r ON r.ad_reference_id = c.ad_reference_id
WHERE c.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_Skip_Dates')
ORDER BY c.columnname;

-- Dates line columns
SELECT c.columnname, c.ad_reference_id, r.name AS ref, c.fieldlength, c.iskey, c.ismandatory,
       c.isupdateable, c.ad_reference_value_id, c.columnsql IS NOT NULL AS is_virtual,
       c.ad_column_uu
FROM ad_column c
LEFT JOIN ad_reference r ON r.ad_reference_id = c.ad_reference_id
WHERE c.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_Dates')
ORDER BY c.columnname;

-- Physical columns on aberp_dates
SELECT column_name, data_type, character_maximum_length, is_nullable
FROM information_schema.columns
WHERE table_schema = 'adempiere' AND table_name = 'aberp_dates'
ORDER BY ordinal_position;

-- Physical columns on aberp_skip_dates
SELECT column_name, data_type, character_maximum_length, is_nullable
FROM information_schema.columns
WHERE table_schema = 'adempiere' AND table_name = 'aberp_skip_dates'
ORDER BY ordinal_position;

-- Sample data counts
SELECT 'skip_dates' AS t, COUNT(*) FROM aberp_skip_dates
UNION ALL
SELECT 'dates', COUNT(*) FROM aberp_dates;

-- Sample skip dates with line counts
SELECT s.aberp_skip_dates_id, s.documentno, s.name, s.isactive,
       (SELECT COUNT(*) FROM aberp_dates d WHERE d.aberp_skip_dates_id = s.aberp_skip_dates_id) AS line_count
FROM aberp_skip_dates s
ORDER BY s.aberp_skip_dates_id
LIMIT 20;

-- CopyFromOrder process parameters
SELECT pp.seqno, pp.columnname, pp.name, pp.ad_reference_id, pp.ad_reference_value_id,
       pp.ismandatory, pp.fieldlength, pp.ad_val_rule_id
FROM ad_process_para pp
WHERE pp.ad_process_id = (SELECT ad_process_id FROM ad_process WHERE value = 'C_Order CopyFrom')
ORDER BY pp.seqno;

-- Copy Service Pattern Lines params + process detail
SELECT p.value, p.name, p.classname, p.showhelp, p.ad_process_uu
FROM ad_process p WHERE p.value = 'Copy Service Pattern Lines';

SELECT pp.seqno, pp.columnname, pp.name, pp.ad_reference_id, pp.ad_reference_value_id,
       pp.ismandatory, pp.fieldlength
FROM ad_process_para pp
JOIN ad_process p ON p.ad_process_id = pp.ad_process_id
WHERE p.value = 'Copy Service Pattern Lines'
ORDER BY pp.seqno;

-- Does Skip Dates already have CopyFrom column?
SELECT c.columnname, c.ad_reference_id, c.ad_process_id, p.name
FROM ad_column c
LEFT JOIN ad_process p ON p.ad_process_id = c.ad_process_id
WHERE c.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_Skip_Dates')
  AND (c.columnname ILIKE '%copy%' OR c.ad_reference_id = 28);
