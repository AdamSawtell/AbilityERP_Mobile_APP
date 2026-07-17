-- =============================================================================
-- SAW027 — Fix Review/Runs not editable (missing IsActive field)
-- iDempiere GridField.isEditable() requires tab context IsActive=Y.
-- Without an IsActive *column* field on the tab, context is empty → form R/O.
--
-- Note: UU 27a02751-f018 was previously used for Processing — do NOT reuse it.
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';

DO $$
DECLARE
  v_tab INTEGER;
  v_table INTEGER;
  v_col INTEGER;
  v_field INTEGER;
  v_proc_col INTEGER;
BEGIN
  --------------------------------------------------------------------------
  -- Repair: Active-named field wrongly bound to Processing (UU f018 collision)
  --------------------------------------------------------------------------
  SELECT t.ad_tab_id, t.ad_table_id INTO v_tab, v_table
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE w.name = 'Activity Audit Review' AND t.name = 'Reviews'
  LIMIT 1;
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'SAW027-15: Reviews tab missing';
  END IF;

  SELECT ad_column_id INTO v_proc_col
  FROM ad_column WHERE ad_table_id = v_table AND columnname = 'Processing';

  UPDATE ad_field SET
    name = 'Processing',
    isdisplayed = 'N',
    isdisplayedgrid = 'N',
    isreadonly = 'Y',
    seqno = 125,
    seqnogrid = 125,
    updated = NOW()
  WHERE ad_tab_id = v_tab
    AND ad_column_id = v_proc_col;

  --------------------------------------------------------------------------
  -- Real IsActive field (new UU — never reuse f018)
  --------------------------------------------------------------------------
  SELECT ad_column_id INTO v_col
  FROM ad_column WHERE ad_table_id = v_table AND columnname = 'IsActive';
  IF v_col IS NULL THEN
    RAISE EXCEPTION 'SAW027-15: IsActive column missing on AbERP_ActivityAuditReview';
  END IF;

  SELECT ad_field_id INTO v_field
  FROM ad_field WHERE ad_field_uu = '27a02751-f030-4f01-8e15-000000000001';
  IF v_field IS NULL THEN
    SELECT ad_field_id INTO v_field
    FROM ad_field WHERE ad_tab_id = v_tab AND ad_column_id = v_col;
  END IF;

  IF v_field IS NULL THEN
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, iscentrallymaintained, ad_tab_id, ad_column_id,
      isdisplayed, displaylength, isreadonly, seqno, issameline,
      isheading, isfieldonly, isencrypted, entitytype,
      isdisplayedgrid, seqnogrid, xposition, columnspan, numlines,
      ad_field_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Active', 'Y', v_tab, v_col,
      'Y', 1, 'N', 155, 'Y',
      'N', 'N', 'N', 'Ab_ERP',
      'N', 155, 4, 2, 1,
      '27a02751-f030-4f01-8e15-000000000001'
    );
  ELSE
    UPDATE ad_field SET
      name = 'Active',
      ad_column_id = v_col,
      isdisplayed = 'Y',
      isdisplayedgrid = 'N',
      isreadonly = 'N',
      seqno = 155,
      seqnogrid = 155,
      issameline = 'Y',
      xposition = 4,
      columnspan = 2,
      ad_field_uu = '27a02751-f030-4f01-8e15-000000000001',
      updated = NOW()
    WHERE ad_field_id = v_field;
  END IF;

  --------------------------------------------------------------------------
  -- Runs tab IsActive (hidden but loaded for context)
  --------------------------------------------------------------------------
  SELECT t.ad_tab_id, t.ad_table_id INTO v_tab, v_table
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE w.name = 'Activity Audit Runs' AND t.name = 'Runs'
  LIMIT 1;

  SELECT ad_column_id INTO v_col
  FROM ad_column WHERE ad_table_id = v_table AND columnname = 'IsActive';

  SELECT ad_field_id INTO v_field
  FROM ad_field WHERE ad_field_uu = '27a02761-f018-4f01-8e15-000000000001';
  IF v_field IS NULL THEN
    SELECT ad_field_id INTO v_field
    FROM ad_field WHERE ad_tab_id = v_tab AND ad_column_id = v_col;
  END IF;

  IF v_field IS NULL THEN
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, iscentrallymaintained, ad_tab_id, ad_column_id,
      isdisplayed, displaylength, isreadonly, seqno, issameline,
      isheading, isfieldonly, isencrypted, entitytype,
      isdisplayedgrid, seqnogrid, xposition, columnspan, numlines,
      ad_field_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Active', 'Y', v_tab, v_col,
      'N', 1, 'N', 5, 'N',
      'N', 'N', 'N', 'Ab_ERP',
      'N', 5, 1, 2, 1,
      '27a02761-f018-4f01-8e15-000000000001'
    );
  ELSE
    UPDATE ad_field SET
      name = 'Active',
      ad_column_id = v_col,
      isdisplayed = 'N',
      isdisplayedgrid = 'N',
      isreadonly = 'N',
      updated = NOW()
    WHERE ad_field_id = v_field;
  END IF;

  UPDATE ad_column SET
    isalwaysupdateable = 'Y',
    updated = NOW()
  WHERE ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_ActivityAuditReview')
    AND columnname IN ('ReviewedBy', 'ReviewedDate');

  UPDATE ad_field f SET
    isreadonly = 'N',
    updated = NOW()
  FROM ad_column c, ad_tab t, ad_window w
  WHERE f.ad_column_id = c.ad_column_id
    AND f.ad_tab_id = t.ad_tab_id
    AND t.ad_window_id = w.ad_window_id
    AND w.name = 'Activity Audit Review'
    AND t.name = 'Reviews'
    AND c.columnname IN ('ReviewStatus', 'IsReviewed', 'ReviewNotes', 'IsFollowUpRequired', 'IsActive');

  UPDATE ad_tab t SET
    isreadonly = 'N',
    isinsertrecord = 'Y',
    updated = NOW()
  FROM ad_window w
  WHERE t.ad_window_id = w.ad_window_id
    AND w.name IN ('Activity Audit Review', 'Activity Audit Runs');

  RAISE NOTICE 'SAW027-15 IsActive (real column) wired for Review/Runs';
END $$;
