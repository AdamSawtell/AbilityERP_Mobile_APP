#!/bin/bash
# Fix bundles.info autostart for acceptrequest and start bundle if server running.
set -euo pipefail
BUNDLES_INFO="/opt/idempiere-server/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info"
CHUBOE_UTILS="/opt/chuboe/idempiere-installation-script/utils"

sudo sed -i 's/^com.aberp.rosteredshift.acceptrequest,\(.*\),4,false/com.aberp.rosteredshift.acceptrequest,\1,4,true/' "$BUNDLES_INFO"
grep acceptrequest "$BUNDLES_INFO"

if systemctl is-active --quiet idempiere; then
  cd "$CHUBOE_UTILS"
  BUNDLE_ID=$(sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep acceptrequest | awk '{print $1}')
  STATE=$(sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep acceptrequest | awk '{print $2}')
  echo "acceptrequest bundle $BUNDLE_ID state $STATE"
  if [ "$STATE" != "ACTIVE" ] && [ -n "$BUNDLE_ID" ]; then
    ./logilite_telnet_start.sh "$BUNDLE_ID"
    sleep 2
    sudo -u idempiere ./chuboe_osgi_ss.sh 2>/dev/null | grep acceptrequest
  fi
fi
