#!/bin/bash
set -euo pipefail

PLUGIN=/opt/ability-erp-pwa/idempiere-plugins/com.aberp.rostering.chat
VERSION=7.1.0.202607110720
JAR=com.aberp.rostering.chat_${VERSION}.jar

sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f /home/ubuntu/09-fix-updates-send.sql

cd "$PLUGIN"
sudo bash build.sh
sudo cp "build/dist/$JAR" /opt/idempiere-server/plugins/
sudo cp "build/dist/$JAR" /opt/idempiere-server/customization-jar/
sudo chown idempiere:idempiere "/opt/idempiere-server/plugins/$JAR"
BUNDLES_INFO=/opt/idempiere-server/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info
sudo sed -i '/^com.aberp.rostering.chat,/d' "$BUNDLES_INFO"
echo "com.aberp.rostering.chat,${VERSION},plugins/${JAR},4,true" | sudo tee -a "$BUNDLES_INFO" >/dev/null
sudo systemctl restart idempiere

for i in $(seq 1 12); do
  sleep 10
  CODE=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/webui/ || echo 000)
  echo "webui $i $CODE"
  if [ "$CODE" = "200" ]; then break; fi
done

node /home/ubuntu/test-chat-e2e-full.js
