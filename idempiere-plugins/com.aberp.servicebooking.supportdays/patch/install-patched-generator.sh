#!/bin/bash
# SAW031: install bytecode-patched servicebooking.generator (skip EEEE overwrite).
set -euo pipefail
IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NEWVER="7.1.12.2026072203"
NEWJAR="com.aberp.servicebooking.generator_${NEWVER}-saw031.jar"
BINFO="${IDEMPIERE_HOME}/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info"

python3 "$SCRIPT_DIR/patch-eeee-beforesave.py"

# Remove prior broken SAW031 generator jars from plugins/
sudo rm -f "${IDEMPIERE_HOME}/plugins"/com.aberp.servicebooking.generator_*-saw031.jar \
           "${IDEMPIERE_HOME}/customization-jar"/com.aberp.servicebooking.generator_*-saw031.jar || true

sudo cp "/tmp/com.aberp.servicebooking.generator_${NEWVER}-saw031.jar" "${IDEMPIERE_HOME}/plugins/${NEWJAR}"
sudo cp "/tmp/com.aberp.servicebooking.generator_${NEWVER}-saw031.jar" "${IDEMPIERE_HOME}/customization-jar/${NEWJAR}"
sudo chown idempiere:idempiere "${IDEMPIERE_HOME}/plugins/${NEWJAR}" "${IDEMPIERE_HOME}/customization-jar/${NEWJAR}"

sudo sed -i "/^com.aberp.servicebooking.generator,/d" "$BINFO"
echo "com.aberp.servicebooking.generator,${NEWVER},plugins/${NEWJAR},4,true" | sudo tee -a "$BINFO" >/dev/null

echo "bundles.info generator line:"
grep '^com.aberp.servicebooking.generator,' "$BINFO"

sudo /etc/init.d/idempiere stop || true
sleep 3
sudo /etc/init.d/idempiere start

for i in $(seq 1 30); do
  sleep 10
  CODE=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/webui/ || echo 000)
  echo "  attempt $i: HTTP $CODE"
  if [ "$CODE" = "200" ]; then
    break
  fi
done
echo "Patched generator installed."
