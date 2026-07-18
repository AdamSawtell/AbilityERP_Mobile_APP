-- SAW029 layout rollback (partial) — prefer DB backup for production.
-- Restores Follow-Up checkbox visibility and moves Active out of Audit same-line pairing.
-- Does not restore every pre-SAW029 seqno / field group assignment.
SET search_path TO adempiere;

DO $$
DECLARE
  v_tab INTEGER;
  v_fg_review INTEGER;
BEGIN
  SELECT ad_tab_id INTO v_tab FROM ad_tab
  WHERE ad_tab_uu = '27a02751-c0d4-4f01-8e15-000000000001'
  LIMIT 1;
  IF v_tab IS NULL THEN
    SELECT t.ad_tab_id INTO v_tab
    FROM ad_tab t
    JOIN ad_window w ON w.ad_window_id = t.ad_window_id
    WHERE w.name = 'Activity Audit Review' AND t.name = 'Reviews'
    LIMIT 1;
  END IF;
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'SAW029 rollback: Reviews tab missing';
  END IF;

  SELECT ad_fieldgroup_id INTO v_fg_review FROM ad_fieldgroup
  WHERE ad_fieldgroup_uu = '29a029fg-0003-4f01-8e15-000000000001'
     OR (name = 'Review' AND entitytype = 'Ab_ERP')
  LIMIT 1;

  UPDATE ad_field f
  SET isdisplayed = 'Y',
      isdisplayedgrid = 'Y',
      isactive = 'Y',
      ad_fieldgroup_id = v_fg_review,
      seqno = 140,
      issameline = 'N',
      xposition = 1,
      updated = NOW()
  FROM ad_column c
  WHERE f.ad_column_id = c.ad_column_id
    AND f.ad_tab_id = v_tab
    AND c.columnname = 'IsFollowUpRequired';

  UPDATE ad_field f
  SET ad_fieldgroup_id = v_fg_review,
      seqno = 150,
      issameline = 'Y',
      xposition = 4,
      isdisplayed = 'Y',
      isdisplayedgrid = 'N',
      updated = NOW()
  FROM ad_column c
  WHERE f.ad_column_id = c.ad_column_id
    AND f.ad_tab_id = v_tab
    AND c.columnname = 'IsActive';

  RAISE NOTICE 'SAW029 rollback applied (partial layout). Cache Reset + re-login required.';
END $$;
