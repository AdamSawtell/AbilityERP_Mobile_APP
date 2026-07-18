-- =============================================================================
-- SAW029 — Activity Audit Review form: field groups + tidy layout
-- Groups: Activity → Match → Review → Audit (collapsed)
-- SQL-only; no JAR change.
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_fieldgroup_id),0)+1 FROM ad_fieldgroup))
WHERE name = 'AD_FieldGroup' AND istableid = 'Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name = 'AD_Field' AND istableid = 'Y';

CREATE OR REPLACE FUNCTION pg_temp.saw029_fieldgroup(
  p_uu TEXT, p_name TEXT, p_collapsed CHAR
) RETURNS INTEGER AS $$
DECLARE
  v_id INTEGER;
BEGIN
  SELECT ad_fieldgroup_id INTO v_id FROM ad_fieldgroup WHERE ad_fieldgroup_uu = p_uu;
  IF v_id IS NULL THEN
    SELECT ad_fieldgroup_id INTO v_id
    FROM ad_fieldgroup
    WHERE name = p_name AND entitytype = 'Ab_ERP'
    ORDER BY ad_fieldgroup_id
    LIMIT 1;
  END IF;
  IF v_id IS NULL THEN
    INSERT INTO ad_fieldgroup (
      ad_fieldgroup_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, entitytype, fieldgrouptype, iscollapsedbydefault, ad_fieldgroup_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_FieldGroup' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, 'Ab_ERP', 'C', p_collapsed, p_uu
    ) RETURNING ad_fieldgroup_id INTO v_id;
  ELSE
    UPDATE ad_fieldgroup SET
      name = p_name,
      entitytype = 'Ab_ERP',
      fieldgrouptype = 'C',
      iscollapsedbydefault = p_collapsed,
      ad_fieldgroup_uu = COALESCE(NULLIF(ad_fieldgroup_uu, ''), p_uu),
      isactive = 'Y',
      updated = NOW()
    WHERE ad_fieldgroup_id = v_id;
  END IF;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw029_field(
  p_tab_id INTEGER, p_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_seqno INTEGER, p_displayed CHAR, p_readonly CHAR,
  p_sameline CHAR, p_gridseq INTEGER, p_displayedgrid CHAR,
  p_fieldgroup_id INTEGER, p_xposition INTEGER, p_columnspan INTEGER,
  p_numlines INTEGER DEFAULT 1
) RETURNS void AS $$
DECLARE
  v_col_id INTEGER;
  v_field_id INTEGER;
  v_table_id INTEGER;
BEGIN
  SELECT ad_table_id INTO v_table_id FROM ad_tab WHERE ad_tab_id = p_tab_id;
  SELECT ad_column_id INTO v_col_id FROM ad_column
  WHERE ad_table_id = v_table_id AND columnname = p_columnname;
  IF v_col_id IS NULL THEN
    RAISE NOTICE 'SAW029 skip % — column missing', p_columnname;
    RETURN;
  END IF;

  SELECT ad_field_id INTO v_field_id FROM ad_field WHERE ad_field_uu = p_uu;
  IF v_field_id IS NULL THEN
    SELECT ad_field_id INTO v_field_id FROM ad_field
    WHERE ad_tab_id = p_tab_id AND ad_column_id = v_col_id;
  END IF;

  IF v_field_id IS NULL THEN
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, iscentrallymaintained, ad_tab_id, ad_column_id,
      isdisplayed, displaylength, isreadonly, seqno, issameline,
      isheading, isfieldonly, isencrypted, entitytype,
      isdisplayedgrid, seqnogrid, xposition, columnspan, numlines,
      ad_fieldgroup_id, ad_field_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, 'Y', p_tab_id, v_col_id,
      p_displayed, 0, p_readonly, p_seqno, p_sameline,
      'N', 'N', 'N', 'Ab_ERP',
      p_displayedgrid, COALESCE(p_gridseq, p_seqno), p_xposition, p_columnspan, p_numlines,
      p_fieldgroup_id, p_uu
    );
  ELSE
    UPDATE ad_field SET
      name = p_name,
      isdisplayed = p_displayed,
      isreadonly = p_readonly,
      seqno = p_seqno,
      issameline = p_sameline,
      isdisplayedgrid = p_displayedgrid,
      seqnogrid = COALESCE(p_gridseq, p_seqno),
      xposition = p_xposition,
      columnspan = p_columnspan,
      numlines = p_numlines,
      ad_fieldgroup_id = p_fieldgroup_id,
      ad_field_uu = COALESCE(NULLIF(ad_field_uu, ''), p_uu),
      updated = NOW()
    WHERE ad_field_id = v_field_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_tab INTEGER;
  v_fg_activity INTEGER;
  v_fg_match INTEGER;
  v_fg_review INTEGER;
  v_fg_audit INTEGER;
