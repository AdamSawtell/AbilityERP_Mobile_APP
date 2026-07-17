-- =============================================================================
-- SAW027 — Add missing Processing column on AbERP_ActivityAuditReview
-- Root cause: Open Activity button AD_Column exists, but physical column did not.
-- WebUI grid SELECT includes Processing → ERROR → 30s timeout → empty grid.
-- =============================================================================
SET search_path TO adempiere;

ALTER TABLE aberp_activityauditreview
  ADD COLUMN IF NOT EXISTS processing character(1) NOT NULL DEFAULT 'N';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'aberp_activityauditreview_processing_chk'
  ) THEN
    ALTER TABLE aberp_activityauditreview
      ADD CONSTRAINT aberp_activityauditreview_processing_chk
      CHECK (processing IN ('Y','N'));
  END IF;
END $$;

-- Keep AD_Column in sync (Button + Open Activity process)
UPDATE ad_column c SET
  ad_reference_id = 28,
  fieldlength = 1,
  isupdateable = 'Y',
  isalwaysupdateable = 'Y',
  ad_process_id = (
    SELECT ad_process_id FROM ad_process
    WHERE value = 'AbERP_ActivityAudit_OpenActivity'
    LIMIT 1
  ),
  updated = NOW()
WHERE c.columnname = 'Processing'
  AND c.ad_table_id = (
    SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_ActivityAuditReview'
  );

-- Hide button from grid columns (form / toolbar only); still loadable for process
UPDATE ad_field f SET
  isdisplayedgrid = 'N',
  updated = NOW()
WHERE f.ad_field_uu = '27a02751-f018-4f01-8e15-000000000001';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'adempiere'
      AND table_name = 'aberp_activityauditreview'
      AND column_name = 'processing'
  ) THEN
    RAISE EXCEPTION 'SAW027: Processing column still missing on aberp_activityauditreview';
  END IF;
  RAISE NOTICE 'SAW027 Processing column OK';
END $$;
