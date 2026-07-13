-- SAW016 Leave Planning — preflight (fail closed if leave foundation missing)
SET search_path TO adempiere;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM ad_table WHERE tablename = 'AbERP_Unavailability_Leave'
  ) THEN
    RAISE EXCEPTION 'SAW016 preflight: AbERP_Unavailability_Leave table missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM ad_column c
    JOIN ad_table t ON t.ad_table_id = c.ad_table_id
    WHERE t.tablename = 'AbERP_Unavailability_Leave'
      AND c.columnname = 'AbERP_ApproverStatus'
  ) THEN
    RAISE EXCEPTION 'SAW016 preflight: AbERP_ApproverStatus column missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM ad_window WHERE ad_window_uu = '80352010-b3bd-47e6-a783-71de6b046da8'
       OR name = 'Unavailability & Leave (all)'
  ) THEN
    RAISE EXCEPTION 'SAW016 preflight: Unavailability & Leave (all) window missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM ad_entitytype WHERE entitytype = 'Ab_ERP'
  ) THEN
    RAISE EXCEPTION 'SAW016 preflight: EntityType Ab_ERP missing';
  END IF;

  RAISE NOTICE 'SAW016 preflight OK';
END $$;
