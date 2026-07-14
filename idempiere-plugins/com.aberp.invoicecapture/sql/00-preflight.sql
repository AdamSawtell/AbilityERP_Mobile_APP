-- =============================================================================
-- SAW019 — Invoice Capture preflight (fail closed)
-- =============================================================================
SET search_path TO adempiere;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ad_entitytype WHERE entitytype = 'Ab_ERP') THEN
    RAISE EXCEPTION 'SAW019 preflight failed: entity type Ab_ERP missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM ad_sequence WHERE name = 'AD_Table' AND istableid = 'Y'
  ) THEN
    RAISE EXCEPTION 'SAW019 preflight failed: AD_Table sequence missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM c_doctype
    WHERE ad_client_id = (SELECT ad_client_id FROM ad_client WHERE name = 'AbilityERP' LIMIT 1)
      AND docbasetype = 'API' AND isactive = 'Y'
  ) THEN
    RAISE NOTICE 'SAW019 preflight: no API doc type on AbilityERP yet — runtime resolve may still find one by client';
  END IF;

  RAISE NOTICE 'SAW019 preflight OK';
END $$;
