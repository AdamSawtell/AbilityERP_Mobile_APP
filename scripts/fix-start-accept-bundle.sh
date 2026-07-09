#!/bin/bash
set -euo pipefail
echo "=== acceptrequest + rosteredshift.process in bundles.info ==="
grep rosteredshift /opt/idempiere-server/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info

echo "=== sample active aberp bundles in bundles.info ==="
grep -E 'rosteredshift|shiftoffer|docstatus|status' /opt/idempiere-server/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info | head -20

echo "=== OSGi status ==="
cd /opt/chuboe/idempiere-installation-script/utils
sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep -iE 'acceptrequest|rosteredshift.process|docstatus|statusline|documentstatus'

echo "=== Start acceptrequest bundle ==="
BUNDLE_ID=$(sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep acceptrequest | awk '{print $1}')
echo "Bundle ID: $BUNDLE_ID"
if [ -n "$BUNDLE_ID" ]; then
  ./logilite_telnet_start.sh "$BUNDLE_ID"
  sleep 3
  sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep -i acceptrequest
fi

BUNDLE_ID2=$(sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep 'rosteredshift.process_7.1.7' | awk '{print $1}')
echo "Official process Bundle ID: $BUNDLE_ID2"
if [ -n "$BUNDLE_ID2" ]; then
  ./logilite_telnet_start.sh "$BUNDLE_ID2"
  sleep 3
  sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep 'rosteredshift.process_7.1.7'
fi
