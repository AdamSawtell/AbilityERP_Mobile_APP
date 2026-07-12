SET search_path TO adempiere;
SELECT column_name, character_maximum_length
FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='c_orderline'
  AND column_name IN ('aberp_support_start_day','aberp_support_end_day');
