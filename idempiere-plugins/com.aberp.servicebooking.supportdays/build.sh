#!/bin/bash
# Build com.aberp.servicebooking.supportdays OSGi bundle (SAW031 model overlay).
set -euo pipefail

IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$PLUGIN_DIR/src"
BUILD_DIR="$PLUGIN_DIR/build"
CLASSES_DIR="$BUILD_DIR/classes"
VERSION="7.1.0.2026072205"
JAR_NAME="com.aberp.servicebooking.supportdays_${VERSION}.jar"

BASE_JAR=$(ls "$IDEMPIERE_HOME"/plugins/org.adempiere.base_*.jar | head -1)
UTILS_JAR=$(ls "$IDEMPIERE_HOME"/plugins/org.adempiere.plugin.utils_*.jar | head -1)
GEN_JAR=$(ls "$IDEMPIERE_HOME"/plugins/com.aberp.servicebooking.generator_*.jar | head -1)

if [ ! -f "$BASE_JAR" ] || [ ! -f "$UTILS_JAR" ] || [ ! -f "$GEN_JAR" ]; then
  echo "Missing required jars under $IDEMPIERE_HOME/plugins"
  echo "  base=$BASE_JAR utils=$UTILS_JAR generator=$GEN_JAR"
  exit 1
fi

CLASSPATH="$BASE_JAR:$UTILS_JAR:$GEN_JAR"

rm -rf "$BUILD_DIR"
mkdir -p "$CLASSES_DIR"

find "$SRC_DIR" -name '*.java' > "$BUILD_DIR/sources.txt"
javac -encoding UTF-8 -source 11 -target 11 -classpath "$CLASSPATH" -d "$CLASSES_DIR" @"$BUILD_DIR/sources.txt"

cp "$PLUGIN_DIR/support-days-model.xml" "$CLASSES_DIR/"
cp "$PLUGIN_DIR/support-days-callout.xml" "$CLASSES_DIR/"

mkdir -p "$BUILD_DIR/dist"
jar cfm "$BUILD_DIR/dist/$JAR_NAME" "$PLUGIN_DIR/META-INF/MANIFEST.MF" -C "$CLASSES_DIR" .

echo "Built $BUILD_DIR/dist/$JAR_NAME"
