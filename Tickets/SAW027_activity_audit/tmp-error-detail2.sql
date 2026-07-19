SET search_path TO adempiere;
SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='ad_pinstance_log'
ORDER BY ordinal_position;

SELECT * FROM ad_pinstance_log
WHERE ad_pinstance_id = (
  SELECT ad_pinstance_id FROM ad_pinstance
  WHERE ad_process_id = (SELECT ad_process_id FROM ad_process WHERE value='AbERP_ActivityAudit_Nightly')
  ORDER BY created DESC LIMIT 1
)
ORDER BY log_id;
