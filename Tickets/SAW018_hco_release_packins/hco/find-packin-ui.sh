#!/bin/bash
PGPASSWORD=flamingo psql -h localhost -U adempiere -d idempiere <<'SQL'
SET search_path TO adempiere;
SELECT w.ad_window_id, w.name, w.ad_window_uu, t.name AS tab
FROM ad_window w
JOIN ad_tab t ON t.ad_window_id=w.ad_window_id
WHERE w.name ILIKE '%pack%in%' OR w.name ILIKE '%2pack%' OR w.name ILIKE '%package%imp%'
ORDER BY w.name, t.seqno;
SELECT m.name, m.action, m.ad_window_id, m.ad_process_id
FROM ad_menu m WHERE m.name ILIKE '%pack%in%' OR m.name ILIKE '%2pack%';
-- where employee.infopanel 2pack lives inside plugins
SQL
echo "=== plugin 2packs ==="
sudo find /opt/idempiere-server/plugins -iname "*2pack*" 2>/dev/null | head -20
sudo find /opt/idempiere-server/plugins -iname "*employee*info*" 2>/dev/null | head -20
ls -la /tmp/hco_*.zip
# ensure a stable web-accessible upload path for PackIn if needed
sudo mkdir -p /opt/idempiere-server/data/tmp/saw018
sudo cp /tmp/hco_*.zip /opt/idempiere-server/data/tmp/saw018/
sudo chown -R idempiere:idempiere /opt/idempiere-server/data/tmp/saw018
ls -la /opt/idempiere-server/data/tmp/saw018/