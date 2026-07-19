-- SAW027 — Reviewed model validator metadata (INACTIVE in AD)
-- Plugin registers the validator via OSGi activator (activityaudit-activator.xml).
-- Activating AD_ModelValidator for a plugin class breaks login:
--   "Missing class … global" (core Class.forName cannot see OSGi bundles).
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_modelvalidator_id),0)+1 FROM ad_modelvalidator))
WHERE name = 'AD_ModelValidator' AND istableid = 'Y';

DO $$
DECLARE
  v_id INTEGER;
  v_uu CONSTANT TEXT := '27a027mv-0001-4f01-8e15-000000000001';
  v_class CONSTANT TEXT := 'com.aberp.activityaudit.model.ActivityAuditReviewValidator';
BEGIN
  SELECT ad_modelvalidator_id INTO v_id FROM ad_modelvalidator WHERE ad_modelvalidator_uu = v_uu;
  IF v_id IS NULL THEN
    SELECT ad_modelvalidator_id INTO v_id FROM ad_modelvalidator WHERE modelvalidationclass = v_class LIMIT 1;
  END IF;

  IF v_id IS NULL THEN
    INSERT INTO ad_modelvalidator (
      ad_modelvalidator_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, entitytype, modelvalidationclass, seqno, ad_modelvalidator_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_ModelValidator' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'N', NOW(), 100, NOW(), 100,
      'AbERP Activity Audit Review',
      'INACTIVE — registered by OSGi activator; do not activate (breaks login)',
      'Runtime: com.aberp.activityaudit ActivityAuditActivator → ModelValidationEngine',
      'Ab_ERP', v_class, 100, v_uu
    );
  ELSE
    UPDATE ad_modelvalidator SET
      name = 'AbERP Activity Audit Review',
      description = 'INACTIVE — registered by OSGi activator; do not activate (breaks login)',
      modelvalidationclass = v_class,
      entitytype = 'Ab_ERP',
      isactive = 'N',
      ad_modelvalidator_uu = COALESCE(NULLIF(ad_modelvalidator_uu, ''), v_uu),
      updated = NOW()
    WHERE ad_modelvalidator_id = v_id;
  END IF;

  RAISE NOTICE 'SAW027 model validator AD row kept inactive; OSGi activator registers at runtime';
END $$;
