SET search_path TO adempiere;

-- SAW013 rollback (AD + triggers). Does not delete historical R_Request rows.

DROP TRIGGER IF EXISTS aberp_shiftchange_prevent_dup_request_trg ON adempiere.r_request;
DROP FUNCTION IF EXISTS adempiere.aberp_shiftchange_prevent_dup_request();
DROP TRIGGER IF EXISTS aberp_shiftchange_sync_from_request_trg ON adempiere.r_request;
DROP FUNCTION IF EXISTS adempiere.aberp_shiftchange_sync_from_request();

UPDATE ad_column
SET columnsql = NULL,
    isupdateable = 'Y',
    updated = NOW(),
    updatedby = 100
WHERE columnname = 'R_Status_ID'
  AND ad_table_id = (
    SELECT ad_table_id FROM ad_table
    WHERE ad_table_uu = '136fd0b7-e2b0-40a1-846f-1e198b8c232d'
       OR tablename = 'AbERP_ShiftChange'
    LIMIT 1
  );

UPDATE ad_field f
SET isreadonly = 'N',
    description = NULL,
    help = NULL,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND c.columnname = 'R_Status_ID'
  AND (w.name = 'HCO Forms and Approvals'
       OR w.ad_window_uu = 'b3919637-5125-4d2d-a9f7-6d751835f537');

UPDATE ad_field f
SET displaylogic = NULL,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND c.columnname = 'AbERP_CreateShiftChangeRequest'
  AND (w.name = 'HCO Forms and Approvals'
       OR w.ad_window_uu = 'b3919637-5125-4d2d-a9f7-6d751835f537');

UPDATE ad_field f
SET isdisplayed = 'N',
    isdisplayedgrid = 'N',
    updated = NOW(),
    updatedby = 100
FROM ad_column c
WHERE f.ad_column_id = c.ad_column_id
  AND c.columnname = 'AbERP_RequestSubmitted';

UPDATE ad_column
SET isactive = 'N',
    updated = NOW(),
    updatedby = 100
WHERE columnname = 'AbERP_RequestSubmitted'
  AND ad_table_id = (
    SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_ShiftChange' LIMIT 1
  );

-- Optional: keep physical aberp_requestsubmitted column (safe); comment out to drop:
-- ALTER TABLE aberp_shiftchange DROP COLUMN IF EXISTS aberp_requestsubmitted;
