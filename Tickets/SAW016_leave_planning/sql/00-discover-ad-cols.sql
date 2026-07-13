SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='ad_tab'
  AND column_name ILIKE '%refresh%' OR (table_schema='adempiere' AND table_name='ad_tab' AND column_name IN ('isrefreshallonactivate','parent_column_id','ad_column_id'))
ORDER BY 1;

SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='ad_ref_table'
ORDER BY ordinal_position;

SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='ad_column'
  AND column_name IN ('islazyloading','columnsql_basedon','isformatted','istoolbarbutton')
ORDER BY 1;
