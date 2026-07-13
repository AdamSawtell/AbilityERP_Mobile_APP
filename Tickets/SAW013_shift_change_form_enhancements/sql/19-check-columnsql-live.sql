SELECT c.columnname, c.columnsql IS NOT NULL AS has_sql, left(c.columnsql,120) AS columnsql,
       c.isupdateable, c.isactive, c.ad_reference_id
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'AbERP_ShiftChange'
  AND c.columnname IN ('R_Status_ID','AbERP_RequestSubmitted','Summary','DocumentNo');

-- physical columns exist?
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name='aberp_shiftchange'
  AND column_name IN ('r_status_id','aberp_requestsubmitted')
ORDER BY 1;

-- triggers
SELECT tgname, tgenabled FROM pg_trigger
WHERE tgrelid = 'aberp_shiftchange'::regclass AND NOT tgisinternal;
