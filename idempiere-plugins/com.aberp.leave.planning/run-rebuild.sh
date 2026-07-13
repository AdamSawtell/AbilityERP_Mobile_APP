#!/bin/bash
set -e
P=/opt/idempiere-server/AbERP/com.aberp.leave.planning
cp /home/ubuntu/LeavePlanningInfoWindow.java "$P/src/com/aberp/leave/planning/info/"
cp /home/ubuntu/MANIFEST.MF "$P/META-INF/"
# CRLF strip rebuild script
sed -i 's/\r$//' /home/ubuntu/rebuild-hco.sh
chmod +x /home/ubuntu/rebuild-hco.sh
bash /home/ubuntu/rebuild-hco.sh
