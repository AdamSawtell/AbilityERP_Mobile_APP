-- SAW021 — preflight
SET search_path TO adempiere;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ad_table WHERE tablename = 'AbERP_OngoingUnavailability') THEN
    RAISE EXCEPTION 'SAW021: AbERP_OngoingUnavailability missing';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ad_table WHERE tablename = 'AbERP_UnavailableDays') THEN
    RAISE EXCEPTION 'SAW021: AbERP_UnavailableDays missing';
  END IF;
  RAISE NOTICE 'SAW021 preflight OK';
END $$;
