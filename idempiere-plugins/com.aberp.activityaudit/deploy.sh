#!/bin/bash
# Deploy Activity Audit plugin + AD on iDempiere host.
set -euo pipefail

IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="7.1.0.202607180800"
SYMBOLIC="com.aberp.activityaudit"
JAR_NAME="${SYMBOLIC}_${VERSION}.jar"
BUILT_JAR="$PLUGIN_DIR/build/dist/$JAR_NAME"
BUNDLES_INFO="${IDEMPIERE_HOME}/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info"

echo "Building plugin..."
bash "$PLUGIN_DIR/build.sh"

echo "Installing $JAR_NAME"
sudo mkdir -p "${IDEMPIERE_HOME}/customization-jar"
sudo cp "$BUILT_JAR" "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME"
sudo cp "$BUILT_JAR" "${IDEMPIERE_HOME}/plugins/$JAR_NAME"
sudo chown idempiere:idempiere "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME" "${IDEMPIERE_HOME}/plugins/$JAR_NAME"

sudo sed -i "/^${SYMBOLIC},/d" "$BUNDLES_INFO"
echo "${SYMBOLIC},${VERSION},plugins/${JAR_NAME},4,true" | sudo tee -a "$BUNDLES_INFO" >/dev/null

echo "Applying AD SQL"
for f in 00-preflight.sql 01-create-tables.sql 02-ad-references.sql 03-ad-table-columns.sql \
         04-windows.sql 05-processes.sql 06-menu-access.sql 07-scheduler.sql \
         08-seed-terms.sql 09-verify.sql 10-fix-review-grid.sql 11-fix-processing-column.sql \
         12-open-activity-button.sql 13-fix-terms-grid.sql 14-format-audit-fieldgroup.sql \
         15-fix-isactive-edit.sql; do
  sudo cp "$PLUGIN_DIR/sql/$f" "/tmp/saw027-$f"
  echo "  -> $f"
  sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "/tmp/saw027-$f"
done

echo "Restarting iDempiere (NOT clearing OSGi cache)"
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
  if [ -n "${BUNDLE_ID:-}" ] && [ "${STATE:-}" != "ACTIVE" ]; then
    ./logilite_telnet_start.sh "$BUNDLE_ID" || true
    sleep 2
  fi
  sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep "${SYMBOLIC}" || true
fi

echo "Deploy complete — Cache Reset / logout-in, then smoke Activity Audit Terms + Nightly"
