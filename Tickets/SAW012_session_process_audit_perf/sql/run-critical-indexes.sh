#!/bin/bash
# SAW012 — unblock DB, build critical Created indexes one at a time
set -e
export PGPASSWORD=flamingo
exec >/tmp/saw012/07-critical-ix.log 2>&1
echo "START $(date -Is)"

# Cancel stuck WebUI COUNTs and competing index builds
psql -h localhost -U adempiere -d idempiere <<'SQL'
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE pid <> pg_backend_pid()
  AND datname = 'idempiere'
  AND (
    query ILIKE 'SELECT COUNT(*) FROM AD_PInstance%'
    OR query ILIKE 'SELECT COUNT(*) FROM AD_ChangeLog%'
    OR query ILIKE 'SELECT COUNT(*) FROM AD_Session%'
    OR query ILIKE '%CREATE INDEX CONCURRENTLY%'
    OR query ILIKE '%DROP INDEX%'
  );
SQL

sleep 2

psql -h localhost -U adempiere -d idempiere <<'SQL'
SET statement_timeout = 0;
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT c.relname
    FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid
    WHERE c.relname IN (
      'ad_pinstance_created_ix','ad_changelog_session_created_ix',
      'ad_issue_created_ix','ad_pinstance_process_created_ix'
    ) AND NOT i.indisvalid
  LOOP
    EXECUTE 'DROP INDEX IF EXISTS adempiere.' || quote_ident(r.relname);
    RAISE NOTICE 'dropped invalid %', r.relname;
  END LOOP;
END $$;
SQL

create_one() {
  local name="$1"
  local ddl="$2"
  echo "=== $name $(date -Is) ==="
  if psql -h localhost -U adempiere -d idempiere -tAc "SELECT 1 FROM pg_index i JOIN pg_class c ON c.oid=i.indexrelid WHERE c.relname='${name}' AND i.indisvalid" | grep -q 1; then
    echo "SKIP valid $name"
    return 0
  fi
  psql -h localhost -U adempiere -d idempiere -c "DROP INDEX IF EXISTS adempiere.${name};" || true
  PGOPTIONS='-c statement_timeout=0' psql -h localhost -U adempiere -d idempiere -c "${ddl}"
  echo "DONE $name $(date -Is)"
}

# Most critical for Process Audit Find/COUNT
create_one ad_pinstance_created_ix \
  "CREATE INDEX CONCURRENTLY ad_pinstance_created_ix ON adempiere.ad_pinstance (created DESC);"

create_one ad_changelog_session_created_ix \
  "CREATE INDEX CONCURRENTLY ad_changelog_session_created_ix ON adempiere.ad_changelog (ad_session_id, created DESC);"

create_one ad_pinstance_process_created_ix \
  "CREATE INDEX CONCURRENTLY ad_pinstance_process_created_ix ON adempiere.ad_pinstance (ad_process_id, created DESC);"

create_one ad_issue_created_ix \
  "CREATE INDEX CONCURRENTLY ad_issue_created_ix ON adempiere.ad_issue (created DESC);"

psql -h localhost -U adempiere -d idempiere -c "ANALYZE adempiere.ad_pinstance; ANALYZE adempiere.ad_changelog;"
psql -h localhost -U adempiere -d idempiere -c "SELECT c.relname, i.indisvalid FROM pg_index i JOIN pg_class c ON c.oid=i.indexrelid WHERE c.relname LIKE 'ad_%created%ix%' OR c.relname='ad_pinstance_process_created_ix' ORDER BY 1;"
echo "EXIT:0 $(date -Is)"
