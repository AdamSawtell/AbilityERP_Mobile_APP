#!/usr/bin/env bash
# SAW022 — Shift (Rostered) Roster Period Find default
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
SQL="$ROOT/sql"
export PGPASSWORD="${PGPASSWORD:-adempiere}"
PSQL=(psql -h "${PGHOST:-localhost}" -U "${PGUSER:-adempiere}" -d "${PGDATABASE:-idempiere}" -v ON_ERROR_STOP=1)

echo "SAW022: preflight..."
"${PSQL[@]}" -f "$SQL/00-preflight.sql"
echo "SAW022: apply..."
"${PSQL[@]}" -f "$SQL/01-set-period-default.sql"
echo "SAW022: verify..."
"${PSQL[@]}" -f "$SQL/02-verify.sql"
echo "SAW022: done. Cache Reset or logout/in — no JAR / no restart."
