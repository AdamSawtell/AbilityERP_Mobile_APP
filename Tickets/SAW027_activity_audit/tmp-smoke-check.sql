SET search_path TO adempiere;

-- Simulate nightly for HCO client by invoking matching via SQL for the smoke activity
-- Full process run is via WebUI; this verifies data path readiness.

SELECT a.c_contactactivity_id, left(a.description,120) AS descr, a.updated
FROM c_contactactivity a
WHERE a.c_contactactivity_id = 1641177;

SELECT t.auditword, t.matchtype, t.risklevel
FROM aberp_activityauditterm t
WHERE t.ad_client_id = 1000003 AND t.isactive='Y'
ORDER BY t.auditword;

-- Count reviews / proc before process
SELECT COUNT(*) AS reviews_before FROM aberp_activityauditreview WHERE ad_client_id=1000003;
SELECT COUNT(*) AS proc_before FROM aberp_activityauditproc WHERE ad_client_id=1000003;
