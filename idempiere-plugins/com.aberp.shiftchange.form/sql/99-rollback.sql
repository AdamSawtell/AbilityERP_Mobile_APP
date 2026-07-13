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

-- Restore CreateRequestFromTemplate para to shared "all templates" val rule
UPDATE ad_process_para pp
SET ad_val_rule_id = (
      SELECT ad_val_rule_id FROM ad_val_rule
      WHERE ad_val_rule_uu = '503d0fb8-d780-4a81-b2d3-081f2f3a25f5'
         OR name = 'R_Request Template'
      LIMIT 1
    ),
    defaultvalue = '@SQL=SELECT R_Request_ID FROM R_Request WHERE R_Request.IsActive=''Y'' AND R_Request.IsTemplate = ''Y'' ORDER BY Created DESC FETCH FIRST ROWS ONLY',
    updated = NOW(),
    updatedby = 100
WHERE pp.ad_process_para_uu = '13425072-7cf3-4cf0-8ff4-d3c1f00ef393'
   OR (pp.columnname = 'RequestTemplate_ID'
       AND pp.ad_process_id = (
         SELECT ad_process_id FROM ad_process
         WHERE ad_process_uu = '3a8e1690-80f7-41b5-9ed9-96f5f3796823'
            OR value = 'CreateRequestFromTemplate'
         LIMIT 1
       ));

DELETE FROM ad_val_rule
WHERE ad_val_rule_uu = 'a0130004-5a01-4e13-a013-000000000004';
