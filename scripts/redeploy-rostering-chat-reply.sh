#!/bin/bash
set -euo pipefail
cd /opt/ability-erp-pwa/idempiere-plugins/com.aberp.rostering.chat
sudo bash build.sh
sudo cp build/dist/com.aberp.rostering.chat_7.1.0.202607110630.jar /opt/idempiere-server/plugins/
sudo cp build/dist/com.aberp.rostering.chat_7.1.0.202607110630.jar /opt/idempiere-server/customization-jar/
sudo chown idempiere:idempiere /opt/idempiere-server/plugins/com.aberp.rostering.chat_7.1.0.202607110630.jar
sudo systemctl restart idempiere
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f /home/ubuntu/seed-officer-reply-test.sql
for i in $(seq 1 12); do
  sleep 15
  CODE=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/webui/ || echo 000)
  echo "attempt $i $CODE"
  if [ "$CODE" = "200" ]; then
    break
  fi
done
node /home/ubuntu/test-officer-reply-visible.js
