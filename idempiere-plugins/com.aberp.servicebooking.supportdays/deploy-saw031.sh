#!/bin/bash
# SAW031 — stop EEEE weekday overwrite on Support Start/End Day + cleanup bad data.
set -euo pipefail

IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
SQL_DIR="$PLUGIN_DIR/sql"
VERSION="7.1.0.2026072205"
SYMBOLIC="com.aberp.servicebooking.supportdays"
JAR_NAME="${SYMBOLIC}_${VERSION}.jar"
BUILT_JAR="$PLUGIN_DIR/build/dist/$JAR_NAME"
BUNDLES_INFO="${IDEMPIERE_HOME}/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info"

sed -i 's/\r$//' "$PLUGIN_DIR"/*.sh 2>/dev/null || true
sed -i 's/\r$//' "$SQL_DIR"/*.sql 2>/dev/null || true

echo "SAW031: building model overlay JAR"
bash "$PLUGIN_DIR/build.sh"

echo "SAW031: installing $JAR_NAME"
sudo cp "$BUILT_JAR" "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME"
sudo cp "$BUILT_JAR" "${IDEMPIERE_HOME}/plugins/$JAR_NAME"
sudo chown idempiere:idempiere "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME" "${IDEMPIERE_HOME}/plugins/$JAR_NAME" 2>/dev/null || true

sudo sed -i "/^${SYMBOLIC},/d" "$BUNDLES_INFO"
echo "${SYMBOLIC},${VERSION},plugins/${JAR_NAME},4,true" | sudo tee -a "$BUNDLES_INFO" >/dev/null

echo "SAW031: cleanup weekday text + re-backfill from pattern"
for f in 06-cleanup-weekday-text.sql 07-verify-saw031.sql; do
  echo "=== $f ==="
  sudo cp "$SQL_DIR/$f" "/tmp/saw031-$f"
  sudo chmod a+r "/tmp/saw031-$f"
  sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -P pager=off -f "/tmp/saw031-$f"
done

echo "SAW031: restarting iDempiere"
sudo /etc/init.d/idempiere stop || true
sleep 3
sudo /etc/init.d/idempiere start

echo "Waiting for WebUI"
for i in $(seq 1 40); do
  sleep 15
  CODE=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/webui/ || curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/webui/ || echo 000)
  echo "  attempt $i: HTTP $CODE"
  if [ "$CODE" = "200" ]; then
    break
  fi
done

echo "SAW031 deploy complete — Cache Reset / logout-in, then smoke Validate on Service Booking Line."
