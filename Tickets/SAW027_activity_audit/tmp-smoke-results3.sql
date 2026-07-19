SET search_path TO adempiere;
SELECT COUNT(*) AS reviews FROM aberp_activityauditreview WHERE ad_client_id=1000003;
SELECT COUNT(*) AS proc FROM aberp_activityauditproc WHERE ad_client_id=1000003;
SELECT COUNT(*) AS runs FROM aberp_activityauditrunt WHERE ad_client_id=1000003;
SELECT c_contactactivity_id, left(matchedterms,80) AS matchedterms, reviewstatus, isreviewed
FROM aberp_activityauditreview
WHERE ad_client_id=1000003
ORDER BY created DESC LIMIT 10;
SELECT summarymsg, activitiesidentified, activitiesprocessed, reviewscreated, errorcount
FROM aberp_activityauditrunt WHERE ad_client_id=1000003 ORDER BY starttime DESC LIMIT 3;
SELECT left(errormsg,300) AS err, result FROM ad_pinstance
WHERE ad_process_id = (SELECT ad_process_id FROM ad_process WHERE value='AbERP_ActivityAudit_Nightly')
ORDER BY created DESC LIMIT 3;
