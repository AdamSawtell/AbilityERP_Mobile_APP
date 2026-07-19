SET search_path TO adempiere;
SELECT pil.p_msg, pil.created
FROM ad_pinstance_log pil
JOIN ad_pinstance pi ON pi.ad_pinstance_id = pil.ad_pinstance_id
JOIN ad_process p ON p.ad_process_id = pi.ad_process_id
WHERE p.value = 'AbERP_ActivityAudit_Nightly'
ORDER BY pil.created DESC
LIMIT 20;

SELECT left(errormsg,500), result, created
FROM ad_pinstance
WHERE ad_process_id = (SELECT ad_process_id FROM ad_process WHERE value='AbERP_ActivityAudit_Nightly')
ORDER BY created DESC LIMIT 1;
