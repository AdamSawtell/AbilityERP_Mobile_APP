#!/bin/bash
# SAW010 — Timesheet Approval Info Window column cleanup (AD only — no OSGi jar).
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"

sed -i 's/\r$//' "$PLUGIN_DIR/deploy.sh" 2>/dev/null || true

echo "Applying SAW010 Timesheet Approval Info Window SQL"
for f in 00-preflight-uuids.sql 01-update-infocolumns.sql 02-verify.sql 03-functional-check.sql; do
  echo "=== $f ==="
  sudo cp "$PLUGIN_DIR/sql/$f" "/tmp/$f"
  sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "/tmp/$f"
done

echo "Deploy complete."
echo "Next: Cache Reset (or log out/in), then open Timesheet Approval and confirm columns."
echo "Optional seed (staging only): sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/04-seed-test-rows.sql"