BEGIN
  SELECT ad_tab_id INTO v_tab FROM ad_tab WHERE ad_tab_uu = '27a02751-c0d4-4f01-8e15-000000000001';
  IF v_tab IS NULL THEN
    SELECT t.ad_tab_id INTO v_tab
    FROM ad_tab t
    JOIN ad_window w ON w.ad_window_id = t.ad_window_id
    WHERE w.name = 'Activity Audit Review' AND t.name = 'Reviews'
    LIMIT 1;
  END IF;
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'SAW029: Activity Audit Review / Reviews tab missing';
  END IF;

  v_fg_activity := pg_temp.saw029_fieldgroup(
    '29a029fg-0001-4f01-8e15-000000000001', 'Activity', 'N');
  v_fg_match := pg_temp.saw029_fieldgroup(
    '29a029fg-0002-4f01-8e15-000000000001', 'Match', 'N');
  v_fg_review := pg_temp.saw029_fieldgroup(
    '29a029fg-0003-4f01-8e15-000000000001', 'Review', 'N');

  SELECT ad_fieldgroup_id INTO v_fg_audit
  FROM ad_fieldgroup
  WHERE ad_fieldgroup_uu = '3551f0df-bb72-40ab-8b1c-c28a7fec9a46';
  IF v_fg_audit IS NULL THEN
    SELECT ad_fieldgroup_id INTO v_fg_audit
    FROM ad_fieldgroup
    WHERE name = 'Audit' AND entitytype = 'Ab_ERP'
    ORDER BY ad_fieldgroup_id LIMIT 1;
  END IF;
  IF v_fg_audit IS NULL THEN
    RAISE EXCEPTION 'SAW029: Audit field group missing';
  END IF;

  -- Identity / system (hidden)
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f000-4f01-8e15-000000000001',
    'AbERP_ActivityAuditReview_ID','Activity Audit Review',0,'N','Y','N',0,'N', NULL, 1, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f00c-4f01-8e15-000000000001',
    'AD_Client_ID','Client',5,'N','Y','N',5,'N', NULL, 1, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f016-4f01-8e15-000000000001',
    'AD_Org_ID','Organisation',6,'N','Y','N',6,'N', NULL, 1, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f012-4f01-8e15-000000000001',
    'C_ContactActivity_ID','Activity',7,'N','Y','N',7,'N', NULL, 1, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f018-4f01-8e15-000000000001',
    'Processing','Processing',8,'N','Y','N',8,'N', NULL, 4, 2);

  --------------------------------------------------------------------------
  -- Activity — who / when / open source
  --------------------------------------------------------------------------
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f001-4f01-8e15-000000000001',
    'ActivityDate','Activity Date',10,'Y','Y','N',10,'Y', v_fg_activity, 1, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f019-4f01-8e15-000000000001',
    'AbERP_OpenActivity','Open Activity',20,'Y','N','Y',15,'Y', v_fg_activity, 4, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f002-4f01-8e15-000000000001',
    'C_BPartner_ID','Client',30,'Y','Y','N',20,'Y', v_fg_activity, 1, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f003-4f01-8e15-000000000001',
    'AD_User_ID','Employee',40,'Y','Y','Y',30,'Y', v_fg_activity, 4, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f004-4f01-8e15-000000000001',
    'ContactActivityType','Activity Type',50,'Y','Y','N',40,'Y', v_fg_activity, 1, 2);

  UPDATE ad_field SET istoolbarbutton = 'B', isreadonly = 'N', updated = NOW()
  WHERE ad_field_uu = '27a02751-f019-4f01-8e15-000000000001';

  --------------------------------------------------------------------------
  -- Match — why this row was flagged
  --------------------------------------------------------------------------
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f005-4f01-8e15-000000000001',
    'MatchedTerms','Matched Terms',60,'Y','Y','N',50,'Y', v_fg_match, 1, 5);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f006-4f01-8e15-000000000001',
    'Category','Category',70,'Y','Y','N',60,'Y', v_fg_match, 1, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f007-4f01-8e15-000000000001',
    'HighestRiskLevel','Risk Level',80,'Y','Y','Y',70,'Y', v_fg_match, 4, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f013-4f01-8e15-000000000001',
    'MatchedExtract','Matched Text Extract',90,'Y','Y','N',130,'N', v_fg_match, 1, 5, 4);

  --------------------------------------------------------------------------
  -- Review — decision fields
  -- Reviewed checkbox is kept: stamps Reviewed By/Date and clears the queue.
  -- Follow-Up Required checkbox is hidden: use Review Status = Follow-Up Required.
  --------------------------------------------------------------------------
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f008-4f01-8e15-000000000001',
    'ReviewStatus','Review Status',100,'Y','N','N',80,'Y', v_fg_review, 1, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f009-4f01-8e15-000000000001',
    'IsReviewed','Reviewed',110,'Y','N','Y',90,'Y', v_fg_review, 4, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f010-4f01-8e15-000000000001',
    'ReviewedBy','Reviewed By',120,'Y','Y','N',100,'Y', v_fg_review, 1, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f011-4f01-8e15-000000000001',
    'ReviewedDate','Reviewed Date',130,'Y','Y','Y',110,'Y', v_fg_review, 4, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f014-4f01-8e15-000000000001',
    'ReviewNotes','Review Notes',140,'Y','N','N',140,'N', v_fg_review, 1, 5, 3);
  -- Hidden: redundant with Review Status list value FU
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f015-4f01-8e15-000000000001',
    'IsFollowUpRequired','Follow-Up Required',150,'N','N','N',150,'N', NULL, 1, 2);

  --------------------------------------------------------------------------
  -- Audit (collapsed) — Active on same line as Activity Updated Audited
  --------------------------------------------------------------------------
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f017-4f01-8e15-000000000001',
    'ActivityUpdatedAudited','Activity Updated Audited',890,'Y','Y','N',890,'N', v_fg_audit, 1, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f030-4f01-8e15-000000000001',
    'IsActive','Active',895,'Y','N','Y',155,'N', v_fg_audit, 4, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f020-4f01-8e15-000000000001',
    'Created','Created',900,'Y','Y','N',900,'N', v_fg_audit, 1, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f021-4f01-8e15-000000000001',
    'CreatedBy','Created By',910,'Y','Y','Y',910,'N', v_fg_audit, 4, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f022-4f01-8e15-000000000001',
    'Updated','Updated',920,'Y','Y','N',920,'N', v_fg_audit, 1, 2);
  PERFORM pg_temp.saw029_field(v_tab,'27a02751-f023-4f01-8e15-000000000001',
    'UpdatedBy','Updated By',930,'Y','Y','Y',930,'N', v_fg_audit, 4, 2);

  UPDATE ad_window SET
    description = 'Review keyword-flagged Contact Activities',
    help = 'Work the queue from the grid, then open a row to review. '
        || 'Activity shows who and when; Match shows why it was flagged; '
        || 'Review is where you set status and notes. Use Open Activity to read the source record.',
    updated = NOW()
  WHERE name = 'Activity Audit Review'
     OR ad_window_uu = '27a02750-c0d4-4f01-8e15-000000000001';

  UPDATE ad_tab SET
    description = 'Outstanding activity audit reviews',
    help = 'Grid is the queue. Form is grouped: Activity → Match → Review → Audit.',
    updated = NOW()
  WHERE ad_tab_id = v_tab;

  RAISE NOTICE 'SAW029 Review field groups applied (Activity=% Match=% Review=% Audit=%)',
    v_fg_activity, v_fg_match, v_fg_review, v_fg_audit;
END $$;
