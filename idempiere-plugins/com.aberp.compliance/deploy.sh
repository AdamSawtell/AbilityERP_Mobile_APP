#!/bin/bash
# Deploy Compliance Refresh process + AD registration on iDempiere host.
set -euo pipefail

IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="7.1.0.202607170545"
SYMBOLIC="com.aberp.compliance"
JAR_NAME="${SYMBOLIC}_${VERSION}.jar"
BUILT_JAR="$PLUGIN_DIR/build/dist/$JAR_NAME"
BUNDLES_INFO="${IDEMPIERE_HOME}/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info"
SQL_DIR="$PLUGIN_DIR/sql"

if [ ! -f "$BUILT_JAR" ] || [ "$PLUGIN_DIR/src/com/aberp/compliance/RefreshCompliance.java" -nt "$BUILT_JAR" ] 2>/dev/null; then
  echo "Building plugin..."
  bash "$PLUGIN_DIR/build.sh"
fi

echo "Installing $JAR_NAME"
sudo cp "$BUILT_JAR" "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME"
sudo cp "$BUILT_JAR" "${IDEMPIERE_HOME}/plugins/$JAR_NAME"
sudo chown idempiere:idempiere "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME" "${IDEMPIERE_HOME}/plugins/$JAR_NAME"

sudo sed -i "/^${SYMBOLIC},/d" "$BUNDLES_INFO"
echo "${SYMBOLIC},${VERSION},plugins/${JAR_NAME},4,true" | sudo tee -a "$BUNDLES_INFO" >/dev/null

echo "Applying Phase-2/3/4 AD SQL"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/04-dashboard-view.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/14-refresh-compliance-process.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/15-seed-employee-rules.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/16-seed-remaining-rules.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/17-audit-results-info.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/18-employee-open-findings.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/19-employee-findings-subtab.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/20-fix-open-assignment-zoom.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/21-physical-open-assignment.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/22-zoom-condition-credential.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/23-source-record-zoom-field.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/24-source-assignment-link.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/25-assignment-label-toolbar.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/26-rename-org-audit-menu.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/27-restore-org-audit-menu.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/28-assignment-zoom-field.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/29-assignment-search-zoom.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/30-open-fix-pathway.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/31-clickable-assignment-pathway.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/32-physical-open-fix-button.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/33-open-findings-all-categories.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/34-rename-findings-tabs.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/35-category-population-summary.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/36-fix-population-client-90d.sql"
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "$SQL_DIR/37-category-kpi-expansion.sql"

echo "Restarting iDempiere via systemd (NOT clearing OSGi cache)"
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

echo "Deploy complete — Cache Reset / logout-in, then Organisation Audit → Employee → Open Findings → Process → Open & Fix Source"
