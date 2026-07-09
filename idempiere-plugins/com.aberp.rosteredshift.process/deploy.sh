#!/bin/bash
# Deploy Accept Shift Request plugin to iDempiere and register AD metadata.
set -euo pipefail

IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="7.1.0.202607091200"
JAR_NAME="com.aberp.rosteredshift.process_${VERSION}.jar"
BUILT_JAR="$PLUGIN_DIR/build/dist/$JAR_NAME"

if [ ! -f "$BUILT_JAR" ]; then
  echo "Building plugin..."
  bash "$PLUGIN_DIR/build.sh"
fi

echo "Installing $JAR_NAME"
sudo cp "$BUILT_JAR" "$IDEMPIERE_HOME/customization-jar/$JAR_NAME"
sudo cp "$BUILT_JAR" "$IDEMPIERE_HOME/plugins/$JAR_NAME"
sudo chown idempiere:idempiere "$IDEMPIERE_HOME/customization-jar/$JAR_NAME" "$IDEMPIERE_HOME/plugins/$JAR_NAME"

BUNDLES_INFO="$IDEMPIERE_HOME/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info"
SYMBOLIC="com.aberp.rosteredshift.process"
if ! grep -q "^${SYMBOLIC}," "$BUNDLES_INFO"; then
  echo "Registering OSGi bundle in bundles.info"
  echo "${SYMBOLIC},${VERSION},plugins/${JAR_NAME},4,false" | sudo tee -a "$BUNDLES_INFO" >/dev/null
fi

echo "Applying AD registration SQL"
sudo cp "$PLUGIN_DIR/sql/register-accept-shift-request.sql" /tmp/register-accept-shift-request.sql
sudo -u postgres psql -d idempiere -f /tmp/register-accept-shift-request.sql

echo "Restarting iDempiere (requires sudo)"
if [ -x "$IDEMPIERE_HOME/utils/stopServer.sh" ]; then
  sudo -u idempiere bash "$IDEMPIERE_HOME/utils/stopServer.sh" || true
  sleep 5
  sudo -u idempiere bash "$IDEMPIERE_HOME/idempiere-server.sh" &
  echo "iDempiere restart initiated"
else
  echo "Restart idempiere manually to load the new bundle"
fi

echo "Deploy complete"
