#!/bin/bash
set -e
export PGPASSWORD=flamingo
echo "START $(date -Is)"
psql -h localhost -U adempiere -d idempiere -v ON_ERROR_STOP=1 -f /tmp/saw012/08-disable-parent-maxquery-count.sql
psql -h localhost -U adempiere -d idempiere -f /tmp/saw012-k2.sql
sleep 2
sudo -u postgres psql -d idempiere -c "DROP INDEX IF EXISTS adempiere.ad_pinstance_created_ix;"
sudo -u postgres psql -d idempiere -c "DROP INDEX IF EXISTS adempiere.ad_pinstance_created_90d_ix;"
echo "CREATE partial 90d index $(date -Is)"
PGOPTIONS='-c statement_timeout=0' psql -h localhost -U adempiere -d idempiere -c \
  "CREATE INDEX CONCURRENTLY ad_pinstance_created_90d_ix ON adempiere.ad_pinstance (created DESC) WHERE created >= (CURRENT_DATE - INTERVAL '90 days');"
echo "DONE $(date -Is)"
psql -h localhost -U adempiere -d idempiere -c \
  "SELECT c.relname, i.indisvalid FROM pg_index i JOIN pg_class c ON c.oid=i.indexrelid WHERE c.relname LIKE 'ad_pinstance%created%';"
