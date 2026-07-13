-- SAW015: show Copy Dates From as a window button (B), same visibility pattern as Accept Shift.
SET search_path TO adempiere;

UPDATE ad_column c
SET istoolbarbutton = 'B',
    updated = NOW(),
    updatedby = 100
FROM ad_table t
WHERE c.ad_table_id = t.ad_table_id
  AND t.tablename = 'AbERP_Skip_Dates'
  AND c.columnname = 'AbERP_CopyDatesFrom';

UPDATE ad_field f
SET istoolbarbutton = 'B',
    isdisplayed = 'Y',
    isdisplayedgrid = 'N',
    updated = NOW(),
    updatedby = 100
WHERE f.name = 'Copy Dates From'
   OR f.ad_field_uu = '15a01504-c0d4-4f01-8e15-000000000004';

SELECT c.istoolbarbutton AS col_tb, f.istoolbarbutton AS field_tb, f.isdisplayed
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
JOIN ad_field f ON f.ad_column_id = c.ad_column_id
WHERE t.tablename = 'AbERP_Skip_Dates' AND c.columnname = 'AbERP_CopyDatesFrom';
