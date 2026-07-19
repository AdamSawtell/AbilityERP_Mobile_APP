SET search_path TO adempiere;
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'adempiere' AND table_name = 'c_contactactivity'
ORDER BY ordinal_position;
