-- =============================================================================
-- SAW027 — Windows: Terms, Review, Runs
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_window_id),0)+1 FROM ad_window))
WHERE name='AD_Window' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_tab_id),0)+1 FROM ad_tab))
WHERE name='AD_Tab' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw027_field(
  p_tab_id INTEGER, p_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_seqno INTEGER, p_displayed CHAR, p_readonly CHAR DEFAULT 'N',
  p_sameline CHAR DEFAULT 'N', p_gridseq INTEGER DEFAULT NULL,
  p_displayedgrid CHAR DEFAULT NULL, p_numlines INTEGER DEFAULT 1
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
    RAISE NOTICE 'SAW027 skip field % — column missing', p_columnname;
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
      isdisplayedgrid, seqnogrid, xposition, columnspan, numlines, ad_field_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, 'Y', p_tab_id, v_col_id,
      p_displayed, 0, p_readonly, p_seqno, p_sameline,
      'N', 'N', 'N', 'Ab_ERP',
      COALESCE(p_displayedgrid, p_displayed), COALESCE(p_gridseq, p_seqno), 1, 2, p_numlines, p_uu
    );
  ELSE
    UPDATE ad_field SET
      name = p_name, isdisplayed = p_displayed, isreadonly = p_readonly,
      seqno = p_seqno, issameline = p_sameline,
      isdisplayedgrid = COALESCE(p_displayedgrid, p_displayed),
      seqnogrid = COALESCE(p_gridseq, p_seqno),
      numlines = p_numlines,
      ad_field_uu = COALESCE(ad_field_uu, p_uu), updated = NOW()
    WHERE ad_field_id = v_field_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw027_window(
  p_uu TEXT, p_name TEXT, p_desc TEXT
) RETURNS INTEGER AS $$
DECLARE
  v_id INTEGER;
