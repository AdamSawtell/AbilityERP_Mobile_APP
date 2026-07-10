#!/bin/bash
set -euo pipefail
PLUGIN=/opt/ability-erp-pwa/idempiere-plugins/com.aberp.rostering.chat
sudo mkdir -p "$PLUGIN/src/com/aberp/rostering/chat/process"
sudo cp /tmp/SendRosteringReply.java "$PLUGIN/src/com/aberp/rostering/chat/process/"
sudo cp /tmp/build-rostering.sh "$PLUGIN/build.sh"
sudo chmod +x "$PLUGIN/build.sh"
cd "$PLUGIN"
sudo bash build.sh
VERSION=7.1.0.202607110830
JAR="com.aberp.rostering.chat_${VERSION}.jar"
ls -la "build/dist/$JAR"
sudo cp "build/dist/$JAR" /opt/idempiere-server/plugins/
sudo cp "build/dist/$JAR" /opt/idempiere-server/customization-jar/
sudo chown idempiere:idempiere "/opt/idempiere-server/plugins/$JAR" "/opt/idempiere-server/customization-jar/$JAR"
BUNDLES=/opt/idempiere-server/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info
sudo sed -i '/^com.aberp.rostering.chat,/d' "$BUNDLES"
echo "com.aberp.rostering.chat,${VERSION},plugins/${JAR},4,true" | sudo tee -a "$BUNDLES"
CHUBOE=/opt/chuboe/idempiere-installation-script/utils
if [ -d "$CHUBOE" ]; then
  cd "$CHUBOE"
  sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep rostering.chat || true
fi
echo BUILD_OK
