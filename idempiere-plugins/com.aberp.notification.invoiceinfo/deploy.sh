#!/bin/bash
# Deploy Paid filter for Notification SR Invoice Send Info (AD only — no OSGi jar).
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"

# Normalize CRLF if edited on Windows
sed -i 's/\r$//' "$PLUGIN_DIR/deploy.sh" 2>/dev/null || true

echo "Applying Paid filter SQL for Notification SR Invoice Send Info"
for f in 01-add-paid-criteria.sql 04-add-info-menu.sql 02-verify.sql 03-functional-check.sql; do
  echo "=== $f ==="
  sudo cp "$PLUGIN_DIR/sql/$f" "/tmp/$f"
  sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "/tmp/$f"
done

echo "Deploy complete."
echo "Next: Cache Reset (or log out/in), then open Notification SR Invoice Send Info and test Paid = Yes / No / blank."
