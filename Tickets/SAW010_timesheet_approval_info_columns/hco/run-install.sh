#!/bin/bash
set -euo pipefail
export PGPASSWORD=flamingo
cd /tmp/saw010
for f in 00-preflight-uuids.sql 01-update-infocolumns.sql 02-verify.sql 03-functional-check.sql; do
  echo "=== $f ==="
  psql -h localhost -U adempiere -d idempiere -v ON_ERROR_STOP=1 -f "$f"
done
echo "=== Admin IW access ==="
psql -h localhost -U adempiere -d idempiere -v ON_ERROR_STOP=1 <<'SQL'
SET search_path TO adempiere;
DO $$
DECLARE
  v_iw NUMERIC;
  r RECORD;
BEGIN
  SELECT ad_infowindow_id INTO v_iw FROM ad_infowindow
  WHERE ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4';
  FOR r IN SELECT ad_role_id, name FROM ad_role WHERE isactive='Y' AND name IN ('Admin','AbilityERP Admin')
  LOOP
    IF NOT EXISTS (SELECT 1 FROM ad_infowindow_access WHERE ad_role_id=r.ad_role_id AND ad_infowindow_id=v_iw) THEN
      INSERT INTO ad_infowindow_access (ad_infowindow_id, ad_role_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby)
      VALUES (v_iw, r.ad_role_id, 0, 0, 'Y', NOW(), 100, NOW(), 100);
      RAISE NOTICE 'Granted IW access to %', r.name;
    ELSE
      UPDATE ad_infowindow_access SET isactive='Y', updated=NOW(), updatedby=100
      WHERE ad_role_id=r.ad_role_id AND ad_infowindow_id=v_iw;
    END IF;
  END LOOP;
END $$;
SELECT r.name, ia.isactive
FROM ad_infowindow_access ia
JOIN ad_role r ON r.ad_role_id=ia.ad_role_id
JOIN ad_infowindow iw ON iw.ad_infowindow_id=ia.ad_infowindow_id
WHERE iw.ad_infowindow_uu='40d6a2d7-3bbc-431e-940c-ce75829a68e4'
  AND r.name IN ('Admin','AbilityERP Admin')
ORDER BY 1;
SQL
echo DONE
