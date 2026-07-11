#!/bin/bash
# Deploy AbERP Rostering Staff Info rewrite to the local iDempiere DB.
# AD-only: no OSGi restart required. Users must log out/in to refresh AD cache.
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="1.0.0.2026071101"
SYMBOLIC="com.aberp.rostering.staffinfo"
JAR_NAME="${SYMBOLIC}_${VERSION}.jar"
IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
DIST_JAR="$PLUGIN_DIR/build/dist/$JAR_NAME"

if [ ! -f "$DIST_JAR" ]; then
  echo "Building distribution JAR..."
  bash "$PLUGIN_DIR/build.sh"
fi

echo "Publishing $JAR_NAME to customization-jar (portable artifact)"
sudo mkdir -p "${IDEMPIERE_HOME}/customization-jar"
sudo cp "$DIST_JAR" "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME"
sudo chown idempiere:idempiere "${IDEMPIERE_HOME}/customization-jar/$JAR_NAME" || true

echo "Applying SQL 01 → 04"
for f in 01-indexes.sql 02-rewrite-infowindow.sql 03-rewrite-infocolumns.sql 04-verify.sql; do
  echo "=== $f ==="
  sudo cp "$PLUGIN_DIR/sql/$f" "/tmp/$f"
  sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f "/tmp/$f"
done

echo
echo "Deploy complete."
echo "Artifact: ${IDEMPIERE_HOME}/customization-jar/$JAR_NAME"
echo "Next: log out and log back into iDempiere WebUI, then open Shift Employee → Employee (User) search."
