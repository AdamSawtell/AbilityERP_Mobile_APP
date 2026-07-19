SET search_path TO adempiere;
UPDATE ad_scheduler SET datenextrun = NOW() - INTERVAL '1 minute', updated = NOW()
WHERE name = 'Activity Audit Nightly';
SELECT name, datenextrun, isactive, ad_client_id FROM ad_scheduler WHERE name = 'Activity Audit Nightly';
