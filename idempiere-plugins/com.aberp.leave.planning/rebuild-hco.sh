#!/bin/bash
set -euo pipefail
P=/opt/idempiere-server/AbERP/com.aberp.leave.planning
IDEMPIERE_HOME=/opt/idempiere-server
VERSION=1.0.0.2026071402
SYMBOLIC=com.aberp.leave.planning
JAR_NAME=${SYMBOLIC}_${VERSION}.jar

# Ensure sources present
test -f "$P/src/com/aberp/leave/planning/info/LeavePlanningInfoWindow.java"

SRC=$P/src
BUILD=$P/build
CLASSES=$BUILD/classes
rm -rf "$BUILD"
mkdir -p "$CLASSES" "$P/release" "$P/build/dist"

BASE=$(ls $IDEMPIERE_HOME/plugins/org.adempiere.base_*.jar | head -1)
UTILS=$(ls $IDEMPIERE_HOME/plugins/org.adempiere.plugin.utils_*.jar | head -1)
UI=$(ls $IDEMPIERE_HOME/plugins/org.adempiere.ui_*.jar | head -1)
UIZK=$(ls $IDEMPIERE_HOME/plugins/org.adempiere.ui.zk_*.jar | head -1)
ZUL=$(ls $IDEMPIERE_HOME/plugins/zul_*.jar | head -1)
ZK=$(ls $IDEMPIERE_HOME/plugins/zk_*.jar | head -1)
ZCOMMON=$(ls $IDEMPIERE_HOME/plugins/zcommon_*.jar | head -1)
ZWEB=$(ls $IDEMPIERE_HOME/plugins/zweb_*.jar 2>/dev/null | head -1 || true)
# org.adempiere.ui has IMiniTable/ColumnInfo (not in base on this build)
CP="$BASE:$UTILS:$UI:$UIZK:$ZUL:$ZK:$ZCOMMON"
for j in $IDEMPIERE_HOME/plugins/org.adempiere.base.callout_*.jar \
         $IDEMPIERE_HOME/plugins/org.compiere.db.postgresql.provider_*.jar \
         $IDEMPIERE_HOME/plugins/org.apache.ecs_*.jar; do
  [ -f "$j" ] && CP="$CP:$j"
done
if [ -n "${ZWEB:-}" ]; then CP="$CP:$ZWEB"; fi
echo "Using CP jars: $(echo $CP | tr ':' '\n' | wc -l)"
jar tf "$UI" | grep -q 'org/compiere/minigrid/IMiniTable.class' && echo "IMiniTable OK in ui" || echo "IMiniTable MISSING"

find "$SRC" -name '*.java' > "$BUILD/sources.txt"
javac -encoding UTF-8 -source 11 -target 11 -classpath "$CP" -d "$CLASSES" @"$BUILD/sources.txt"
cp "$P/leaveplanning-info.xml" "$CLASSES/"
# Use MANIFEST from plugin
jar cfm "$BUILD/dist/$JAR_NAME" "$P/META-INF/MANIFEST.MF" -C "$CLASSES" .
cp "$BUILD/dist/$JAR_NAME" "$P/release/$JAR_NAME"

# Install single version
sudo rm -f $IDEMPIERE_HOME/plugins/${SYMBOLIC}_*.jar
sudo rm -f $IDEMPIERE_HOME/customization-jar/${SYMBOLIC}_*.jar
sudo cp "$BUILD/dist/$JAR_NAME" "$IDEMPIERE_HOME/plugins/$JAR_NAME"
sudo cp "$BUILD/dist/$JAR_NAME" "$IDEMPIERE_HOME/customization-jar/$JAR_NAME"
sudo chown idempiere:idempiere "$IDEMPIERE_HOME/plugins/$JAR_NAME" "$IDEMPIERE_HOME/customization-jar/$JAR_NAME"

B=$IDEMPIERE_HOME/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info
sudo sed -i "/^${SYMBOLIC},/d" "$B"
echo "${SYMBOLIC},${VERSION},plugins/${JAR_NAME},4,true" | sudo tee -a "$B" >/dev/null

echo "Built and installed $JAR_NAME ($(stat -c%s $IDEMPIERE_HOME/plugins/$JAR_NAME) bytes)"
sudo /etc/init.d/idempiere stop || true
sleep 3
sudo /etc/init.d/idempiere start
for i in $(seq 1 24); do
  CODE=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/webui/ || echo 000)
  echo "attempt $i: $CODE"
  if [ "$CODE" = "200" ]; then exit 0; fi
  sleep 10
done
exit 1
