-- SAW009 rollback (AD fields/columns + trigger; keeps physical DB columns nullable)
SET search_path TO adempiere;

DROP TRIGGER IF EXISTS tr_aberp_c_orderline_copy_pattern_days ON c_orderline;
DROP FUNCTION IF EXISTS adempiere.aberp_c_orderline_copy_pattern_days();

DELETE FROM ad_field
WHERE ad_field_uu IN (
  'c0a90003-50a9-4009-a001-000000000003',
  'c0a90004-50a9-4009-a001-000000000004'
);

DELETE FROM ad_column
WHERE ad_column_uu IN (
  'c0a90001-50a9-4009-a001-000000000001',
  'c0a90002-50a9-4009-a001-000000000002'
);

-- Optional: uncomment to drop physical columns (destructive)
-- ALTER TABLE c_orderline DROP COLUMN IF EXISTS aberp_support_start_day;
-- ALTER TABLE c_orderline DROP COLUMN IF EXISTS aberp_support_end_day;
