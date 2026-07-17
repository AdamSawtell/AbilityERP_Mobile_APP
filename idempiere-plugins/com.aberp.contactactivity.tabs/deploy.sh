#!/bin/bash
# Deploy Contact Activity tabs plugin to iDempiere.
# OTHER BUILDS: portable registration (name/UU). Do NOT use seed window IDs in sql/02–03.
# Optional: ABERP_ACTIVITY_SEED_SQL=1 to force legacy seed-ID path (reference tenant only).
set -euo pipefail

IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="7.1.0.202607092300"
SYMBOLIC="com.aberp.contactactivity.tabs"
JAR_NAME="${SYMBOLIC}_${VERSION}.jar"
BUILT_JAR="$PLUGIN_DIR/build/dist/$JAR_NAME"
BUNDLES_INFO="${IDEMPIERE_HOME}/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info"

if [ ! -f "$BUILT_JAR" ] || [ "$PLUGIN_DIR/META-INF/MANIFEST.MF" -nt "$BUILT_JAR" ] 2>/dev/null; then
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
if [ "${ABERP_ACTIVITY_SEED_SQL:-0}" = "1" ]; then
  echo "WARNING: seed-ID SQL path (window IDs hardcoded) — reference tenant only"
  for sql in sql/01-add-link-columns.sql sql/02-add-activity-tabs.sql sql/03-update-activity-type-windows.sql; do
    sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$PLUGIN_DIR/$sql"
  done
else
  # Portable other-build path
  sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$PLUGIN_DIR/sql/01-add-link-columns.sql"
  sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$PLUGIN_DIR/register-contactactivity-tabs.sql"
  sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$PLUGIN_DIR/fix-activity-user-contact.sql"
  sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$PLUGIN_DIR/sql/04-ensure-activity-types.sql"
  # SAW026 — Vehicle Activity tab (idempotent; skips BP user/contact inheritance)
  sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$PLUGIN_DIR/sql/05-add-vehicle-activity-tab.sql"
  sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$PLUGIN_DIR/sql/95-verify-vehicle-activity-tab.sql"
fi

echo "Restarting iDempiere via systemd"
sudo systemctl restart idempiere

echo "Waiting for WebUI (up to 6 minutes)"
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
  echo "Ensuring ${SYMBOLIC} bundle is ACTIVE"
  cd "$CHUBOE_UTILS"
  BUNDLE_ID=$(sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep "${SYMBOLIC}" | awk '{print $1}')
  STATE=$(sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep "${SYMBOLIC}" | awk '{print $2}')
  if [ -n "$BUNDLE_ID" ] && [ "$STATE" != "ACTIVE" ]; then
    ./logilite_telnet_start.sh "$BUNDLE_ID" || true
  fi
fi

echo "Deploy complete — log out/in on WebUI."
echo "Tickets: Tickets/SAW007_activity_tab_integration/DEPLOY.md · Tickets/SAW026_vehicle_activity_tab/DEPLOY.md"
