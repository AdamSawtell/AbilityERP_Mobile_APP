SET search_path TO adempiere;
SELECT t.aberp_timesheetandexpenses_id, t.documentno, t.r_status_id, s.name AS status_name, t.updated
FROM aberp_timesheetandexpenses t
LEFT JOIN r_status s ON s.r_status_id = t.r_status_id
WHERE t.aberp_timesheetandexpenses_id IN (1000095,1000096,1000097)
ORDER BY t.aberp_timesheetandexpenses_id;

SELECT pi.ad_pinstance_id, pi.created, pi.isprocessing, pi.result, pi.errormsg, p.name
FROM ad_pinstance pi
JOIN ad_process p ON p.ad_process_id = pi.ad_process_id
WHERE p.ad_process_uu = '3a3c2c41-995c-41ba-9fde-caeaacee1d75'
ORDER BY pi.created DESC
LIMIT 5;
