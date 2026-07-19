SET search_path TO adempiere;
SELECT COUNT(*) AS reviews FROM aberp_activityauditreview WHERE ad_client_id=1000003;
SELECT COUNT(*) AS proc FROM aberp_activityauditproc WHERE ad_client_id=1000003;
SELECT c_contactactivity_id, matchedterms, reviewstatus FROM aberp_activityauditreview WHERE ad_client_id=1000003 ORDER BY created DESC LIMIT 5;
SELECT summarymsg, reviewscreated, errorcount FROM aberp_activityauditrunt WHERE ad_client_id=1000003 ORDER BY starttime DESC LIMIT 2;
SELECT p_msg FROM ad_pinstance_log WHERE ad_pinstance_id=(
  SELECT ad_pinstance_id FROM ad_pinstance WHERE ad_process_id=(SELECT ad_process_id FROM ad_process WHERE value='AbERP_ActivityAudit_Nightly') ORDER BY created DESC LIMIT 1
) ORDER BY log_id;
