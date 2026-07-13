#!/bin/bash
set -e
sudo -u postgres psql -d idempiere -c "SELECT count(*) AS total, coalesce(state,'null') AS state FROM pg_stat_activity GROUP BY state ORDER BY 1 DESC;"
echo "Terminating waiting DELETE backends..."
sudo -u postgres psql -d idempiere -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='idempiere' AND pid <> pg_backend_pid() AND wait_event_type IS NOT NULL AND query ILIKE '%DELETE%' AND state='active' AND query_start < now() - interval '30 minutes';" || true
# Also terminate 'idle in transaction' if any
sudo -u postgres psql -d idempiere -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='idempiere' AND pid <> pg_backend_pid() AND state = 'idle in transaction' AND state_change < now() - interval '10 minutes';" || true
# Terminate CREATE INDEX waiting if stuck > 1 day? leave indexes alone
sudo -u postgres psql -d idempiere -c "SELECT count(*) AS total, coalesce(state,'null') AS state FROM pg_stat_activity WHERE datname='idempiere' GROUP BY state ORDER BY 1 DESC;"
sudo -u postgres psql -d idempiere -c "SET search_path TO adempiere; SELECT c.columnname, c.istoolbarbutton, p.value FROM ad_column c JOIN ad_table t ON t.ad_table_id=c.ad_table_id LEFT JOIN ad_process p ON p.ad_process_id=c.ad_process_id WHERE t.tablename='AbERP_Skip_Dates' AND c.columnname='AbERP_CopyDatesFrom';"
sudo -u postgres psql -d idempiere -c "SET search_path TO adempiere; SELECT f.name, f.isdisplayed, f.istoolbarbutton, f.isactive FROM ad_field f WHERE f.ad_field_uu='15a01504-c0d4-4f01-8e15-000000000004' OR f.name='Copy Dates From';"
sudo -u postgres psql -d idempiere -c "SET search_path TO adempiere; SELECT r.name FROM ad_process_access pa JOIN ad_process p ON p.ad_process_id=pa.ad_process_id JOIN ad_role r ON r.ad_role_id=pa.ad_role_id WHERE p.value='AbERP_SkipDates_CopyDatesFrom' ORDER BY 1;"
