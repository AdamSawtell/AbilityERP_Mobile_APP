#!/bin/bash
echo "=== server status ==="
systemctl is-active idempiere || true
sudo systemctl is-active idempiere || true
pgrep -af "idempiere|equinox" | head -5 || true
curl -s -o /dev/null -w "webui:%{http_code}\n" http://127.0.0.1/webui/ || true
echo "=== employee.infopanel 2packs on disk ==="
sudo find /opt/idempiere-server -iname "*employee*infopanel*" 2>/dev/null | head -30
sudo find /opt/idempiere-server/migration -iname "*.zip" 2>/dev/null | head -40
echo "=== AD_Package_ImpDetail for latest fails ==="
PGPASSWORD=flamingo psql -h localhost -U adempiere -d idempiere <<'SQL'
SET search_path TO adempiere;
SELECT ad_package_imp_id, name, pk_status, processed, created
FROM ad_package_imp WHERE name ILIKE '%employee.infopanel%' ORDER BY created DESC LIMIT 5;
SELECT COUNT(*) AS fail_count FROM ad_package_imp WHERE name ILIKE '%employee.infopanel%' AND pk_status ILIKE '%Fail%';
SQL
echo "=== Pack In process ==="
PGPASSWORD=flamingo psql -h localhost -U adempiere -d idempiere <<'SQL'
SET search_path TO adempiere;
SELECT ad_process_id, value, name, classname FROM ad_process WHERE name ILIKE '%pack%in%' OR value ILIKE '%pack%in%' OR classname ILIKE '%PackIn%';
SQL