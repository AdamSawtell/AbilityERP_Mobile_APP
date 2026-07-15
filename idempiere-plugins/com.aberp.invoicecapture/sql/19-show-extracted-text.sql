-- =============================================================================
-- SAW019 — Show Extracted Text after process (large textarea)
-- Hidden while Pending; visible once Processed=Y
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_tab INTEGER;
BEGIN
  SELECT t.ad_tab_id INTO v_tab
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE w.ad_window_uu = '19a01903-c0d4-4f01-8e15-000000000001'
    AND t.seqno = 10
  LIMIT 1;
  IF v_tab IS NULL THEN
    SELECT t.ad_tab_id INTO v_tab
    FROM ad_tab t
    JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
    WHERE tb.tablename = 'AbERP_InvoiceCapture' AND t.seqno = 10
    LIMIT 1;
  END IF;
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'SAW019: Invoice Capture header tab missing';
  END IF;

  UPDATE ad_field f SET
    isdisplayed = 'Y',
    isdisplayedgrid = 'N',
    isreadonly = 'Y',
    seqno = 105,
    seqnogrid = 0,
    issameline = 'N',
    xposition = 1,
    columnspan = 5,
    numlines = 10,
    displaylength = 80,
    displaylogic = '@Processed@=Y',
    updated = NOW(),
    updatedby = 100
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab
    AND f.ad_column_id = c.ad_column_id
    AND c.columnname = 'ExtractedText';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'SAW019: ExtractedText field missing on Invoice Capture tab';
  END IF;

  RAISE NOTICE 'SAW019 Extracted Text shown after process (numlines=10, tab=%)', v_tab;
END $$;
