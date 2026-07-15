#!/bin/bash
set -euo pipefail
cd /tmp/saw023-sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f 04-dashboard-view.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f 08-seed-dummy-snapshot.sql
sudo -u postgres psql -d idempiere -c "SET search_path TO adempiere; SELECT ad_client_id, overallscore, totalitems, employeetotal FROM aberp_compliancedashboard ORDER BY 1;"
