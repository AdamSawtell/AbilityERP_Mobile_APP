SET search_path TO adempiere;
-- Scheduler must run on HCO client (smoke host)
UPDATE ad_scheduler SET
  ad_client_id = 1000003,
  datenextrun = NOW() - INTERVAL '1 minute',
  updated = NOW()
WHERE name = 'Activity Audit Nightly';
SELECT name, ad_client_id, datenextrun, isactive FROM ad_scheduler WHERE name = 'Activity Audit Nightly';
