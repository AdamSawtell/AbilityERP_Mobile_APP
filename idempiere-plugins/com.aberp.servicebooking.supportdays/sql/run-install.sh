#!/bin/bash
set -euo pipefail
DIR="${1:-/tmp/saw009-sql}"
cd "$DIR"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -P pager=off <<'SQL'
SET search_path TO adempiere;
\i 00-preflight.sql
\i 01-add-support-day-columns.sql
\i 02-add-fields.sql
\i 03-backfill-from-pattern.sql
\i 04-sync-trigger.sql
\i 05-verify.sql
SQL
