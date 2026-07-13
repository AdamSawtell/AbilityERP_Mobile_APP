SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='ad_column'
  AND column_name IN ('isautocomplete','isallowcopy','seqnoselection','issyncdatabase','isformatted');
SELECT ad_reference_id, attname, format_type(atttypid,atttypmod)
FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='adempiere' AND c.relname='ad_column' AND attname='istoolbarbutton';
