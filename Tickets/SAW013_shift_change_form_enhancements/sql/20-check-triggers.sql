SELECT tgname, rel.relname AS table_name, tgenabled
FROM pg_trigger t
JOIN pg_class rel ON rel.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = rel.relnamespace
WHERE n.nspname = 'adempiere'
  AND tgname ILIKE '%shiftchange%'
  AND NOT tgisinternal;

SELECT proname FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname='adempiere' AND proname ILIKE '%shiftchange%';
