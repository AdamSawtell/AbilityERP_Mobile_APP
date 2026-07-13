SELECT c.columnname, c.isupdateable, c.isalwaysupdateable, c.columnsql, c.ad_reference_id,
       c.fieldlength, c.ismandatory
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'AbERP_ShiftChange'
  AND c.columnname IN ('Summary','R_Status_ID','AbERP_RequestSubmitted','R_RequestType_ID','DocumentNo');

-- any model validators on this table?
SELECT * FROM (
  SELECT m.classname, m.modelvalidationclass, m.entitytype, m.isactive
  FROM ad_modelvalidator m
  WHERE m.isactive='Y'
) x LIMIT 0;

SELECT classname, modelvalidationclass, entitytype, isactive
FROM ad_modelvalidator
WHERE isactive='Y'
  AND (classname ILIKE '%shift%' OR modelvalidationclass ILIKE '%shift%' OR classname ILIKE '%request%' OR modelvalidationclass ILIKE '%aberp%')
ORDER BY 1;
