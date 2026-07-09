-- Disable Accept button field to stop Response Log tab row-1 timeout on open.
SET search_path TO adempiere;

UPDATE ad_field
SET isactive = 'N', updated = NOW(), updatedby = 100
WHERE ad_tab_id = 1000366
  AND ad_column_id = (SELECT ad_column_id FROM ad_column WHERE columnname = 'AbERP_AcceptShiftRequest');

UPDATE ad_toolbarbutton
SET isactive = 'N', updated = NOW(), updatedby = 100
WHERE name = 'Accept Shift Request' AND ad_tab_id = 1000366;
