#!/bin/bash
set -euo pipefail

# Sync ID sequences
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f /home/ubuntu/fix-chat-sequences.sql

# Deploy API fixes
cd /opt/ability-erp-pwa/api
npm run build
pm2 reload ability-erp-api

# Rebuild Close Chat plugin
cd /opt/ability-erp-pwa/idempiere-plugins/com.aberp.rostering.chat
sudo bash build.sh
JAR=com.aberp.rostering.chat_7.1.0.202607110700.jar
sudo cp "build/dist/$JAR" /opt/idempiere-server/plugins/
sudo cp "build/dist/$JAR" /opt/idempiere-server/customization-jar/
sudo chown idempiere:idempiere "/opt/idempiere-server/plugins/$JAR"
# Point bundles.info at new version
BUNDLES_INFO=/opt/idempiere-server/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info
sudo sed -i '/^com.aberp.rostering.chat,/d' "$BUNDLES_INFO"
echo "com.aberp.rostering.chat,7.1.0.202607110700,plugins/${JAR},4,true" | sudo tee -a "$BUNDLES_INFO" >/dev/null
sudo systemctl restart idempiere

for i in $(seq 1 12); do
  sleep 10
  CODE=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/webui/ || echo 000)
  echo "webui $i $CODE"
  if [ "$CODE" = "200" ]; then break; fi
done

node /home/ubuntu/test-new-chat-after-close.js
