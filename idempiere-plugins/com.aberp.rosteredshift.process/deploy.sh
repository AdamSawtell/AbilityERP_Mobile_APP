#!/bin/bash
# Deploy Accept Shift Request plugin to iDempiere and register AD metadata.
# Uses bundle symbolic name com.aberp.rosteredshift.acceptrequest (separate from
# the official com.aberp.rosteredshift.process 7.1.7 plugin — do not collide).
set -euo pipefail

IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="7.1.0.202607181600"
SYMBOLIC="com.aberp.rosteredshift.acceptrequest"
JAR_NAME="${SYMBOLIC}_${VERSION}.jar"
BUILT_JAR="$PLUGIN_DIR/build/dist/$JAR_NAME"

OFFICIAL_SYMBOLIC="com.aberp.rosteredshift.process"
OFFICIAL_VERSION="7.1.7.202509081930"
OFFICIAL_JAR="${OFFICIAL_SYMBOLIC}_${OFFICIAL_VERSION}.jar"
OFFICIAL_CACHE="${IDEMPIERE_HOME}/configuration/org.eclipse.osgi/1111/5/bundleFile"
BUNDLES_INFO="${IDEMPIERE_HOME}/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info"

if [ ! -f "$BUILT_JAR" ]; then
  echo "Building plugin..."
  bash "$PLUGIN_DIR/build.sh"
fi
# Always rebuild when sources are newer than the JAR
if [ "$PLUGIN_DIR/src/com/aberp/rosteredshift/process/AcceptShiftRequest.java" -nt "$BUILT_JAR" ] 2>/dev/null; then
  echo "Rebuilding plugin (sources changed)..."
  bash "$PLUGIN_DIR/build.sh"
fi

echo "Restoring official ${OFFICIAL_SYMBOLIC} ${OFFICIAL_VERSION} (if missing)"
if [ ! -f "${IDEMPIERE_HOME}/plugins/${OFFICIAL_JAR}" ] && [ -f "$OFFICIAL_CACHE" ]; then
  sudo cp "$OFFICIAL_CACHE" "${IDEMPIERE_HOME}/plugins/${OFFICIAL_JAR}"
  sudo chown idempiere:idempiere "${IDEMPIERE_HOME}/plugins/${OFFICIAL_JAR}"
fi

echo "Removing mistaken ${OFFICIAL_SYMBOLIC} 7.1.0 override JARs"
sudo rm -f "${IDEMPIERE_HOME}/plugins/com.aberp.rosteredshift.process_7.1.0.202607091200.jar"
sudo rm -f "${IDEMPIERE_HOME}/customization-jar/com.aberp.rosteredshift.process_7.1.0.202607091200.jar"

echo "Fixing bundles.info entries"
sudo sed -i "/^${OFFICIAL_SYMBOLIC},7.1.0.202607091200,/d" "$BUNDLES_INFO"
if [ -f "${IDEMPIERE_HOME}/plugins/${OFFICIAL_JAR}" ]; then
  sudo sed -i "/^${OFFICIAL_SYMBOLIC},/d" "$BUNDLES_INFO"
  echo "${OFFICIAL_SYMBOLIC},${OFFICIAL_VERSION},plugins/${OFFICIAL_JAR},4,false" | sudo tee -a "$BUNDLES_INFO" >/dev/null
  # Official bundle requires org.logilite.sms.base — do not autostart here
fi

echo "Installing $JAR_NAME"
sudo cp "$BUILT_JAR" "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME"
sudo cp "$BUILT_JAR" "${IDEMPIERE_HOME}/plugins/$JAR_NAME"
sudo chown idempiere:idempiere "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME" "${IDEMPIERE_HOME}/plugins/$JAR_NAME"

sudo sed -i "/^${SYMBOLIC},/d" "$BUNDLES_INFO"
echo "${SYMBOLIC},${VERSION},plugins/${JAR_NAME},4,true" | sudo tee -a "$BUNDLES_INFO" >/dev/null

echo "Applying AD registration SQL"
sudo cp "$PLUGIN_DIR/sql/install-accept-shift-request.sql" /tmp/install-accept-shift-request.sql
sudo -u postgres psql -d idempiere -f /tmp/install-accept-shift-request.sql

echo "Restarting iDempiere via systemd (NOT clearing OSGi cache — that breaks dynamically installed AbERP plugins)"
sudo systemctl restart idempiere

echo "Waiting for WebUI (up to 6 minutes — do not telnet OSGi during startup)"
for i in $(seq 1 24); do
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
  echo "Ensuring ${SYMBOLIC} bundle is ACTIVE (after WebUI is up)"
  cd "$CHUBOE_UTILS"
  BUNDLE_ID=$(sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep "${SYMBOLIC}" | awk '{print $1}')
  STATE=$(sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep "${SYMBOLIC}" | awk '{print $2}')
  if [ -n "$BUNDLE_ID" ] && [ "$STATE" != "ACTIVE" ]; then
    ./logilite_telnet_start.sh "$BUNDLE_ID" || true
    sleep 2
    sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep "${SYMBOLIC}" || true
  fi
fi

echo "Deploy complete — verify acceptrequest bundle is ACTIVE and AcceptShiftRequest resolves"
