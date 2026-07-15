#!/bin/bash
# Deploy SAW017 Bulk Generate Bookings (additive). Does not install Flamingo generator JAR.
set -euo pipefail

IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="7.1.0.202607160715"
SYMBOLIC="com.aberp.bookinggenerator.bulk"
JAR_NAME="${SYMBOLIC}_${VERSION}.jar"
BUILT_JAR="$PLUGIN_DIR/build/dist/$JAR_NAME"
BUNDLES_INFO="${IDEMPIERE_HOME}/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info"

if [ ! -f "$BUILT_JAR" ] || [ "$PLUGIN_DIR/src/com/aberp/bookinggenerator/bulk/BulkGenerateBookings.java" -nt "$BUILT_JAR" ] 2>/dev/null; then
  echo "Building plugin..."
  bash "$PLUGIN_DIR/build.sh"
fi

echo "Installing $JAR_NAME"
sudo cp "$BUILT_JAR" "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME"
sudo cp "$BUILT_JAR" "${IDEMPIERE_HOME}/plugins/$JAR_NAME"
sudo chown idempiere:idempiere "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME" "${IDEMPIERE_HOME}/plugins/$JAR_NAME" 2>/dev/null || true

sudo sed -i "/^${SYMBOLIC},/d" "$BUNDLES_INFO"
echo "${SYMBOLIC},${VERSION},plugins/${JAR_NAME},4,true" | sudo tee -a "$BUNDLES_INFO" >/dev/null

echo "Applying AD registration SQL"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$PLUGIN_DIR/sql/00-preflight.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$PLUGIN_DIR/sql/01-install-bulk-generate.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$PLUGIN_DIR/sql/02-fix-docaction-list.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$PLUGIN_DIR/sql/03-fix-yesno-display.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$PLUGIN_DIR/sql/04-verify.sql"

echo "Restarting iDempiere"
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

echo "Deploy complete — Cache Reset / logout-in"
echo "NOTE: Bulk Generate calls existing Generate Bookings at runtime."
echo "      Install com.aberp.servicebooking.generator (+ deps) before expecting successful generation."
