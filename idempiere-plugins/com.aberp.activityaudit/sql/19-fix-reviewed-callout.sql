-- SAW027 — Reviewed uses IColumnCalloutFactory only (OSGi-safe).
-- Classic AD_Column.Callout classname fails with ClassNotFoundException under org.adempiere.base.
SET search_path TO adempiere;

DO $$
DECLARE
  v_n INTEGER;
BEGIN
  UPDATE ad_column c
  SET callout = NULL,
      updated = NOW()
  FROM ad_table t
  WHERE c.ad_table_id = t.ad_table_id
    AND t.tablename = 'AbERP_ActivityAuditReview'
    AND c.columnname = 'IsReviewed'
    AND COALESCE(c.callout, '') <> '';

  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    -- Still OK if already cleared; ensure column exists
    IF NOT EXISTS (
      SELECT 1 FROM ad_column c
      JOIN ad_table t ON t.ad_table_id = c.ad_table_id
      WHERE t.tablename = 'AbERP_ActivityAuditReview' AND c.columnname = 'IsReviewed'
    ) THEN
      RAISE EXCEPTION 'SAW027: IsReviewed column missing on AbERP_ActivityAuditReview';
    END IF;
    RAISE NOTICE 'SAW027: IsReviewed classic Callout already cleared';
  ELSE
    RAISE NOTICE 'SAW027: cleared classic Callout on IsReviewed (% row(s)); factory handles stamping', v_n;
  END IF;
END $$;
