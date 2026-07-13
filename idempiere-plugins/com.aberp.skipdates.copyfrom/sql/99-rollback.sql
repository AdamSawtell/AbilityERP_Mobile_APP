-- SAW015 rollback — remove Copy Dates From AD objects (keeps business date data).
SET search_path TO adempiere;

DELETE FROM ad_process_access
WHERE ad_process_id IN (
  SELECT ad_process_id FROM ad_process
  WHERE value = 'AbERP_SkipDates_CopyDatesFrom'
     OR ad_process_uu = '15a01501-c0d4-4f01-8e15-000000000001'
);

DELETE FROM ad_field
WHERE ad_field_uu = '15a01504-c0d4-4f01-8e15-000000000004'
   OR ad_column_id IN (
        SELECT c.ad_column_id FROM ad_column c
        JOIN ad_table t ON t.ad_table_id = c.ad_table_id
        WHERE t.tablename = 'AbERP_Skip_Dates' AND c.columnname = 'AbERP_CopyDatesFrom'
      );

DELETE FROM ad_column
WHERE ad_column_uu = '15a01503-c0d4-4f01-8e15-000000000003'
   OR (columnname = 'AbERP_CopyDatesFrom'
       AND ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_Skip_Dates' LIMIT 1));

DELETE FROM ad_process_para
WHERE ad_process_para_uu = '15a01505-c0d4-4f01-8e15-000000000005'
   OR ad_process_id IN (
        SELECT ad_process_id FROM ad_process
        WHERE value = 'AbERP_SkipDates_CopyDatesFrom'
           OR ad_process_uu = '15a01501-c0d4-4f01-8e15-000000000001'
      );

DELETE FROM ad_process
WHERE value = 'AbERP_SkipDates_CopyDatesFrom'
   OR ad_process_uu = '15a01501-c0d4-4f01-8e15-000000000001';

DELETE FROM ad_element
WHERE columnname = 'AbERP_CopyDatesFrom'
   OR ad_element_uu = '15a01502-c0d4-4f01-8e15-000000000002';

DELETE FROM ad_val_rule
WHERE ad_val_rule_uu = '15a01506-c0d4-4f01-8e15-000000000006'
   OR name = 'AbERP Skip Dates - Exclude Current';

-- Optional: DROP COLUMN aberp_copydatesfrom — left in place (harmless char(1)).
