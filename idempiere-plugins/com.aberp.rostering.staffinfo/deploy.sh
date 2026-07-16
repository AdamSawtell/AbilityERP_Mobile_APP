#!/bin/bash
# Deploy AbERP Rostering Staff Info (SQL AD + Java Info/Callout) to iDempiere.
set -euo pipefail

IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="1.1.0.2026071517"
SYMBOLIC="com.aberp.rostering.staffinfo"
JAR_NAME="${SYMBOLIC}_${VERSION}.jar"
BUILT_JAR="$PLUGIN_DIR/build/dist/$JAR_NAME"
BUNDLES_INFO="${IDEMPIERE_HOME}/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info"

# Normalize CRLF if edited on Windows (do not use sed s/\r$/ — GNU sed may eat trailing r)
perl -pi -e 's/\r\n/\n/g' "$PLUGIN_DIR/build.sh" "$PLUGIN_DIR/deploy.sh" 2>/dev/null || true

if [ ! -f "$BUILT_JAR" ] || find "$PLUGIN_DIR/src" -name '*.java' -newer "$BUILT_JAR" 2>/dev/null | grep -q .; then
  echo "Building plugin..."
  bash "$PLUGIN_DIR/build.sh"
fi

echo "Installing $JAR_NAME"
sudo mkdir -p "${IDEMPIERE_HOME}/customization-jar" "${IDEMPIERE_HOME}/plugins"
# Remove older staffinfo jars so only one active version remains
sudo rm -f "${IDEMPIERE_HOME}/plugins/${SYMBOLIC}_"*.jar
sudo rm -f "${IDEMPIERE_HOME}/customization-jar/${SYMBOLIC}_"*.jar
sudo cp "$BUILT_JAR" "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME"
sudo cp "$BUILT_JAR" "${IDEMPIERE_HOME}/plugins/$JAR_NAME"
sudo chown idempiere:idempiere "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME" "${IDEMPIERE_HOME}/plugins/$JAR_NAME" || true

sudo sed -i "/^${SYMBOLIC},/d" "$BUNDLES_INFO"
echo "${SYMBOLIC},${VERSION},plugins/${JAR_NAME},4,true" | sudo tee -a "$BUNDLES_INFO" >/dev/null

echo "Applying SQL 01 → 25 → 04"
for f in \
  01-indexes.sql \
  02-rewrite-infowindow.sql \
  03-rewrite-infocolumns.sql \
  05-hotfix-browser-smoke.sql \
  06-fix-shift-org.sql \
  07-eligibility-criteria.sql \
  08-enable-related-info.sql \
  09-find-fill-ux.sql \
  10-java-ux-org.sql \
  11-drop-redundant-criteria.sql \
  12-needs-match-criteria.sql \
  14-fix-show-unmatched-selectclause.sql \
  15-fix-onapprovedleave-criteria.sql \
  16-fix-nonnegative-id-criteria.sql \
  17-fix-hidden-multiselect-criteria.sql \
  18-fix-result-grid-readonly.sql \
  19-rename-staff-name.sql \
  20-hide-clutter-columns.sql \
  21-fix-nonnegative-multiselect.sql \
  22-harden-nonnegative-editors.sql \
  23-force-no-id-criteria.sql \
  24-perf-staff-info.sql \
  25-hide-eligibility-display-columns.sql \
  04-verify.sql
do
  echo "=== $f ==="
  sudo cp "$PLUGIN_DIR/sql/$f" "/tmp/$f"
  sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "/tmp/$f"
done

echo "Restarting iDempiere (Java OSGi change)"
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
echo "Deploy complete: $JAR_NAME"
echo "Next: Cache Reset or log out/in, then test Shift → Employee → staff Search."
