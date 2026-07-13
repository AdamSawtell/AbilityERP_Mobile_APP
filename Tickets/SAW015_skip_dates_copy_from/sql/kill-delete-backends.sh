#!/bin/bash
set -x
echo "Before:"
ps aux | grep 'postgres: 12/main: adempiere idempiere' | grep -v grep | wc -l
# Kill long-running DELETE worker backends (SAW012 purge saturating connections)
pids=$(ps aux | grep 'postgres: 12/main: adempiere idempiere' | grep -v grep | grep DELETE | awk '{print $2}')
echo "DELETE pids:"
echo "$pids"
for p in $pids; do
  echo "kill $p"
  sudo kill "$p" || true
done
sleep 3
echo "After:"
ps aux | grep 'postgres: 12/main: adempiere idempiere' | grep -v grep | wc -l
sudo -u postgres psql -d idempiere -c "SELECT count(*) FROM pg_stat_activity WHERE datname='idempiere';"
sudo -u postgres psql -d idempiere -c "SET search_path TO adempiere; SELECT c.columnname, c.istoolbarbutton, p.value FROM ad_column c JOIN ad_table t ON t.ad_table_id=c.ad_table_id LEFT JOIN ad_process p ON p.ad_process_id=c.ad_process_id WHERE t.tablename='AbERP_Skip_Dates' AND c.columnname='AbERP_CopyDatesFrom';"
sudo -u postgres psql -d idempiere -c "SET search_path TO adempiere; SELECT f.name, f.isdisplayed, f.istoolbarbutton, f.isactive FROM ad_field f WHERE f.name='Copy Dates From';"
