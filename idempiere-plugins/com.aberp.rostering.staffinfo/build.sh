#!/bin/bash
# Build distribution JAR for AbERP Rostering Staff Info (AD SQL package).
# This JAR is the portable install artifact for other iDempiere instances.
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="1.0.0.2026071123"
SYMBOLIC="com.aberp.rostering.staffinfo"
JAR_NAME="${SYMBOLIC}_${VERSION}.jar"
DIST_DIR="$PLUGIN_DIR/build/dist"
STAGE_DIR="$PLUGIN_DIR/build/stage"

rm -rf "$PLUGIN_DIR/build"
mkdir -p "$STAGE_DIR/sql" "$STAGE_DIR/META-INF" "$DIST_DIR"

cp "$PLUGIN_DIR/META-INF/MANIFEST.MF" "$STAGE_DIR/META-INF/MANIFEST.MF"
cp "$PLUGIN_DIR"/sql/*.sql "$STAGE_DIR/sql/"
cp "$PLUGIN_DIR/README.md" "$STAGE_DIR/"

jar cfm "$DIST_DIR/$JAR_NAME" "$PLUGIN_DIR/META-INF/MANIFEST.MF" \
  -C "$STAGE_DIR" sql \
  -C "$STAGE_DIR" README.md

mkdir -p "$PLUGIN_DIR/release"
cp "$DIST_DIR/$JAR_NAME" "$PLUGIN_DIR/release/$JAR_NAME"

echo "Built $DIST_DIR/$JAR_NAME"
echo "Release copy: $PLUGIN_DIR/release/$JAR_NAME"
jar tf "$DIST_DIR/$JAR_NAME"
