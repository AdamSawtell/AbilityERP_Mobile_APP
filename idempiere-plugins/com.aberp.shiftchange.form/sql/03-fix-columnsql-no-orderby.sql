SET search_path TO adempiere;

-- SAW013: ensure no ColumnSQL remains (physical sync approach)
UPDATE ad_column c
SET columnsql = NULL,
    isupdateable = 'N',
    updated = NOW(),
    updatedby = 100
FROM ad_table t
WHERE c.ad_table_id = t.ad_table_id
  AND t.tablename = 'AbERP_ShiftChange'
  AND c.columnname IN ('R_Status_ID', 'AbERP_RequestSubmitted');

SELECT columnname, columnsql IS NULL AS no_sql, isupdateable
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'AbERP_ShiftChange'
  AND c.columnname IN ('R_Status_ID', 'AbERP_RequestSubmitted');
