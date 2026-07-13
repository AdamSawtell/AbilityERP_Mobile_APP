#!/bin/bash
# Deploy Skip Dates Copy Dates From plugin + AD registration on iDempiere host.
set -euo pipefail

IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="7.1.0.202607131830"
SYMBOLIC="com.aberp.skipdates.copyfrom"
JAR_NAME="${SYMBOLIC}_${VERSION}.jar"
BUILT_JAR="$PLUGIN_DIR/build/dist/$JAR_NAME"
BUNDLES_INFO="${IDEMPIERE_HOME}/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info"

if [ ! -f "$BUILT_JAR" ] || [ "$PLUGIN_DIR/src/com/aberp/skipdates/copyfrom/CopyDatesFrom.java" -nt "$BUILT_JAR" ] 2>/dev/null; then
  echo "Building plugin..."
  bash "$PLUGIN_DIR/build.sh"
fi

echo "Installing $JAR_NAME"
sudo cp "$BUILT_JAR" "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME"
sudo cp "$BUILT_JAR" "${IDEMPIERE_HOME}/plugins/$JAR_NAME"
sudo chown idempiere:idempiere "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME" "${IDEMPIERE_HOME}/plugins/$JAR_NAME"

sudo sed -i "/^${SYMBOLIC},/d" "$BUNDLES_INFO"
echo "${SYMBOLIC},${VERSION},plugins/${JAR_NAME},4,true" | sudo tee -a "$BUNDLES_INFO" >/dev/null

echo "Applying AD registration SQL"
sudo cp "$PLUGIN_DIR/sql/00-preflight.sql" /tmp/saw015-00-preflight.sql
sudo cp "$PLUGIN_DIR/sql/01-install-copy-dates-from.sql" /tmp/saw015-01-install.sql
sudo cp "$PLUGIN_DIR/sql/02-button-window-style.sql" /tmp/saw015-02-button.sql
sudo cp "$PLUGIN_DIR/sql/04-verify.sql" /tmp/saw015-04-verify.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f /tmp/saw015-00-preflight.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f /tmp/saw015-01-install.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f /tmp/saw015-02-button.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f /tmp/saw015-04-verify.sql

echo "Restarting iDempiere via systemd (NOT clearing OSGi cache)"
# Force stop first — 'restart' can no-op with stale 'already running' when Java is down
sudo /etc/init.d/idempiere stop || true
sleep 3
sudo /etc/init.d/idempiere start

echo "Waiting for WebUI (up to 6 minutes)"
for i in $(seq 1 40); do
  sleep 15
  CODE=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/webui/ || echo 000)
  echo "  attempt $i: HTTP $CODE"
  if [ "$CODE" = "200" ]; then
    break
  fi
done

sudo systemctl is-active idempiere
curl -s -o /dev/null -w 'WebUI HTTP %{http_code}\n' http://127.0.0.1:8080/webui/

CHUBOE_UTILS="/opt/chuboe/idempiere-installation-script/utils"
if [ -d "$CHUBOE_UTILS" ]; then
  echo "Ensuring ${SYMBOLIC} bundle is ACTIVE"
  cd "$CHUBOE_UTILS"
  BUNDLE_ID=$(sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep "${SYMBOLIC}" | awk '{print $1}')
  STATE=$(sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep "${SYMBOLIC}" | awk '{print $2}')
  if [ -n "$BUNDLE_ID" ] && [ "$STATE" != "ACTIVE" ]; then
    ./logilite_telnet_start.sh "$BUNDLE_ID" || true
    sleep 2
    sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep "${SYMBOLIC}" || true
  else
    sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep "${SYMBOLIC}" || true
  fi
fi

echo "Deploy complete — Cache Reset / logout-in, then smoke Skip Dates → Copy Dates From"
