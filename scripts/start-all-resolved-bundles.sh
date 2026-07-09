#!/bin/bash
# Start all RESOLVED OSGi bundles (AbERP customization plugins lost after cache wipe).
set -euo pipefail
CHUBOE_UTILS="/opt/chuboe/idempiere-installation-script/utils"
cd "$CHUBOE_UTILS"

if ! systemctl is-active --quiet idempiere; then
  echo "iDempiere not running"
  exit 1
fi

STARTED=0
FAILED=0
ROUNDS=0
MAX_ROUNDS=5

while [ "$ROUNDS" -lt "$MAX_ROUNDS" ]; do
  ROUNDS=$((ROUNDS + 1))
  echo "=== Round $ROUNDS ==="
  RESOLVED=$(sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | awk '$2=="RESOLVED" {print $1}')
  [ -z "$RESOLVED" ] && break
  for id in $RESOLVED; do
    echo -n "Starting bundle $id... "
    OUT=$(./logilite_telnet_start.sh "$id" 2>&1 || true)
    if echo "$OUT" | grep -qi 'BundleException\|Could not resolve'; then
      echo "FAILED"
      FAILED=$((FAILED + 1))
    else
      echo "OK"
      STARTED=$((STARTED + 1))
    fi
    sleep 0.5
  done
done

echo "=== Summary: started=$STARTED failed=$FAILED ==="
sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | awk '{print $2}' | sort | uniq -c

echo "=== acceptrequest ==="
sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep acceptrequest
