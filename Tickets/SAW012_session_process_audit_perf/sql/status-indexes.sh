#!/bin/bash
# Read-only status for SAW012 index job
tail -n 60 /tmp/saw012/02-indexes.log
PGPASSWORD=flamingo psql -h localhost -U adempiere -d idempiere -f - <<'SQL'
SELECT c.relname, i.indisvalid
FROM pg_index i JOIN pg_class c ON c.oid=i.indexrelid
WHERE c.relname IN (
  'ad_pinstance_created_ix','ad_session_created_ix','ad_changelog_session_created_ix',
  'ad_issue_created_ix','ad_pinstance_process_created_ix'
)
ORDER BY 1;
SELECT pid, wait_event_type, now()-query_start AS age, left(query,90) AS q
FROM pg_stat_activity
WHERE query ILIKE '%INDEX%' AND state='active' AND pid <> pg_backend_pid();
SQL
