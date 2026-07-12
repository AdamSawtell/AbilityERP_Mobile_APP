#!/bin/bash
set -euo pipefail
export PGPASSWORD=flamingo
cd /tmp/saw009
for f in 00-preflight.sql 01-add-support-day-columns.sql 02-add-fields.sql 03-backfill-from-pattern.sql 04-sync-trigger.sql 05-verify.sql; do
  echo "=== $f ==="
  psql -h localhost -U adempiere -d idempiere -v ON_ERROR_STOP=1 -f "$f"
done
echo "=== post UU check (must keep HCO column UUs) ==="
psql -h localhost -U adempiere -d idempiere -v ON_ERROR_STOP=1 <<'SQL'
SET search_path TO adempiere;
SELECT columnname, ad_column_uu, ad_reference_id, ad_reference_value_id
FROM ad_column c
JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE t.tablename='C_OrderLine'
  AND columnname IN ('AbERP_Support_Start_Day','AbERP_Support_End_Day');
SELECT name, ad_field_uu, isdisplayed, seqno
FROM ad_field WHERE ad_tab_id=1000137 AND name ILIKE 'Support % Day'
ORDER BY seqno;
SELECT aberp_support_start_day, COUNT(*) FROM c_orderline
WHERE aberp_support_start_day IS NOT NULL
GROUP BY 1 ORDER BY 2 DESC LIMIT 10;
SQL
echo DONE
