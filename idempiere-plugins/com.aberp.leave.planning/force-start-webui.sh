#!/bin/bash
set -euo pipefail
sudo systemctl stop idempiere || true
sudo mkdir -p /opt/idempiere-server/log
sudo chown -R idempiere:idempiere /opt/idempiere-server/log
LOGNAME="manual_start_$(date +%Y%m%d%H%M%S).log"
echo "Starting -> /opt/idempiere-server/log/${LOGNAME}"
sudo -u idempiere bash -lc "cd /opt/idempiere-server && nohup ./idempiere-server.sh > log/${LOGNAME} 2>&1 &"
for i in $(seq 1 50); do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://127.0.0.1:8080/webui/ || echo 000)
  echo "  wait ${i}: ${code}"
  if [ "${code}" = "200" ]; then
    echo UP
    grep leave.planning /opt/idempiere-server/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info || true
    exit 0
  fi
  if [ $((i % 5)) -eq 0 ]; then
    ps ax | grep -v grep | grep equinox | head -1 || echo "  (no equinox)"
    sudo -u idempiere tail -5 "/opt/idempiere-server/log/${LOGNAME}" 2>/dev/null || true
  fi
  sleep 6
done
echo FAILED
sudo -u idempiere tail -80 "/opt/idempiere-server/log/${LOGNAME}" || true
exit 1
