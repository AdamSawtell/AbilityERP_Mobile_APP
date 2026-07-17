-- =============================================================================
-- SAW027 — Activity Audit preflight (fail closed)
-- =============================================================================
SET search_path TO adempiere;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ad_entitytype WHERE entitytype = 'Ab_ERP') THEN
    RAISE EXCEPTION 'SAW027 preflight failed: entity type Ab_ERP missing';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_table WHERE tablename = 'C_ContactActivity') THEN
    RAISE EXCEPTION 'SAW027 preflight failed: C_ContactActivity table missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'adempiere' AND table_name = 'c_contactactivity'
      AND column_name IN ('description', 'comments')
    HAVING COUNT(*) = 2
  ) THEN
    RAISE EXCEPTION 'SAW027 preflight failed: C_ContactActivity.Description/Comments missing';
  END IF;

  RAISE NOTICE 'SAW027 preflight OK';
END $$;
