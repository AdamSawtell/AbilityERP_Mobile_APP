-- SAW012: Process Audit default WhereClause — hide Document Validation flood
-- Those rows remain in DB (HouseKeeping/purge still apply). Real process runs stay visible.
-- Resolves process by Value (portable). Fail closed if neither process exists? No — empty IN is fine.

UPDATE ad_tab
SET whereclause = 'AD_Process_ID NOT IN (SELECT AD_Process_ID FROM AD_Process WHERE Value IN (''ChuBoe_Validate_Document'',''AbERP_Validate_Document''))',
    updated = now(),
    updatedby = 100
WHERE ad_tab_uu = '58bba03d-cb5c-4230-aeb2-1a435ae41b93';

SELECT name, whereclause, maxqueryrecords
FROM ad_tab
WHERE ad_tab_uu = '58bba03d-cb5c-4230-aeb2-1a435ae41b93';
