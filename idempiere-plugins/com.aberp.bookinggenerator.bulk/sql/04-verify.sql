-- SAW017 verify
SET search_path TO adempiere;

SELECT p.value, p.name, p.classname, p.ad_process_uu, p.isactive
FROM ad_process p
WHERE p.ad_process_uu = '17a01701-b017-4017-8017-000000000001';

SELECT pp.seqno, pp.columnname, pp.name, pp.ismandatory, pp.defaultvalue
FROM ad_process_para pp
JOIN ad_process p ON p.ad_process_id = pp.ad_process_id
WHERE p.ad_process_uu = '17a01701-b017-4017-8017-000000000001'
ORDER BY pp.seqno;

SELECT c.columnname, c.istoolbarbutton, c.ad_process_id IS NOT NULL AS has_process
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'AbERP_BookingGenerator' AND c.columnname = 'AbERP_BulkGenerateBookings';

SELECT r.name AS role, pa.isreadwrite
FROM ad_process_access pa
JOIN ad_process p ON p.ad_process_id = pa.ad_process_id
JOIN ad_role r ON r.ad_role_id = pa.ad_role_id
WHERE p.ad_process_uu = '17a01701-b017-4017-8017-000000000001'
ORDER BY r.name;
