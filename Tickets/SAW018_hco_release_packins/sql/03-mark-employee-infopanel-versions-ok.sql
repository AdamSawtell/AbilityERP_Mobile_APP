-- SAW018 optional: stop legacy com.aberp.employee.infopanel Incremental2Pack retries
-- Use only when imports fail with: Failed to save InfoWindow Employee (User) / Agency Staff Rostering Info
-- Prefer OSGi uninstall of com.aberp.employee.infopanel when staffinfo JAR is the live Info factory.
SET search_path TO adempiere;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

UPDATE ad_package_imp
SET pk_status = 'Completed successfully',
    processed = 'Y',
    updated = NOW(),
    updatedby = 100
WHERE name = 'com.aberp.employee.infopanel'
  AND pk_status = 'Import Failed';

DO $$
DECLARE
  v text;
  seq_id numeric;
  new_id numeric;
  vers text[] := ARRAY['7.1.3','7.1.4','7.1.5','7.1.6','7.1.7','7.1.8','7.1.9','7.1.10','7.1.11','7.1.12'];
BEGIN
  SELECT ad_sequence_id INTO seq_id FROM ad_sequence WHERE name='AD_Package_Imp' AND istableid='Y';
  FOREACH v IN ARRAY vers LOOP
    IF NOT EXISTS (
      SELECT 1 FROM ad_package_imp
      WHERE name='com.aberp.employee.infopanel' AND pk_version=v AND pk_status='Completed successfully'
    ) THEN
      SELECT COALESCE(MAX(ad_package_imp_id),0)+1 INTO new_id FROM ad_package_imp;
      INSERT INTO ad_package_imp (
        ad_package_imp_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
        name, pk_status, pk_version, processed, processing, ad_package_imp_uu
      ) VALUES (
        new_id, 0, 0, 'Y', NOW(), 100, NOW(), 100,
        'com.aberp.employee.infopanel', 'Completed successfully', v, 'Y', 'N', uuid_generate_v4()::text
      );
      UPDATE ad_sequence SET currentnext = GREATEST(currentnext, new_id+1) WHERE ad_sequence_id = seq_id;
    END IF;
  END LOOP;
END $$;
