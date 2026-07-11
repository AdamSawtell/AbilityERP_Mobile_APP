#!/bin/bash
# Deploy Rostering Chat plugin to iDempiere and register AD metadata.
set -euo pipefail

IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="7.1.0.202607111450"
SYMBOLIC="com.aberp.rostering.chat"
JAR_NAME="${SYMBOLIC}_${VERSION}.jar"
BUILT_JAR="$PLUGIN_DIR/build/dist/$JAR_NAME"
BUNDLES_INFO="${IDEMPIERE_HOME}/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info"

if [ ! -f "$BUILT_JAR" ]; then
  echo "Building plugin..."
  bash "$PLUGIN_DIR/build.sh"
fi

if find "$PLUGIN_DIR/src" -name '*.java' -newer "$BUILT_JAR" 2>/dev/null | grep -q .; then
  echo "Rebuilding plugin (sources changed)..."
  bash "$PLUGIN_DIR/build.sh"
fi

echo "Installing $JAR_NAME"
sudo cp "$BUILT_JAR" "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME"
sudo cp "$BUILT_JAR" "${IDEMPIERE_HOME}/plugins/$JAR_NAME"
sudo chown idempiere:idempiere "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME" "${IDEMPIERE_HOME}/plugins/$JAR_NAME"

sudo sed -i "/^${SYMBOLIC},/d" "$BUNDLES_INFO"
echo "${SYMBOLIC},${VERSION},plugins/${JAR_NAME},4,true" | sudo tee -a "$BUNDLES_INFO" >/dev/null

echo "Applying AD registration SQL"
sudo cp "$PLUGIN_DIR/sql/install-rostering-chat.sql" /tmp/install-rostering-chat.sql
sudo -u postgres psql -d idempiere -f /tmp/install-rostering-chat.sql

# install-rostering-chat.sql resets field layout; re-apply silent Send/Close UX
for sql in 21-send-button-awaiting-order.sql 24-silent-send-close.sql 25-silent-reply-default.sql; do
  if [ -f "$PLUGIN_DIR/sql/$sql" ]; then
    echo "Applying $sql"
    sudo cp "$PLUGIN_DIR/sql/$sql" "/tmp/$sql"
    sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -c "SET search_path TO adempiere, public;" -f "/tmp/$sql"
  fi
done
# Keep Send/Close visible (displaylogic on R_Status_ID can hide buttons when context is empty)
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 <<'EOSQL'
SET search_path TO adempiere, public;
UPDATE ad_field f
SET displaylogic = NULL, updated = NOW(), updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname IN ('AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat');
EOSQL

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

echo "Deploy complete — log out/in on WebUI, then open Rostering Chat"
