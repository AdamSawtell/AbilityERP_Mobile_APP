-- =============================================================================
-- SAW019 — Show Capture Status for unprocessed (Pending) captures
-- After Upload (and after Process): Document No + Capture Status + Last Result
-- Pending = waiting for manual Process or overnight batch — not the Processed flag
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_tab INTEGER;
  v_fg_ready INTEGER;
  v_s23 CONSTANT TEXT := '@Processed@=Y | (@Processed@=N & @LastResult@!'''')';
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

  SELECT ad_fieldgroup_id INTO v_fg_ready
  FROM ad_fieldgroup
  WHERE ad_fieldgroup_uu = '19a019fg-0002-4f01-8e15-000000000001'
     OR (name = 'Document' AND entitytype = 'Ab_ERP')
  LIMIT 1;

  -- Capture Status: visible once uploaded (Pending) and after process (OK/RR/…)
  UPDATE ad_field f SET
    isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    isreadonly = 'Y',
    iscentrallymaintained = 'N',
    displaylogic = v_s23,
    ad_fieldgroup_id = COALESCE(v_fg_ready, f.ad_fieldgroup_id),
    seqno = 35,
    seqnogrid = 20,
    issameline = 'Y',
    xposition = 4,
    columnspan = 2,
    description = 'Pending = waiting for Process (tonight''s batch or the Process button). Other values are the last process outcome.',
    help = $h$Use Capture Status — not the system Processed flag — to see where a capture sits.

• Pending — PDF uploaded (or saved ready); waiting for overnight batch or manual Process.
• Successfully Processed — Draft AP created; review Vendor Invoice.
• Requires Review / Vendor Not Matched / Possible Duplicate / etc. — open the record and fix, then use Process on the window (batch will not retry these).

Records added during the day stay Pending until the night batch (or you Process them).$h$,
    updated = NOW(),
    updatedby = 100
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab
    AND f.ad_column_id = c.ad_column_id
    AND c.columnname = 'CaptureStatus';

  UPDATE ad_field_trl ft SET
    description = f.description,
    help = f.help,
    istranslated = 'N',
    updated = NOW()
  FROM ad_field f
  JOIN ad_column c ON c.ad_column_id = f.ad_column_id
  WHERE ft.ad_field_id = f.ad_field_id
    AND f.ad_tab_id = v_tab
    AND c.columnname = 'CaptureStatus';

  -- Document No stays leading column on the Document row
  UPDATE ad_field f SET
    seqno = 30,
    issameline = 'N',
    xposition = 1,
    columnspan = 2,
    updated = NOW()
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab
    AND f.ad_column_id = c.ad_column_id
    AND c.columnname = 'DocumentNo';

  -- Clarify Pending in the list (where present)
  UPDATE ad_ref_list SET
    description = 'Waiting for Process — overnight batch or the Process button on the window.',
    updated = NOW()
  WHERE value = 'PE'
    AND ad_reference_id = (
      SELECT c.ad_reference_value_id
      FROM ad_column c
      JOIN ad_table t ON t.ad_table_id = c.ad_table_id
      WHERE t.tablename = 'AbERP_InvoiceCapture' AND c.columnname = 'CaptureStatus'
      LIMIT 1
    );

  RAISE NOTICE 'SAW019 Capture Status shown for Pending (uploaded) and processed records (tab=%)', v_tab;
END $$;
