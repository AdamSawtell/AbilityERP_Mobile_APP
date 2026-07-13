#!/bin/bash
PGPASSWORD=flamingo psql -h localhost -U adempiere -d idempiere <<'SQL'
SET search_path TO adempiere;
SELECT p.ad_process_id, p.value, p.name, p.classname, pp.seqno, pp.columnname, pp.name, pp.ad_reference_id
FROM ad_process p
LEFT JOIN ad_process_para pp ON pp.ad_process_id=p.ad_process_id
WHERE p.ad_process_id IN (200099, 50008)
ORDER BY p.ad_process_id, pp.seqno;
-- Pack In window file column
SELECT c.columnname, c.name, c.ad_reference_id
FROM ad_column c
JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE t.tablename='AD_Package_Imp_Proc' OR t.tablename ILIKE '%Package_Imp%'
ORDER BY t.tablename, c.columnname;
SELECT tablename FROM ad_table WHERE tablename ILIKE '%pack%imp%';
SQL

# Try OSGi console PackInFolder if possible
echo "=== try telnet console ==="
# Check if we can run process via runProcess
which expect || true