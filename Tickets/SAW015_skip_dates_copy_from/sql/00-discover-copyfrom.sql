SET search_path TO adempiere;

SELECT s.aberp_skip_dates_id, s.name, s.isactive,
       (SELECT COUNT(*) FROM aberp_dates d WHERE d.aberp_skip_dates_id = s.aberp_skip_dates_id) AS line_count
FROM aberp_skip_dates s
ORDER BY line_count DESC, s.aberp_skip_dates_id
LIMIT 20;

SELECT pp.seqno, pp.columnname, pp.name, pp.ad_reference_id, pp.ad_reference_value_id,
       pp.ismandatory, pp.fieldlength, pp.ad_val_rule_id
FROM ad_process_para pp
WHERE pp.ad_process_id = (SELECT ad_process_id FROM ad_process WHERE value = 'C_Order CopyFrom')
ORDER BY pp.seqno;

SELECT p.value, p.name, p.classname, p.showhelp, p.ad_process_uu, p.help
FROM ad_process p WHERE p.value IN ('C_Order CopyFrom', 'Copy Service Pattern Lines');

SELECT pp.seqno, pp.columnname, pp.name, pp.ad_reference_id, pp.ad_reference_value_id,
       pp.ismandatory, pp.fieldlength, pp.ad_element_id
FROM ad_process_para pp
JOIN ad_process p ON p.ad_process_id = pp.ad_process_id
WHERE p.value = 'Copy Service Pattern Lines'
ORDER BY pp.seqno;

-- How CopyFrom is wired on C_Order
SELECT c.columnname, c.ad_reference_id, c.ad_process_id, c.istoolbarbutton,
       c.isalwaysupdateable, c.isupdateable, e.name AS element_name
FROM ad_column c
LEFT JOIN ad_element e ON e.ad_element_id = c.ad_element_id
WHERE c.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'C_Order')
  AND c.columnname = 'CopyFrom';

-- Sequence for aberp_dates
SELECT * FROM ad_sequence WHERE name IN ('AbERP_Dates', 'AbERP_Skip_Dates');

-- Window access for Skip Dates
SELECT r.name AS role_name, wa.isreadwrite
FROM ad_window_access wa
JOIN ad_role r ON r.ad_role_id = wa.ad_role_id
JOIN ad_window w ON w.ad_window_id = wa.ad_window_id
WHERE w.name = 'Skip Dates'
ORDER BY r.name;