BEGIN
  SELECT ad_window_id INTO v_id FROM ad_window WHERE ad_window_uu = p_uu;
  IF v_id IS NULL THEN
    SELECT ad_window_id INTO v_id FROM ad_window WHERE name = p_name AND entitytype = 'Ab_ERP';
  END IF;
  IF v_id IS NULL THEN
    INSERT INTO ad_window (
      ad_window_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, windowtype, issotrx,
      entitytype, processing, isdefault, isbetafunctionality, ad_window_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Window' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, p_desc, NULL, 'M', 'N',
      'Ab_ERP', 'N', 'N', 'N', p_uu
    ) RETURNING ad_window_id INTO v_id;
  ELSE
    UPDATE ad_window SET name = p_name, description = p_desc, entitytype = 'Ab_ERP',
      ad_window_uu = COALESCE(ad_window_uu, p_uu), isactive = 'Y', updated = NOW()
    WHERE ad_window_id = v_id;
  END IF;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw027_tab(
  p_uu TEXT, p_window_id INTEGER, p_table_id INTEGER, p_name TEXT,
  p_seq INTEGER, p_where TEXT DEFAULT NULL, p_parent_col TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
  v_id INTEGER;
  v_parent INTEGER;
BEGIN
  v_parent := NULL;
  IF p_parent_col IS NOT NULL THEN
    SELECT ad_column_id INTO v_parent FROM ad_column
    WHERE ad_table_id = p_table_id AND columnname = p_parent_col;
  END IF;

  SELECT ad_tab_id INTO v_id FROM ad_tab WHERE ad_tab_uu = p_uu;
  IF v_id IS NULL THEN
    SELECT ad_tab_id INTO v_id FROM ad_tab WHERE ad_window_id = p_window_id AND name = p_name;
  END IF;
  IF v_id IS NULL THEN
    INSERT INTO ad_tab (
      ad_tab_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, ad_table_id, seqno, ad_window_id,
      tablevel, issinglerow, isinfotab, istranslationtab, isreadonly,
      hastree, whereclause, orderbyclause,
      commitwarning, processing, ad_process_id,
      ad_column_id, entitytype, isadvancedtab, ad_tab_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Tab' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, p_table_id, p_seq, p_window_id,
      CASE WHEN p_parent_col IS NULL THEN 0 ELSE 1 END,
      'Y', 'N', 'N', CASE WHEN p_parent_col IS NULL THEN 'N' ELSE 'Y' END,
      'N', p_where, NULL,
      NULL, 'N', NULL,
      v_parent, 'Ab_ERP', 'N', p_uu
    ) RETURNING ad_tab_id INTO v_id;
  ELSE
    UPDATE ad_tab SET
      name = p_name, ad_table_id = p_table_id, seqno = p_seq,
      whereclause = p_where, ad_column_id = COALESCE(v_parent, ad_column_id),
      entitytype = 'Ab_ERP', ad_tab_uu = COALESCE(ad_tab_uu, p_uu),
      isactive = 'Y', updated = NOW()
    WHERE ad_tab_id = v_id;
  END IF;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_win_term INTEGER;
  v_win_rev INTEGER;
  v_win_run INTEGER;
  v_tab INTEGER;
  v_tid INTEGER;
BEGIN
  -- Terms window
  v_win_term := pg_temp.saw027_window(
    '27a02740-c0d4-4f01-8e15-000000000001',
    'Activity Audit Terms',
    'Configure organisation audit words and phrases for Activity scanning');
  SELECT ad_table_id INTO v_tid FROM ad_table WHERE tablename = 'AbERP_ActivityAuditTerm';
  v_tab := pg_temp.saw027_tab('27a02741-c0d4-4f01-8e15-000000000001', v_win_term, v_tid, 'Audit Terms', 10);
  UPDATE ad_tab SET
    issinglerow = 'N',
    orderbyclause = 'AD_Org_ID, AuditWord, AbERP_ActivityAuditTerm_ID',
    updated = NOW()
  WHERE ad_tab_id = v_tab;
  UPDATE ad_table SET ad_window_id = v_win_term, ishighvolume = 'N' WHERE ad_table_id = v_tid;
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f000-4f01-8e15-000000000001','AbERP_ActivityAuditTerm_ID','Activity Audit Term',0,'N','Y','N',0,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f00c-4f01-8e15-000000000001','AD_Client_ID','Client',5,'N','Y','N',5,'N');
  -- Organisation hidden; Audit stamps via 14-format-audit-fieldgroup.sql
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f001-4f01-8e15-000000000001','AD_Org_ID','Organisation',10,'N','Y','N',10,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f002-4f01-8e15-000000000001','AuditWord','Audit Word or Phrase',20,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f003-4f01-8e15-000000000001','Description','Description',30,'Y','N','N',30,'Y',3);
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f004-4f01-8e15-000000000001','Category','Category',40,'Y','N','N',40);
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f005-4f01-8e15-000000000001','RiskLevel','Risk Level',50,'Y','N','Y',50);
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f006-4f01-8e15-000000000001','MatchType','Match Type',60,'Y','N','N',60);
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f007-4f01-8e15-000000000001','IsActive','Active',70,'Y','N','Y',70);
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f008-4f01-8e15-000000000001','ValidFrom','Effective From',80,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f009-4f01-8e15-000000000001','ValidTo','Effective To',90,'Y','N','Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f010-4f01-8e15-000000000001','Created','Created',900,'Y','Y','N',900,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f011-4f01-8e15-000000000001','CreatedBy','Created By',910,'Y','Y','Y',910,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f012-4f01-8e15-000000000001','Updated','Updated',920,'Y','Y','N',920,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f013-4f01-8e15-000000000001','UpdatedBy','Updated By',930,'Y','Y','Y',930,'N');

  SELECT ad_table_id INTO v_tid FROM ad_table WHERE tablename = 'AbERP_ActivityAuditTermAudit';
  v_tab := pg_temp.saw027_tab('27a02742-c0d4-4f01-8e15-000000000001', v_win_term, v_tid, 'Change History', 20, NULL, 'AbERP_ActivityAuditTerm_ID');
  PERFORM pg_temp.saw027_field(v_tab,'27a02742-f001-4f01-8e15-000000000001','ChangedDate','Changed Date',10,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02742-f002-4f01-8e15-000000000001','ChangedBy','Changed By',20,'Y','Y','Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02742-f003-4f01-8e15-000000000001','FieldName','Field',30,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02742-f004-4f01-8e15-000000000001','ChangeType','Change Type',40,'Y','N','Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02742-f005-4f01-8e15-000000000001','OldValue','Previous Value',50,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02742-f006-4f01-8e15-000000000001','NewValue','New Value',60,'Y');

  -- Review window (outstanding default) — grid-first for queue
  v_win_rev := pg_temp.saw027_window(
    '27a02750-c0d4-4f01-8e15-000000000001',
    'Activity Audit Review',
    'Review Activities flagged by the Activity Audit process');
  SELECT ad_table_id INTO v_tid FROM ad_table WHERE tablename = 'AbERP_ActivityAuditReview';
  v_tab := pg_temp.saw027_tab(
    '27a02751-c0d4-4f01-8e15-000000000001', v_win_rev, v_tid, 'Reviews', 10,
    'IsReviewed=''N'' AND ReviewStatus IN (''NW'',''UR'',''FU'',''IR'',''ES'')');
  UPDATE ad_tab SET
    issinglerow = 'N',
    orderbyclause = 'ActivityDate DESC, AbERP_ActivityAuditReview_ID DESC',
    updated = NOW()
  WHERE ad_tab_id = v_tab;
  UPDATE ad_table SET ad_window_id = v_win_rev, ishighvolume = 'N' WHERE ad_table_id = v_tid;
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f000-4f01-8e15-000000000001','AbERP_ActivityAuditReview_ID','Activity Audit Review',0,'N','Y','N',0,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f00c-4f01-8e15-000000000001','AD_Client_ID','Client',5,'N','Y','N',5,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f001-4f01-8e15-000000000001','ActivityDate','Activity Date',10,'Y','Y','N',10);
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f002-4f01-8e15-000000000001','C_BPartner_ID','Client',20,'Y','Y','N',20);
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f003-4f01-8e15-000000000001','AD_User_ID','Employee',30,'Y','Y','Y',30);
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f004-4f01-8e15-000000000001','ContactActivityType','Activity Type',40,'Y','Y','N',40);
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f005-4f01-8e15-000000000001','MatchedTerms','Matched Terms',50,'Y','Y','N',50);
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f006-4f01-8e15-000000000001','Category','Category',60,'Y','Y','Y',60);
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f007-4f01-8e15-000000000001','HighestRiskLevel','Risk Level',70,'Y','Y','Y',70);
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f008-4f01-8e15-000000000001','ReviewStatus','Review Status',80,'Y','N','N',80);
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f009-4f01-8e15-000000000001','IsReviewed','Reviewed',90,'Y','N','Y',90);
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f010-4f01-8e15-000000000001','ReviewedBy','Reviewed By',100,'Y','Y','N',100);
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f011-4f01-8e15-000000000001','ReviewedDate','Reviewed Date',110,'Y','Y','Y',110);
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f012-4f01-8e15-000000000001','C_ContactActivity_ID','Activity',120,'Y','Y','N',120);
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f013-4f01-8e15-000000000001','MatchedExtract','Matched Text Extract',130,'Y','Y','N',NULL,'N',4);
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f014-4f01-8e15-000000000001','ReviewNotes','Review Notes',140,'Y','N','N',NULL,'N',3);
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f015-4f01-8e15-000000000001','IsFollowUpRequired','Follow-Up Required',150,'Y');
  -- IsActive required on tab for WebUI editability (GridField context)
  -- UU f030 — do not reuse f018 (reserved for Processing in 11-fix-processing-column.sql)
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f030-4f01-8e15-000000000001','IsActive','Active',155,'Y','N','Y',155,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f016-4f01-8e15-000000000001','AD_Org_ID','Organisation',160,'N','Y','N',160,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f017-4f01-8e15-000000000001','ActivityUpdatedAudited','Activity Updated Audited',890,'Y','Y','N',890,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f020-4f01-8e15-000000000001','Created','Created',900,'Y','Y','N',900,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f021-4f01-8e15-000000000001','CreatedBy','Created By',910,'Y','Y','Y',910,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f022-4f01-8e15-000000000001','Updated','Updated',920,'Y','Y','N',920,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02751-f023-4f01-8e15-000000000001','UpdatedBy','Updated By',930,'Y','Y','Y',930,'N');

  -- Runs window
  v_win_run := pg_temp.saw027_window(
    '27a02760-c0d4-4f01-8e15-000000000001',
    'Activity Audit Runs',
    'Nightly and historical Activity Audit process run log');
  SELECT ad_table_id INTO v_tid FROM ad_table WHERE tablename = 'AbERP_ActivityAuditRunt';
  v_tab := pg_temp.saw027_tab('27a02761-c0d4-4f01-8e15-000000000001', v_win_run, v_tid, 'Runs', 10);
  UPDATE ad_table SET ad_window_id = v_win_run WHERE ad_table_id = v_tid;
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f018-4f01-8e15-000000000001','IsActive','Active',5,'N','N','N',5,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f001-4f01-8e15-000000000001','StartTime','Start Time',10,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f002-4f01-8e15-000000000001','EndTime','End Time',20,'Y','Y','Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f003-4f01-8e15-000000000001','TriggerType','Trigger',30,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f004-4f01-8e15-000000000001','PeriodFrom','Period From',40,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f005-4f01-8e15-000000000001','PeriodTo','Period To',50,'Y','N','Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f006-4f01-8e15-000000000001','ActivitiesIdentified','Identified',60,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f007-4f01-8e15-000000000001','ActivitiesSkipped','Skipped',70,'Y','N','Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f008-4f01-8e15-000000000001','ActivitiesProcessed','Processed',80,'Y','N','Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f009-4f01-8e15-000000000001','ActivitiesNoMatch','No Match',90,'Y','N','Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f010-4f01-8e15-000000000001','ReviewsCreated','Reviews Created',100,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f011-4f01-8e15-000000000001','ReviewsReopened','Reopened',110,'Y','N','Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f012-4f01-8e15-000000000001','ErrorCount','Errors',120,'Y','N','Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f013-4f01-8e15-000000000001','SummaryMsg','Summary',130,'Y','Y','N',NULL,'Y',3);
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f014-4f01-8e15-000000000001','Created','Created',900,'Y','Y','N',900,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f015-4f01-8e15-000000000001','CreatedBy','Created By',910,'Y','Y','Y',910,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f016-4f01-8e15-000000000001','Updated','Updated',920,'Y','Y','N',920,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02761-f017-4f01-8e15-000000000001','UpdatedBy','Updated By',930,'Y','Y','Y',930,'N');

  RAISE NOTICE 'SAW027 windows ready — run 14-format-audit-fieldgroup.sql for Audit field group wiring';
END $$;
