#!/bin/bash
# Reinstall missing customization-jar plugins via logilite deploy (fixes status indicators etc).
set -euo pipefail
DEPLOY_JAR="/opt/idempiere-server/deploy-jar"
CUSTOM="/opt/idempiere-server/customization-jar"
CHUBOE_UTILS="/opt/chuboe/idempiere-installation-script/utils"

sudo mkdir -p "$DEPLOY_JAR"
sudo rm -f "$DEPLOY_JAR"/*.jar

# Copy only bundles not currently ACTIVE in OSGi
cd "$CHUBOE_UTILS"
for j in "$CUSTOM"/*.jar; do
  base=$(basename "$j")
  sym=$(echo "$base" | sed 's/_[0-9].*//')
  state=$(sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep "$sym" | awk '{print $2}' | head -1)
  if [ "$state" != "ACTIVE" ]; then
    sudo cp "$j" "$DEPLOY_JAR/"
  fi
done

count=$(ls "$DEPLOY_JAR"/*.jar 2>/dev/null | wc -l)
echo "Deploying $count jars from customization-jar..."
sudo chown -R idempiere:idempiere "$DEPLOY_JAR"

if [ "$count" -gt 0 ]; then
  cd "$CHUBOE_UTILS"
  # -R = install, start, no restart; -m = include already deployed; -D = keep source jars
  sudo bash logilite_deploy_plugins.sh -R -m -D -d 2
fi

echo "DONE"
