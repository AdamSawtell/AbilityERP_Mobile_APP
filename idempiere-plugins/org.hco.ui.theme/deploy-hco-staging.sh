#!/bin/bash
# SAW033 — install HCO theme on staging host.
# Note: OSGi fragment Jetty-WarPrependFragmentResourcePath does not serve
# theme pages on this iDempiere 7.1 / Jetty 9.4 host. Deploy injects theme/hco
# into org.adempiere.ui.zk (with backup) and sets ZK_THEME=hco.
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
VERSION="$(grep '^Bundle-Version:' "$PLUGIN_DIR/META-INF/MANIFEST.MF" | awk '{print $2}' | tr -d '\r')"
JAR_NAME="org.hco.ui.theme_${VERSION}.jar"
UIZK_JAR="$(ls "$IDEMPIERE_HOME"/plugins/org.adempiere.ui.zk_*.jar | grep -v pre-hco | head -1)"

bash "$PLUGIN_DIR/build.sh"
STAGE_DIR="$PLUGIN_DIR/build/stage"
if [[ ! -d "$STAGE_DIR/theme/hco" ]]; then
  echo "ERROR: build stage missing theme/hco" >&2
  exit 1
fi

echo "Stopping iDempiere..."
sudo /etc/init.d/idempiere stop || true
sleep 3
sudo pkill -f 'org.eclipse.equinox.launcher' || true
sleep 2

if [[ ! -f "${UIZK_JAR}.pre-hco.bak" ]]; then
  sudo cp -a "$UIZK_JAR" "${UIZK_JAR}.pre-hco.bak"
  echo "Backed up $(basename "$UIZK_JAR") -> .pre-hco.bak"
fi

WORKDIR=$(mktemp -d)
cp "$UIZK_JAR" "$WORKDIR/ui.zk.jar"
(
  cd "$STAGE_DIR"
  # replace any previous theme/hco then add fresh
  zip -d "$WORKDIR/ui.zk.jar" 'theme/hco/*' 2>/dev/null || true
  jar uf "$WORKDIR/ui.zk.jar" theme/hco
)
sudo cp -f "$WORKDIR/ui.zk.jar" "$UIZK_JAR"
sudo chown idempiere:idempiere "$UIZK_JAR"
sudo chmod 644 "$UIZK_JAR"

# Keep fragment JAR available for future hosts that support war fragments
sudo cp -f "$PLUGIN_DIR/release/$JAR_NAME" "$IDEMPIERE_HOME/plugins/$JAR_NAME"
sudo cp -f "$PLUGIN_DIR/release/$JAR_NAME" "$IDEMPIERE_HOME/customization-jar/$JAR_NAME" 2>/dev/null || true
sudo chown idempiere:idempiere "$IDEMPIERE_HOME/plugins/$JAR_NAME"
BINFO="$IDEMPIERE_HOME/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info"
if grep -q '^org.hco.ui.theme,' "$BINFO"; then
  sudo sed -i "s#^org.hco.ui.theme,.*#org.hco.ui.theme,$VERSION,plugins/$JAR_NAME,4,true#" "$BINFO"
else
  echo "org.hco.ui.theme,$VERSION,plugins/$JAR_NAME,4,true" | sudo tee -a "$BINFO" >/dev/null
fi

sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 <<'SQL'
SET search_path TO adempiere;
UPDATE ad_sysconfig SET value = 'hco', updated = NOW() WHERE name = 'ZK_THEME';
UPDATE ad_sysconfig SET value = 'Y', updated = NOW() WHERE name = 'ZK_LOGIN_LEFTPANEL_SHOWN';
UPDATE ad_sysconfig SET value = '', updated = NOW() WHERE name IN ('ZK_LOGO_LARGE', 'ZK_LOGO_SMALL');
SELECT name, value FROM ad_sysconfig
 WHERE name IN ('ZK_THEME','ZK_LOGIN_LEFTPANEL_SHOWN','ZK_LOGO_LARGE','ZK_LOGO_SMALL')
 ORDER BY 1;
SQL

echo "Starting iDempiere..."
sudo /etc/init.d/idempiere start
for i in $(seq 1 36); do
  code=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/webui/ || true)
  echo "try $i code=$code"
  if [[ "$code" == "200" ]]; then
    break
  fi
  sleep 5
done
curl -sI http://127.0.0.1/webui/theme/hco/css/theme.css.dsp | head -n 8
echo "Deploy complete."
