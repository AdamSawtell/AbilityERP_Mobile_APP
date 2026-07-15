-- =============================================================================
-- SAW023 — Compliance & Audit Hub preflight (fail closed)
-- =============================================================================
SET search_path TO adempiere;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ad_entitytype WHERE entitytype = 'Ab_ERP') THEN
    RAISE EXCEPTION 'SAW023 preflight failed: entity type Ab_ERP missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM ad_sequence WHERE name = 'AD_Table' AND istableid = 'Y'
  ) THEN
    RAISE EXCEPTION 'SAW023 preflight failed: AD_Table sequence missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM ad_table WHERE tablename = 'AbERP_Support_Location'
  ) THEN
    RAISE EXCEPTION 'SAW023 preflight failed: AbERP_Support_Location AD_Table missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'adempiere' AND table_name = 'aberp_support_location'
  ) THEN
    RAISE EXCEPTION 'SAW023 preflight failed: physical aberp_support_location missing';
  END IF;

  RAISE NOTICE 'SAW023 preflight OK';
END $$;
