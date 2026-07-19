SET search_path TO adempiere;
SELECT ad_client_id, name FROM ad_client ORDER BY ad_client_id;
SELECT ad_client_id, COUNT(*) FROM c_contactactivity GROUP BY ad_client_id;
SELECT COUNT(*) FROM c_contactactivity;
