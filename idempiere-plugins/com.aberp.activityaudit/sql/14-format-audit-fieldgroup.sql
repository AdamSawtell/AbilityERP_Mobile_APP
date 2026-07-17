-- =============================================================================
-- SAW027 — Format Activity Audit windows (AbilityERP core practice)
-- - Hide Organisation on form + grid
-- - Created / Created By / Updated / Updated By in collapsible Audit field group
-- - Match Ab_ERP Audit group layout (xposition 1 / 4 pairs)
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw027_ensure_field(
  p_tab_id INTEGER, p_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_seqno INTEGER, p_displayed CHAR, p_readonly CHAR,
  p_sameline CHAR, p_gridseq INTEGER, p_displayedgrid CHAR,
  p_fieldgroup_id INTEGER, p_xposition INTEGER, p_columnspan INTEGER
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
    RAISE NOTICE 'SAW027-14 skip % — column missing', p_columnname;
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
      p_displayedgrid, COALESCE(p_gridseq, p_seqno), p_xposition, p_columnspan, 1,
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
      ad_fieldgroup_id = p_fieldgroup_id,
      ad_field_uu = COALESCE(ad_field_uu, p_uu),
      updated = NOW()
    WHERE ad_field_id = v_field_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_fg_audit INTEGER;
  v_tab INTEGER;
BEGIN
  -- Prefer Ab_ERP Audit field group (collapsible, collapsed by default)
  SELECT ad_fieldgroup_id INTO v_fg_audit
  FROM ad_fieldgroup
  WHERE ad_fieldgroup_uu = '3551f0df-bb72-40ab-8b1c-c28a7fec9a46';
  IF v_fg_audit IS NULL THEN
    SELECT ad_fieldgroup_id INTO v_fg_audit
    FROM ad_fieldgroup
    WHERE name = 'Audit' AND entitytype = 'Ab_ERP'
    ORDER BY ad_fieldgroup_id
    LIMIT 1;
  END IF;
  IF v_fg_audit IS NULL THEN
    SELECT ad_fieldgroup_id INTO v_fg_audit
    FROM ad_fieldgroup
    WHERE name = 'Audit'
    ORDER BY ad_fieldgroup_id
    LIMIT 1;
  END IF;
  IF v_fg_audit IS NULL THEN
    RAISE EXCEPTION 'SAW027-14: Audit field group missing';
  END IF;

  --------------------------------------------------------------------------
  -- Activity Audit Terms (Audit Terms tab)
  --------------------------------------------------------------------------
  SELECT ad_tab_id INTO v_tab FROM ad_tab WHERE ad_tab_uu = '27a02741-c0d4-4f01-8e15-000000000001';
  IF v_tab IS NULL THEN
    SELECT t.ad_tab_id INTO v_tab
    FROM ad_tab t JOIN ad_window w ON w.ad_window_id = t.ad_window_id
    WHERE w.name = 'Activity Audit Terms' AND t.name = 'Audit Terms' LIMIT 1;
  END IF;
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'SAW027-14: Audit Terms tab missing';
  END IF;

  -- Hide Organisation (form + grid)
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02741-f001-4f01-8e15-000000000001',
    'AD_Org_ID','Organisation',10,'N','Y','N',10,'N', NULL, 1, 2);

  -- Main fields (tidy pairs)
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02741-f002-4f01-8e15-000000000001',
    'AuditWord','Audit Word or Phrase',20,'Y','N','N',20,'Y', NULL, 1, 5);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02741-f003-4f01-8e15-000000000001',
    'Description','Description',30,'Y','N','N',30,'Y', NULL, 1, 5);
  UPDATE ad_field SET numlines = 3, updated = NOW()
  WHERE ad_field_uu = '27a02741-f003-4f01-8e15-000000000001';
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02741-f004-4f01-8e15-000000000001',
    'Category','Category',40,'Y','N','N',40,'Y', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02741-f005-4f01-8e15-000000000001',
    'RiskLevel','Risk Level',50,'Y','N','Y',50,'Y', NULL, 4, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02741-f006-4f01-8e15-000000000001',
    'MatchType','Match Type',60,'Y','N','N',60,'Y', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02741-f007-4f01-8e15-000000000001',
    'IsActive','Active',70,'Y','N','Y',70,'Y', NULL, 4, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02741-f008-4f01-8e15-000000000001',
    'ValidFrom','Effective From',80,'Y','N','N',80,'Y', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02741-f009-4f01-8e15-000000000001',
    'ValidTo','Effective To',90,'Y','N','Y',90,'Y', NULL, 4, 2);

  -- Audit group at bottom (form only — keep grid clean)
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02741-f010-4f01-8e15-000000000001',
    'Created','Created',900,'Y','Y','N',900,'N', v_fg_audit, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02741-f011-4f01-8e15-000000000001',
    'CreatedBy','Created By',910,'Y','Y','Y',910,'N', v_fg_audit, 4, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02741-f012-4f01-8e15-000000000001',
    'Updated','Updated',920,'Y','Y','N',920,'N', v_fg_audit, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02741-f013-4f01-8e15-000000000001',
    'UpdatedBy','Updated By',930,'Y','Y','Y',930,'N', v_fg_audit, 4, 2);

  UPDATE ad_tab SET
    orderbyclause = 'AuditWord, AbERP_ActivityAuditTerm_ID',
    updated = NOW()
  WHERE ad_tab_id = v_tab;

  --------------------------------------------------------------------------
  -- Activity Audit Review (Reviews tab)
  --------------------------------------------------------------------------
  SELECT ad_tab_id INTO v_tab FROM ad_tab WHERE ad_tab_uu = '27a02751-c0d4-4f01-8e15-000000000001';
  IF v_tab IS NULL THEN
    SELECT t.ad_tab_id INTO v_tab
    FROM ad_tab t JOIN ad_window w ON w.ad_window_id = t.ad_window_id
    WHERE w.name = 'Activity Audit Review' AND t.name = 'Reviews' LIMIT 1;
  END IF;
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'SAW027-14: Reviews tab missing';
  END IF;

  -- Hide Organisation
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f016-4f01-8e15-000000000001',
    'AD_Org_ID','Organisation',160,'N','Y','N',160,'N', NULL, 1, 2);

  -- Tidy main review fields (pairs)
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f001-4f01-8e15-000000000001',
    'ActivityDate','Activity Date',10,'Y','Y','N',10,'Y', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f019-4f01-8e15-000000000001',
    'AbERP_OpenActivity','Open Activity',15,'Y','N','Y',15,'Y', NULL, 4, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f002-4f01-8e15-000000000001',
    'C_BPartner_ID','Client',20,'Y','Y','N',20,'Y', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f003-4f01-8e15-000000000001',
    'AD_User_ID','Employee',30,'Y','Y','Y',30,'Y', NULL, 4, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f004-4f01-8e15-000000000001',
    'ContactActivityType','Activity Type',40,'Y','Y','N',40,'Y', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f005-4f01-8e15-000000000001',
    'MatchedTerms','Matched Terms',50,'Y','Y','N',50,'Y', NULL, 1, 5);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f006-4f01-8e15-000000000001',
    'Category','Category',60,'Y','Y','N',60,'Y', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f007-4f01-8e15-000000000001',
    'HighestRiskLevel','Risk Level',70,'Y','Y','Y',70,'Y', NULL, 4, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f008-4f01-8e15-000000000001',
    'ReviewStatus','Review Status',80,'Y','N','N',80,'Y', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f009-4f01-8e15-000000000001',
    'IsReviewed','Reviewed',90,'Y','N','Y',90,'Y', NULL, 4, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f010-4f01-8e15-000000000001',
    'ReviewedBy','Reviewed By',100,'Y','Y','N',100,'Y', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f011-4f01-8e15-000000000001',
    'ReviewedDate','Reviewed Date',110,'Y','Y','Y',110,'Y', NULL, 4, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f013-4f01-8e15-000000000001',
    'MatchedExtract','Matched Text Extract',130,'Y','Y','N',130,'N', NULL, 1, 5);
  UPDATE ad_field SET numlines = 4, updated = NOW()
  WHERE ad_field_uu = '27a02751-f013-4f01-8e15-000000000001';
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f014-4f01-8e15-000000000001',
    'ReviewNotes','Review Notes',140,'Y','N','N',140,'N', NULL, 1, 5);
  UPDATE ad_field SET numlines = 3, updated = NOW()
  WHERE ad_field_uu = '27a02751-f014-4f01-8e15-000000000001';
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f015-4f01-8e15-000000000001',
    'IsFollowUpRequired','Follow-Up Required',150,'Y','N','N',150,'Y', NULL, 1, 2);

  -- Keep Open Activity button usable in form + grid
  UPDATE ad_field SET istoolbarbutton = 'B', isreadonly = 'N', updated = NOW()
  WHERE ad_field_uu = '27a02751-f019-4f01-8e15-000000000001';

  -- Audit group
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f017-4f01-8e15-000000000001',
    'ActivityUpdatedAudited','Activity Updated Audited',890,'Y','Y','N',890,'N', v_fg_audit, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f020-4f01-8e15-000000000001',
    'Created','Created',900,'Y','Y','N',900,'N', v_fg_audit, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f021-4f01-8e15-000000000001',
    'CreatedBy','Created By',910,'Y','Y','Y',910,'N', v_fg_audit, 4, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f022-4f01-8e15-000000000001',
    'Updated','Updated',920,'Y','Y','N',920,'N', v_fg_audit, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02751-f023-4f01-8e15-000000000001',
    'UpdatedBy','Updated By',930,'Y','Y','Y',930,'N', v_fg_audit, 4, 2);

  --------------------------------------------------------------------------
  -- Activity Audit Runs (Runs tab)
  --------------------------------------------------------------------------
  SELECT ad_tab_id INTO v_tab FROM ad_tab WHERE ad_tab_uu = '27a02761-c0d4-4f01-8e15-000000000001';
  IF v_tab IS NULL THEN
    SELECT t.ad_tab_id INTO v_tab
    FROM ad_tab t JOIN ad_window w ON w.ad_window_id = t.ad_window_id
    WHERE w.name = 'Activity Audit Runs' AND t.name = 'Runs' LIMIT 1;
  END IF;
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'SAW027-14: Runs tab missing';
  END IF;

  -- Hide Organisation if/when present
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f000-4f01-8e15-000000000001',
    'AD_Org_ID','Organisation',5,'N','Y','N',5,'N', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f00c-4f01-8e15-000000000001',
    'AbERP_ActivityAuditRunt_ID','Activity Audit Run',0,'N','Y','N',0,'N', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f00d-4f01-8e15-000000000001',
    'AD_Client_ID','Client',2,'N','Y','N',2,'N', NULL, 1, 2);

  -- Tidy run metrics pairs
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f001-4f01-8e15-000000000001',
    'StartTime','Start Time',10,'Y','Y','N',10,'Y', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f002-4f01-8e15-000000000001',
    'EndTime','End Time',20,'Y','Y','Y',20,'Y', NULL, 4, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f003-4f01-8e15-000000000001',
    'TriggerType','Trigger',30,'Y','Y','N',30,'Y', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f004-4f01-8e15-000000000001',
    'PeriodFrom','Period From',40,'Y','Y','N',40,'Y', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f005-4f01-8e15-000000000001',
    'PeriodTo','Period To',50,'Y','Y','Y',50,'Y', NULL, 4, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f006-4f01-8e15-000000000001',
    'ActivitiesIdentified','Identified',60,'Y','Y','N',60,'Y', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f007-4f01-8e15-000000000001',
    'ActivitiesSkipped','Skipped',70,'Y','Y','Y',70,'Y', NULL, 4, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f008-4f01-8e15-000000000001',
    'ActivitiesProcessed','Processed',80,'Y','Y','N',80,'Y', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f009-4f01-8e15-000000000001',
    'ActivitiesNoMatch','No Match',90,'Y','Y','Y',90,'Y', NULL, 4, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f010-4f01-8e15-000000000001',
    'ReviewsCreated','Reviews Created',100,'Y','Y','N',100,'Y', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f011-4f01-8e15-000000000001',
    'ReviewsReopened','Reopened',110,'Y','Y','Y',110,'Y', NULL, 4, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f012-4f01-8e15-000000000001',
    'ErrorCount','Errors',120,'Y','Y','N',120,'Y', NULL, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f013-4f01-8e15-000000000001',
    'SummaryMsg','Summary',130,'Y','Y','N',130,'Y', NULL, 1, 5);
  UPDATE ad_field SET numlines = 3, isreadonly = 'Y', updated = NOW()
  WHERE ad_field_uu = '27a02761-f013-4f01-8e15-000000000001';

  -- Audit group at bottom
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f014-4f01-8e15-000000000001',
    'Created','Created',900,'Y','Y','N',900,'N', v_fg_audit, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f015-4f01-8e15-000000000001',
    'CreatedBy','Created By',910,'Y','Y','Y',910,'N', v_fg_audit, 4, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f016-4f01-8e15-000000000001',
    'Updated','Updated',920,'Y','Y','N',920,'N', v_fg_audit, 1, 2);
  PERFORM pg_temp.saw027_ensure_field(v_tab,'27a02761-f017-4f01-8e15-000000000001',
    'UpdatedBy','Updated By',930,'Y','Y','Y',930,'N', v_fg_audit, 4, 2);

  UPDATE ad_tab SET issinglerow = 'N', updated = NOW() WHERE ad_tab_id = v_tab;

  RAISE NOTICE 'SAW027-14 formatting applied (Audit fieldgroup=%)', v_fg_audit;
END $$;
