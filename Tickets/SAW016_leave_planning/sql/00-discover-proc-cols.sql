SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='ad_process_para'
ORDER BY ordinal_position;
SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='ad_reportview'
ORDER BY ordinal_position;
SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='ad_process'
  AND column_name IN ('allowmultipleexecution','isprinterpreview','ad_ctxhelp_id','executiontype');
