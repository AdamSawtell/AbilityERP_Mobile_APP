-- SAW018: clear stuck 2Pack imports that block PackIn / Incremental2PackActivator
-- Safe: only marks processed='N' + pk_status='Installing' as failed (does not delete history)
SET search_path TO adempiere;

UPDATE ad_package_imp
SET processed = 'Y',
    pk_status = 'Import Failed',
    updated = NOW(),
    updatedby = 100
WHERE processed = 'N'
  AND COALESCE(pk_status, '') IN ('Installing', '');

SELECT COUNT(*) AS remaining_stuck
FROM ad_package_imp
WHERE processed = 'N';
