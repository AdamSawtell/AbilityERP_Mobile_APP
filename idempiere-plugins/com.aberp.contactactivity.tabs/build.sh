#!/bin/bash
# Build com.aberp.contactactivity.tabs OSGi bundle (AD-only marker bundle).
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PLUGIN_DIR/build"
CLASSES_DIR="$BUILD_DIR/classes"
VERSION="7.1.0.202607092300"
JAR_NAME="com.aberp.contactactivity.tabs_${VERSION}.jar"

rm -rf "$BUILD_DIR"
mkdir -p "$CLASSES_DIR"
# Marker resource so the JAR is non-empty
echo "AbERP Contact Activity Tabs plugin — AD SQL applied by deploy.sh" > "$CLASSES_DIR/plugin.info"

mkdir -p "$BUILD_DIR/dist"
jar cfm "$BUILD_DIR/dist/$JAR_NAME" "$PLUGIN_DIR/META-INF/MANIFEST.MF" -C "$CLASSES_DIR" .

echo "Built $BUILD_DIR/dist/$JAR_NAME"
