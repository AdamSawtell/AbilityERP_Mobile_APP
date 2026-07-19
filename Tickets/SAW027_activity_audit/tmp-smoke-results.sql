SET search_path TO adempiere;
SELECT COUNT(*) AS reviews FROM aberp_activityauditreview WHERE ad_client_id=1000003;
SELECT COUNT(*) AS proc FROM aberp_activityauditproc WHERE ad_client_id=1000003;
SELECT COUNT(*) AS runs FROM aberp_activityauditrunt WHERE ad_client_id=1000003;
SELECT c_contactactivity_id, matchedterms, reviewstatus, isreviewed
FROM aberp_activityauditreview
WHERE ad_client_id=1000003
ORDER BY created DESC LIMIT 5;
SELECT summarymsg FROM aberp_activityauditrunt WHERE ad_client_id=1000003 ORDER BY starttime DESC LIMIT 3;
SELECT name, datelastrun, datenextrun FROM ad_scheduler WHERE name='Activity Audit Nightly';
