SET search_path TO adempiere;
-- Avoid full ad_pinstance scans: filter by process_id first via subquery
SELECT pi.ad_pinstance_id, pi.created, pi.result,
       left(coalesce(pi.errormsg,''),160) AS err, pi.record_id
FROM ad_pinstance pi
WHERE pi.ad_process_id = (SELECT ad_process_id FROM ad_process WHERE value = 'Generate Bookings' LIMIT 1)
ORDER BY pi.ad_pinstance_id DESC
LIMIT 25;
