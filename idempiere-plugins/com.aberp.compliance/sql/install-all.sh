#!/bin/bash
set -euo pipefail
cd /tmp/saw023-sql
for f in \
  00-preflight.sql \
  01-create-tables.sql \
  02-ad-references.sql \
  03-ad-table-columns.sql \
  04-dashboard-view.sql \
  05-rules-window.sql \
  06-summary-window.sql \
  07-menu-access.sql \
  08-seed-dummy-snapshot.sql \
  09-verify.sql \
  10-menu-window-trl.sql \
  11-org-audit-tab-name.sql \
  12-org-header-category-tabs.sql \
  13-rename-ndis-audit-tool.sql
do
  echo "===== $f ====="
  sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$f"
done
echo "===== DONE ====="
