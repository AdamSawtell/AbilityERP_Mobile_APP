#!/bin/bash
# Deploy Invoice Capture plugin + AD on iDempiere host (same-box OCR).
set -euo pipefail

IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="7.1.0.202607142100"
SYMBOLIC="com.aberp.invoicecapture"
JAR_NAME="${SYMBOLIC}_${VERSION}.jar"
BUILT_JAR="$PLUGIN_DIR/build/dist/$JAR_NAME"
BUNDLES_INFO="${IDEMPIERE_HOME}/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info"

echo "Ensuring OCR host tools (poppler + tesseract)"
if ! command -v pdftotext >/dev/null 2>&1 || ! command -v tesseract >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq poppler-utils tesseract-ocr
fi
pdftotext -v 2>&1 | head -1 || true
tesseract --version 2>&1 | head -1 || true

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
for f in 00-preflight.sql 01-create-tables.sql 02-status-reference.sql 03-ad-table-columns.sql \
         04-window-tabs-fields.sql 05-processes-button.sql 06-menu-access.sql 07-scheduler.sql \
         09-batch-menu.sql 10-enable-attachment.sql 11-fix-pk-field.sql \
         12-fix-org-default-docno.sql 13-fix-client-field.sql 08-verify.sql; do
  sudo cp "$PLUGIN_DIR/sql/$f" "/tmp/saw019-$f"
  echo "  -> $f"
  sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "/tmp/saw019-$f"
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

echo "Deploy complete — Cache Reset / logout-in, then smoke Invoice Capture → Process Selected Invoice"
