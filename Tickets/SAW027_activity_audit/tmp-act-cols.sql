SET search_path TO adempiere;
SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='c_contactactivity'
ORDER BY ordinal_position;
SELECT ad_client_id, COUNT(*) FROM c_contactactivity WHERE ad_client_id=1000003 GROUP BY 1;
SELECT auditword FROM aberp_activityauditterm WHERE ad_client_id=1000003 AND isactive='Y' ORDER BY 1;
