#!/bin/bash
set -euo pipefail
LOGDIR=/tmp/saw018-logs
mkdir -p "$LOGDIR"
sudo mkdir -p /tmp/saw018-one
sudo chown -R idempiere:idempiere /tmp/saw018-one 2>/dev/null || true

for z in hco_credentials hco_employee hco_client hco_supportlocation; do
  echo ""
  echo "######## PACKIN $z ########"
  sudo rm -rf /tmp/saw018-one
  sudo mkdir -p /tmp/saw018-one
  sudo cp "/tmp/${z}.zip" /tmp/saw018-one/
  sudo chown -R idempiere:idempiere /tmp/saw018-one
  cd /opt/idempiere-server/utils
  set +e
  sudo -u idempiere ./RUN_ApplyPackInFromFolder.sh /tmp/saw018-one > "$LOGDIR/${z}.log" 2>&1
  rc=$?
  set -e
  echo "exit=$rc"
  tail -50 "$LOGDIR/${z}.log"
  PGPASSWORD=flamingo psql -h localhost -U adempiere -d idempiere -c \
    "SELECT ad_package_imp_id, name, pk_status, processed FROM adempiere.ad_package_imp ORDER BY created DESC LIMIT 5;"
done

echo "=== VERIFY ==="
PGPASSWORD=flamingo psql -h localhost -U adempiere -d idempiere -f /tmp/02-verify.sql
echo "DONE"
