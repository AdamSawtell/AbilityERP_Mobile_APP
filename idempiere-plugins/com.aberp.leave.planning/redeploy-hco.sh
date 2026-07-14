#!/bin/bash
# SAW016 — Full HCO redeploy: ordered SQL + JAR 1402 + WebUI up.
# Run on iDempiere host from this plugin directory.
set -euo pipefail

P="$(cd "$(dirname "$0")" && pwd)"
IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
export PGPASSWORD="${PGPASSWORD:-flamingo}"
PSQL=(psql -h localhost -U adempiere -d idempiere -v ON_ERROR_STOP=1)

echo "=== SAW016 redeploy from $P ==="
test -f "$P/src/com/aberp/leave/planning/info/LeavePlanningInfoWindow.java"
test -f "$P/META-INF/MANIFEST.MF"
test -f "$P/rebuild-hco.sh"

# Normalize CRLF if uploaded from Windows
find "$P" -type f \( -name '*.sh' -o -name '*.sql' -o -name '*.xml' \) -print0 \
  | xargs -0 sed -i 's/\r$//' 2>/dev/null || true

has_info() {
  "${PSQL[@]}" -tAc \
    "SELECT 1 FROM adempiere.ad_infowindow WHERE ad_infowindow_uu='16a016iw-c0d4-4f01-8e15-000000000001'" \
    | grep -q 1
}

apply() {
  local f="$1"
  echo "=== SQL $f ==="
  "${PSQL[@]}" -f "$P/sql/$f"
}

if ! has_info; then
  echo "Info Window missing — first-time AD pack"
  for f in \
    00-preflight.sql \
    01-create-table.sql \
    08-summary-functions.sql \
    02-ad-table-columns.sql \
    03-leave-virtual-columns.sql \
    04-window-tabs-fields.sql \
    09-planning-line.sql \
    10-ad-planning-line.sql \
    05-menu-access.sql \
    06-report.sql \
    07-verify.sql \
    11-info-window.sql \
    12-fix-info-locations.sql \
    13-simplify-service-location.sql
  do
    apply "$f"
  done
else
  echo "Info Window present — incremental only"
fi

# Always re-apply harden / location / non-neg (idempotent)
for f in \
  14-info-readonly.sql \
  15-info-summary-functions.sql \
  16-hide-grid-columns.sql \
  17-risk-sort-order.sql \
  18-support-location-valrule.sql \
  19-fix-service-location-roster.sql \
  20-fix-service-location-parser.sql \
  21-primary-service-location.sql \
  22-primary-location-function.sql \
  23-rename-support-location.sql \
  24-support-location-search-nonneg.sql \
  25-restore-criteria-dropdowns.sql
do
  apply "$f"
done

echo "=== Build + install JAR ==="
bash "$P/rebuild-hco.sh" || true

wait_webui() {
  local i code
  for i in $(seq 1 36); do
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1:8080/webui/ || echo 000)
    echo "  wait $i: $code"
    if [ "$code" = "200" ]; then
      return 0
    fi
    sleep 8
  done
  return 1
}

CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1:8080/webui/ || echo 000)
# Note: Apache proxies :80 → Jetty :8080. Poll Jetty, not Apache alone.
if [ "$CODE" != "200" ]; then
  echo "WebUI HTTP $CODE — force restart (systemctl often says already running with no Java)"
  sudo systemctl stop idempiere || true
  sudo /etc/init.d/idempiere stop || true
  sleep 2
  # Use pattern that cannot match this bash script:
  sudo pkill -9 -f 'org.eclipse.equinox.launcher' || true
  sleep 2
  LOGNAME="redeploy_start_$(date +%Y%m%d%H%M%S).log"
  sudo mkdir -p "$IDEMPIERE_HOME/log"
  sudo chown -R idempiere:idempiere "$IDEMPIERE_HOME/log" || true
  sudo -u idempiere bash -lc "cd $IDEMPIERE_HOME && nohup ./idempiere-server.sh > log/${LOGNAME} 2>&1 &"
  wait_webui || {
    echo "FAILED: WebUI did not return 200 — see $IDEMPIERE_HOME/log/${LOGNAME}"
    exit 1
  }
fi

echo "=== Bundle ==="
grep leave.planning "$IDEMPIERE_HOME/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info" || true
ls -la "$IDEMPIERE_HOME/plugins"/com.aberp.leave.planning_*.jar

echo "=== Column check ==="
"${PSQL[@]}" -c "
SELECT ic.columnname, ic.name, ic.ad_reference_id, left(coalesce(ic.selectclause,''),70) AS sel
FROM adempiere.ad_infocolumn ic
JOIN adempiere.ad_infowindow iw ON iw.ad_infowindow_id=ic.ad_infowindow_id
WHERE iw.ad_infowindow_uu='16a016iw-c0d4-4f01-8e15-000000000001'
  AND ic.columnname IN ('C_BPartner_Location_ID','AbERP_LP_ServiceLocation');
"

echo "SAW016 redeploy complete."
echo "Next: Cache Reset or logout/in as Admin → Leave Planning smoke (see Tickets/SAW016_leave_planning/DEPLOY.md)."
