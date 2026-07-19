SET search_path TO adempiere;
SELECT aberp_activityauditreview_id, processing, aberp_openactivity, isactive
FROM aberp_activityauditreview;
SELECT column_name, column_default
FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='aberp_activityauditreview'
  AND column_name IN ('processing','aberp_openactivity');
