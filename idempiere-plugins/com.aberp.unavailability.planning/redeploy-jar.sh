#!/bin/bash
# JAR-only redeploy (no SQL) + force WebUI restart.
set -euo pipefail
P="$(cd "$(dirname "$0")" && pwd)"
IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
VERSION="1.0.0.2026071402"
SYMBOLIC="com.aberp.unavailability.planning"
JAR_NAME="${SYMBOLIC}_${VERSION}.jar"

perl -pi -e 's/\r\n/\n/g' "$P"/*.sh 2>/dev/null || true
SRC=$P/src
BUILD=$P/build
CLASSES=$BUILD/classes
rm -rf "$BUILD"
mkdir -p "$CLASSES" "$P/release" "$BUILD/dist"

BASE=$(ls "$IDEMPIERE_HOME"/plugins/org.adempiere.base_*.jar | head -1)
UTILS=$(ls "$IDEMPIERE_HOME"/plugins/org.adempiere.plugin.utils_*.jar | head -1)
UIZK=$(ls "$IDEMPIERE_HOME"/plugins/org.adempiere.ui.zk_*.jar | head -1)
UI=$(ls "$IDEMPIERE_HOME"/plugins/org.adempiere.ui_*.jar | head -1)
ZUL=$(ls "$IDEMPIERE_HOME"/plugins/zul_*.jar | head -1)
ZK=$(ls "$IDEMPIERE_HOME"/plugins/zk_*.jar | head -1)
ZCOMMON=$(ls "$IDEMPIERE_HOME"/plugins/zcommon_*.jar | head -1)
CP="$BASE:$UTILS:$UIZK:$UI:$ZUL:$ZK:$ZCOMMON"
for j in "$IDEMPIERE_HOME"/plugins/org.adempiere.base.callout_*.jar \
         "$IDEMPIERE_HOME"/plugins/org.compiere.db.postgresql.provider_*.jar \
         "$IDEMPIERE_HOME"/plugins/org.apache.ecs_*.jar; do
  [ -f "$j" ] && CP="$CP:$j"
done

find "$SRC" -name '*.java' > "$BUILD/sources.txt"
while IFS= read -r f; do sed -i 's/\r$//' "$f" || true; done < "$BUILD/sources.txt"
javac -encoding UTF-8 -source 11 -target 11 -classpath "$CP" -d "$CLASSES" @"$BUILD/sources.txt"
cp "$P/unavailabilityplanning-info.xml" "$CLASSES/"
jar cfm "$BUILD/dist/$JAR_NAME" "$P/META-INF/MANIFEST.MF" -C "$CLASSES" .
cp "$BUILD/dist/$JAR_NAME" "$P/release/$JAR_NAME"

sudo rm -f "$IDEMPIERE_HOME"/plugins/${SYMBOLIC}_*.jar "$IDEMPIERE_HOME"/customization-jar/${SYMBOLIC}_*.jar
sudo cp "$BUILD/dist/$JAR_NAME" "$IDEMPIERE_HOME/plugins/$JAR_NAME"
sudo cp "$BUILD/dist/$JAR_NAME" "$IDEMPIERE_HOME/customization-jar/$JAR_NAME"
sudo chown idempiere:idempiere "$IDEMPIERE_HOME/plugins/$JAR_NAME" "$IDEMPIERE_HOME/customization-jar/$JAR_NAME" || true
B=$IDEMPIERE_HOME/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info
sudo sed -i "/^${SYMBOLIC},/d" "$B"
echo "${SYMBOLIC},${VERSION},plugins/${JAR_NAME},4,true" | sudo tee -a "$B" >/dev/null

echo "Installed $JAR_NAME — force-starting WebUI"
sudo bash /opt/idempiere-server/AbERP/com.aberp.leave.planning/force-start-webui.sh
