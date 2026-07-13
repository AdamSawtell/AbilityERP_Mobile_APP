#!/bin/bash
L=$(ls -t /opt/idempiere-server/log/*.log | head -1)
echo "LOG=$L"
sudo grep -n 'NoClassDefFoundError\|StaffRosteringInfo\|leave.planning\|fireMenuSelected' "$L" | tail -40
echo '---- STACK ----'
LINE=$(sudo grep -n 'NoClassDefFoundError: org/zkoss/util/media/Media' "$L" | tail -1 | cut -d: -f1)
if [ -n "$LINE" ]; then
  START=$((LINE-5))
  END=$((LINE+40))
  sudo sed -n "${START},${END}p" "$L"
fi
echo '---- leave jar ----'
ls -la /opt/idempiere-server/plugins/com.aberp.leave.planning_*.jar
grep leave.planning /opt/idempiere-server/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info
