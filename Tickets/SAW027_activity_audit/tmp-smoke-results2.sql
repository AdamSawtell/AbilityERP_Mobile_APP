SET search_path TO adempiere;
SELECT COUNT(*) AS reviews FROM aberp_activityauditreview WHERE ad_client_id=1000003;
SELECT COUNT(*) AS proc FROM aberp_activityauditproc WHERE ad_client_id=1000003;
SELECT COUNT(*) AS runs FROM aberp_activityauditrunt WHERE ad_client_id=1000003;
SELECT c_contactactivity_id, matchedterms, reviewstatus, isreviewed
FROM aberp_activityauditreview
WHERE ad_client_id=1000003
ORDER BY created DESC LIMIT 5;
SELECT summarymsg FROM aberp_activityauditrunt WHERE ad_client_id=1000003 ORDER BY starttime DESC LIMIT 3;
SELECT pi.ad_pinstance_id, pi.result, left(pi.errormsg,200) AS errormsg, pi.iserror, pi.created
FROM ad_pinstance pi
JOIN ad_process p ON p.ad_process_id = pi.ad_process_id
WHERE p.value = 'AbERP_ActivityAudit_Nightly'
ORDER BY pi.created DESC
LIMIT 5;
