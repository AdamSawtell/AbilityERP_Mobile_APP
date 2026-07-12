#!/bin/bash
# Build com.aberp.rostering.staffinfo OSGi bundle (Java + SQL AD package).
set -euo pipefail

IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$PLUGIN_DIR/src"
BUILD_DIR="$PLUGIN_DIR/build"
CLASSES_DIR="$BUILD_DIR/classes"
STAGE_DIR="$BUILD_DIR/stage"
VERSION="1.1.0.2026071215"
SYMBOLIC="com.aberp.rostering.staffinfo"
JAR_NAME="${SYMBOLIC}_${VERSION}.jar"

BASE_JAR=$(ls "$IDEMPIERE_HOME"/plugins/org.adempiere.base_*.jar | head -1)
UTILS_JAR=$(ls "$IDEMPIERE_HOME"/plugins/org.adempiere.plugin.utils_*.jar | head -1)
UIZK_JAR=$(ls "$IDEMPIERE_HOME"/plugins/org.adempiere.ui.zk_*.jar | head -1)
ZUL_JAR=$(ls "$IDEMPIERE_HOME"/plugins/zul_*.jar | head -1)
ZK_JAR=$(ls "$IDEMPIERE_HOME"/plugins/zk_*.jar | head -1)
ZCOMMON_JAR=$(ls "$IDEMPIERE_HOME"/plugins/zcommon_*.jar | head -1)

if [ ! -f "$BASE_JAR" ] || [ ! -f "$UTILS_JAR" ] || [ ! -f "$UIZK_JAR" ]; then
  echo "Missing iDempiere base/ui.zk jars under $IDEMPIERE_HOME/plugins"
  exit 1
fi

CLASSPATH="$BASE_JAR:$UTILS_JAR:$UIZK_JAR:$ZUL_JAR:$ZK_JAR:$ZCOMMON_JAR"

rm -rf "$BUILD_DIR"
mkdir -p "$CLASSES_DIR" "$STAGE_DIR/sql" "$STAGE_DIR/META-INF"

find "$SRC_DIR" -name '*.java' > "$BUILD_DIR/sources.txt"
javac -encoding UTF-8 -source 11 -target 11 -classpath "$CLASSPATH" -d "$CLASSES_DIR" @"$BUILD_DIR/sources.txt"

cp "$PLUGIN_DIR/staffinfo-info.xml" "$CLASSES_DIR/"
cp "$PLUGIN_DIR/staffinfo-callout.xml" "$CLASSES_DIR/"
cp "$PLUGIN_DIR/META-INF/MANIFEST.MF" "$STAGE_DIR/META-INF/MANIFEST.MF"
cp "$PLUGIN_DIR"/sql/*.sql "$STAGE_DIR/sql/"
cp "$PLUGIN_DIR/README.md" "$STAGE_DIR/" 2>/dev/null || true

mkdir -p "$BUILD_DIR/dist" "$PLUGIN_DIR/release"
jar cfm "$BUILD_DIR/dist/$JAR_NAME" "$PLUGIN_DIR/META-INF/MANIFEST.MF" \
  -C "$CLASSES_DIR" . \
  -C "$STAGE_DIR" sql \
  -C "$STAGE_DIR" README.md

cp "$BUILD_DIR/dist/$JAR_NAME" "$PLUGIN_DIR/release/$JAR_NAME"
echo "Built $BUILD_DIR/dist/$JAR_NAME"
jar tf "$BUILD_DIR/dist/$JAR_NAME" | head -40
