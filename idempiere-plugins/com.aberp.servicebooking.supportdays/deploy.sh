#!/bin/bash
# SAW009 — Support Start/End Day numbered list on Service Booking Line (AD/SQL only).
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
SQL_DIR="$PLUGIN_DIR/sql"

sed -i 's/\r$//' "$PLUGIN_DIR/deploy.sh" 2>/dev/null || true
sed -i 's/\r$//' "$SQL_DIR"/*.sql 2>/dev/null || true

echo "SAW009: applying Service Booking Line support-day pattern number SQL"
for f in \
  00-preflight.sql \
  01-add-support-day-columns.sql \
  02-add-fields.sql \
  03-backfill-from-pattern.sql \
  04-sync-trigger.sql \
  05-verify.sql
do
  echo "=== $f ==="
  sudo cp "$SQL_DIR/$f" "/tmp/saw009-$f"
  sudo chmod a+r "/tmp/saw009-$f"
  sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -P pager=off -f "/tmp/saw009-$f"
done

echo "Deploy complete."
echo "Next: WebUI Cache Reset (or log out/in), then smoke Service Booking → Service Booking Line Support Start/End Day."
echo "No iDempiere restart. No JAR."
