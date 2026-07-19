-- =============================================================================
-- SAW027 — AD Table + Columns
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_table_id),0)+1 FROM ad_table))
WHERE name='AD_Table' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw027_col(
  p_table_id INTEGER, p_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_ref INTEGER, p_ref_value INTEGER, p_mandatory CHAR, p_updateable CHAR,
  p_seqno INTEGER, p_fieldlength INTEGER,
  p_iskey CHAR DEFAULT 'N', p_isparent CHAR DEFAULT 'N', p_isidentifier CHAR DEFAULT 'N',
  p_isselection CHAR DEFAULT 'N', p_default TEXT DEFAULT NULL, p_callout TEXT DEFAULT NULL
) RETURNS void AS $$
DECLARE
  v_col_id INTEGER;
  v_el INTEGER;
BEGIN
  SELECT ad_element_id INTO v_el FROM ad_element WHERE columnname = p_columnname LIMIT 1;
  IF v_el IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_columnname, 'Ab_ERP', p_name, p_name,
      '27a027e0-0000-4000-8000-' || lpad(substr(md5(p_columnname), 1, 12), 12, '0')
    ) RETURNING ad_element_id INTO v_el;
  END IF;

  SELECT ad_column_id INTO v_col_id FROM ad_column WHERE ad_column_uu = p_uu;
  IF v_col_id IS NULL THEN
    SELECT ad_column_id INTO v_col_id FROM ad_column
    WHERE ad_table_id = p_table_id AND columnname = p_columnname;
  END IF;

  IF v_col_id IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, version, entitytype, columnname, ad_table_id,
      ad_reference_id, ad_reference_value_id,
      fieldlength, iskey, isparent, ismandatory, isupdateable,
      isidentifier, seqno, istranslated, isencrypted, isselectioncolumn,
      ad_element_id, issyncdatabase, isalwaysupdateable,
      isallowcopy, defaultvalue, callout, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, 0, 'Ab_ERP', p_columnname, p_table_id,
      p_ref, p_ref_value,
      p_fieldlength, p_iskey, p_isparent, p_mandatory, p_updateable,
      p_isidentifier, p_seqno, 'N', 'N', p_isselection,
      v_el, 'Y', 'N',
      'Y', p_default, p_callout, p_uu
    );
  ELSE
    UPDATE ad_column SET
      name = p_name,
      ad_reference_id = p_ref,
      ad_reference_value_id = p_ref_value,
      fieldlength = p_fieldlength,
      ismandatory = p_mandatory,
      isupdateable = p_updateable,
      isidentifier = p_isidentifier,
      iskey = p_iskey,
      isparent = p_isparent,
      isselectioncolumn = p_isselection,
      defaultvalue = COALESCE(p_default, defaultvalue),
      callout = COALESCE(p_callout, callout),
      entitytype = 'Ab_ERP',
      ad_column_uu = COALESCE(ad_column_uu, p_uu),
      updated = NOW()
    WHERE ad_column_id = v_col_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw027_table(
  p_uu TEXT, p_tablename TEXT, p_name TEXT, p_changelog CHAR DEFAULT 'N'
) RETURNS INTEGER AS $$
DECLARE
  v_id INTEGER;
BEGIN
  SELECT ad_table_id INTO v_id FROM ad_table WHERE ad_table_uu = p_uu;
  IF v_id IS NULL THEN
    SELECT ad_table_id INTO v_id FROM ad_table WHERE tablename = p_tablename;
  END IF;

  IF v_id IS NULL THEN
    INSERT INTO ad_table (
      ad_table_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, tablename,
      isview, accesslevel, entitytype, issecurityenabled,
      isdeleteable, ishighvolume, importtable, ischangelog,
      replicationtype, ad_table_uu, iscentrallymaintained
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Table' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, p_name, p_tablename,
      'N', '3', 'Ab_ERP', 'N',
      'Y', 'N', 'N', p_changelog,
      'L', p_uu, 'Y'
    ) RETURNING ad_table_id INTO v_id;
  ELSE
    UPDATE ad_table SET
      name = p_name, tablename = p_tablename, entitytype = 'Ab_ERP',
      ischangelog = p_changelog,
      ad_table_uu = COALESCE(ad_table_uu, p_uu), isactive = 'Y', updated = NOW()
    WHERE ad_table_id = v_id;
  END IF;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_term INTEGER;
  v_taud INTEGER;
  v_proc INTEGER;
  v_rev INTEGER;
  v_runt INTEGER;
  v_mt INTEGER;
  v_rl INTEGER;
  v_cat INTEGER;
  v_rs INTEGER;
  v_ar INTEGER;
  v_tr INTEGER;
  v_ca_ref INTEGER;
BEGIN
  SELECT ad_reference_id INTO v_mt FROM ad_reference
  WHERE ad_reference_uu = '27a02720-c0d4-4f01-8e15-000000000001' OR name = 'AbERP_ActivityAudit_MatchType' LIMIT 1;
  SELECT ad_reference_id INTO v_rl FROM ad_reference
  WHERE ad_reference_uu = '27a02721-c0d4-4f01-8e15-000000000001' OR name = 'AbERP_ActivityAudit_RiskLevel' LIMIT 1;
  SELECT ad_reference_id INTO v_cat FROM ad_reference
  WHERE ad_reference_uu = '27a02722-c0d4-4f01-8e15-000000000001' OR name = 'AbERP_ActivityAudit_Category' LIMIT 1;
  SELECT ad_reference_id INTO v_rs FROM ad_reference
  WHERE ad_reference_uu = '27a02723-c0d4-4f01-8e15-000000000001' OR name = 'AbERP_ActivityAudit_ReviewStatus' LIMIT 1;
  SELECT ad_reference_id INTO v_ar FROM ad_reference
  WHERE ad_reference_uu = '27a02724-c0d4-4f01-8e15-000000000001' OR name = 'AbERP_ActivityAudit_Result' LIMIT 1;
  SELECT ad_reference_id INTO v_tr FROM ad_reference
  WHERE ad_reference_uu = '27a02725-c0d4-4f01-8e15-000000000001' OR name = 'AbERP_ActivityAudit_Trigger' LIMIT 1;
  IF v_mt IS NULL OR v_rl IS NULL OR v_cat IS NULL OR v_rs IS NULL OR v_ar IS NULL OR v_tr IS NULL THEN
    RAISE EXCEPTION 'SAW027: list references missing — run 02 first';
  END IF;

  -- Table reference for C_ContactActivity (Search)
  SELECT r.ad_reference_id INTO v_ca_ref
  FROM ad_reference r
  JOIN ad_ref_table rt ON rt.ad_reference_id = r.ad_reference_id
  JOIN ad_table t ON t.ad_table_id = rt.ad_table_id
  WHERE t.tablename = 'C_ContactActivity'
  LIMIT 1;
  IF v_ca_ref IS NULL THEN
    -- fallback: create Table reference
    INSERT INTO ad_reference (
      ad_reference_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, validationtype, entitytype, ad_reference_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Reference' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_C_ContactActivity', 'Contact Activity search', 'T', 'Ab_ERP',
      '27a02726-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_reference_id INTO v_ca_ref;

    INSERT INTO ad_ref_table (
      ad_reference_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      ad_table_id, ad_key, ad_display, isvaluedisplayed, entitytype, ad_ref_table_uu
    )
    SELECT v_ca_ref, 0, 0, 'Y', NOW(), 100, NOW(), 100,
      t.ad_table_id,
      (SELECT ad_column_id FROM ad_column WHERE ad_table_id = t.ad_table_id AND columnname = 'C_ContactActivity_ID'),
      (SELECT ad_column_id FROM ad_column WHERE ad_table_id = t.ad_table_id AND columnname = 'Description'),
      'N', 'Ab_ERP', '27a02726-t001-4f01-8e15-000000000001'
    FROM ad_table t WHERE t.tablename = 'C_ContactActivity';
  END IF;

  v_term := pg_temp.saw027_table('27a02701-c0d4-4f01-8e15-000000000001', 'AbERP_ActivityAuditTerm', 'Activity Audit Term', 'Y');
  v_taud := pg_temp.saw027_table('27a02702-c0d4-4f01-8e15-000000000001', 'AbERP_ActivityAuditTermAudit', 'Activity Audit Term Change', 'N');
  v_proc := pg_temp.saw027_table('27a02703-c0d4-4f01-8e15-000000000001', 'AbERP_ActivityAuditProc', 'Activity Audit Processing', 'N');
  v_rev  := pg_temp.saw027_table('27a02704-c0d4-4f01-8e15-000000000001', 'AbERP_ActivityAuditReview', 'Activity Audit Review', 'Y');
  v_runt := pg_temp.saw027_table('27a02705-c0d4-4f01-8e15-000000000001', 'AbERP_ActivityAuditRunt', 'Activity Audit Run', 'N');

  -- Term
  PERFORM pg_temp.saw027_col(v_term,'27a02701-c001-4f01-8e15-000000000001','AbERP_ActivityAuditTerm_ID','Activity Audit Term',13,NULL,'Y','N',0,10,'Y','N','Y');
  PERFORM pg_temp.saw027_col(v_term,'27a02701-c002-4f01-8e15-000000000001','AD_Client_ID','Client',19,NULL,'Y','N',10,10);
  PERFORM pg_temp.saw027_col(v_term,'27a02701-c003-4f01-8e15-000000000001','AD_Org_ID','Organisation',19,NULL,'Y','Y',20,10);
  PERFORM pg_temp.saw027_col(v_term,'27a02701-c004-4f01-8e15-000000000001','IsActive','Active',20,NULL,'Y','Y',30,1,'N','N','N','N','Y');
  PERFORM pg_temp.saw027_col(v_term,'27a02701-c005-4f01-8e15-000000000001','Created','Created',16,NULL,'Y','N',40,7);
  PERFORM pg_temp.saw027_col(v_term,'27a02701-c006-4f01-8e15-000000000001','CreatedBy','Created By',18,110,'Y','N',50,10);
  PERFORM pg_temp.saw027_col(v_term,'27a02701-c007-4f01-8e15-000000000001','Updated','Updated',16,NULL,'Y','N',60,7);
  PERFORM pg_temp.saw027_col(v_term,'27a02701-c008-4f01-8e15-000000000001','UpdatedBy','Updated By',18,110,'Y','N',70,10);
  PERFORM pg_temp.saw027_col(v_term,'27a02701-c009-4f01-8e15-000000000001','AbERP_ActivityAuditTerm_UU','UUID',10,NULL,'N','N',80,36);
  PERFORM pg_temp.saw027_col(v_term,'27a02701-c010-4f01-8e15-000000000001','AuditWord','Audit Word or Phrase',10,NULL,'Y','Y',90,255,'N','N','Y','Y');
  PERFORM pg_temp.saw027_col(v_term,'27a02701-c011-4f01-8e15-000000000001','Description','Description',14,NULL,'N','Y',100,500);
  PERFORM pg_temp.saw027_col(v_term,'27a02701-c012-4f01-8e15-000000000001','Category','Category',17,v_cat,'Y','Y',110,2,'N','N','N','Y','OT');
  PERFORM pg_temp.saw027_col(v_term,'27a02701-c013-4f01-8e15-000000000001','RiskLevel','Risk Level',17,v_rl,'Y','Y',120,2,'N','N','N','Y','MD');
  PERFORM pg_temp.saw027_col(v_term,'27a02701-c014-4f01-8e15-000000000001','MatchType','Match Type',17,v_mt,'Y','Y',130,2,'N','N','N','Y','EW');
  PERFORM pg_temp.saw027_col(v_term,'27a02701-c015-4f01-8e15-000000000001','ValidFrom','Effective From',16,NULL,'N','Y',140,7);
  PERFORM pg_temp.saw027_col(v_term,'27a02701-c016-4f01-8e15-000000000001','ValidTo','Effective To',16,NULL,'N','Y',150,7);

  -- Term audit
  PERFORM pg_temp.saw027_col(v_taud,'27a02702-c001-4f01-8e15-000000000001','AbERP_ActivityAuditTermAudit_ID','Term Change',13,NULL,'Y','N',0,10,'Y');
  PERFORM pg_temp.saw027_col(v_taud,'27a02702-c002-4f01-8e15-000000000001','AD_Client_ID','Client',19,NULL,'Y','N',10,10);
  PERFORM pg_temp.saw027_col(v_taud,'27a02702-c003-4f01-8e15-000000000001','AD_Org_ID','Organisation',19,NULL,'Y','N',20,10);
  PERFORM pg_temp.saw027_col(v_taud,'27a02702-c004-4f01-8e15-000000000001','IsActive','Active',20,NULL,'Y','Y',30,1,'N','N','N','N','Y');
  PERFORM pg_temp.saw027_col(v_taud,'27a02702-c005-4f01-8e15-000000000001','Created','Created',16,NULL,'Y','N',40,7);
  PERFORM pg_temp.saw027_col(v_taud,'27a02702-c006-4f01-8e15-000000000001','CreatedBy','Created By',18,110,'Y','N',50,10);
  PERFORM pg_temp.saw027_col(v_taud,'27a02702-c007-4f01-8e15-000000000001','Updated','Updated',16,NULL,'Y','N',60,7);
  PERFORM pg_temp.saw027_col(v_taud,'27a02702-c008-4f01-8e15-000000000001','UpdatedBy','Updated By',18,110,'Y','N',70,10);
  PERFORM pg_temp.saw027_col(v_taud,'27a02702-c009-4f01-8e15-000000000001','AbERP_ActivityAuditTermAudit_UU','UUID',10,NULL,'N','N',80,36);
  PERFORM pg_temp.saw027_col(v_taud,'27a02702-c010-4f01-8e15-000000000001','AbERP_ActivityAuditTerm_ID','Activity Audit Term',19,NULL,'Y','N',90,10,'N','Y');
  PERFORM pg_temp.saw027_col(v_taud,'27a02702-c011-4f01-8e15-000000000001','FieldName','Field',10,NULL,'N','N',100,60);
  PERFORM pg_temp.saw027_col(v_taud,'27a02702-c012-4f01-8e15-000000000001','ChangeType','Change Type',10,NULL,'N','N',110,40);
  PERFORM pg_temp.saw027_col(v_taud,'27a02702-c013-4f01-8e15-000000000001','OldValue','Previous Value',14,NULL,'N','N',120,2000);
  PERFORM pg_temp.saw027_col(v_taud,'27a02702-c014-4f01-8e15-000000000001','NewValue','New Value',14,NULL,'N','N',130,2000);
  PERFORM pg_temp.saw027_col(v_taud,'27a02702-c015-4f01-8e15-000000000001','ChangedBy','Changed By',18,110,'N','N',140,10);
  PERFORM pg_temp.saw027_col(v_taud,'27a02702-c016-4f01-8e15-000000000001','ChangedDate','Changed Date',16,NULL,'Y','N',150,7);

  -- Proc
  PERFORM pg_temp.saw027_col(v_proc,'27a02703-c001-4f01-8e15-000000000001','AbERP_ActivityAuditProc_ID','Activity Audit Processing',13,NULL,'Y','N',0,10,'Y');
  PERFORM pg_temp.saw027_col(v_proc,'27a02703-c002-4f01-8e15-000000000001','AD_Client_ID','Client',19,NULL,'Y','N',10,10);
  PERFORM pg_temp.saw027_col(v_proc,'27a02703-c003-4f01-8e15-000000000001','AD_Org_ID','Organisation',19,NULL,'Y','N',20,10);
  PERFORM pg_temp.saw027_col(v_proc,'27a02703-c004-4f01-8e15-000000000001','IsActive','Active',20,NULL,'Y','Y',30,1,'N','N','N','N','Y');
  PERFORM pg_temp.saw027_col(v_proc,'27a02703-c005-4f01-8e15-000000000001','Created','Created',16,NULL,'Y','N',40,7);
  PERFORM pg_temp.saw027_col(v_proc,'27a02703-c006-4f01-8e15-000000000001','CreatedBy','Created By',18,110,'Y','N',50,10);
  PERFORM pg_temp.saw027_col(v_proc,'27a02703-c007-4f01-8e15-000000000001','Updated','Updated',16,NULL,'Y','N',60,7);
  PERFORM pg_temp.saw027_col(v_proc,'27a02703-c008-4f01-8e15-000000000001','UpdatedBy','Updated By',18,110,'Y','N',70,10);
  PERFORM pg_temp.saw027_col(v_proc,'27a02703-c009-4f01-8e15-000000000001','AbERP_ActivityAuditProc_UU','UUID',10,NULL,'N','N',80,36);
  PERFORM pg_temp.saw027_col(v_proc,'27a02703-c010-4f01-8e15-000000000001','C_ContactActivity_ID','Activity',30,v_ca_ref,'Y','N',90,10,'N','N','Y','Y');
  PERFORM pg_temp.saw027_col(v_proc,'27a02703-c011-4f01-8e15-000000000001','ActivityUpdated','Activity Updated Timestamp',16,NULL,'Y','N',100,7);
  PERFORM pg_temp.saw027_col(v_proc,'27a02703-c012-4f01-8e15-000000000001','LastAudited','Last Audited',16,NULL,'Y','N',110,7);
  PERFORM pg_temp.saw027_col(v_proc,'27a02703-c013-4f01-8e15-000000000001','AuditResult','Audit Result',17,v_ar,'Y','N',120,2);
  PERFORM pg_temp.saw027_col(v_proc,'27a02703-c014-4f01-8e15-000000000001','MatchedTerms','Matched Terms',14,NULL,'N','N',130,2000);
  PERFORM pg_temp.saw027_col(v_proc,'27a02703-c015-4f01-8e15-000000000001','TermsApplied','Terms Applied',14,NULL,'N','N',140,2000);

  -- Review
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c001-4f01-8e15-000000000001','AbERP_ActivityAuditReview_ID','Activity Audit Review',13,NULL,'Y','N',0,10,'Y');
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c002-4f01-8e15-000000000001','AD_Client_ID','Client',19,NULL,'Y','N',10,10);
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c003-4f01-8e15-000000000001','AD_Org_ID','Organisation',19,NULL,'Y','N',20,10);
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c004-4f01-8e15-000000000001','IsActive','Active',20,NULL,'Y','Y',30,1,'N','N','N','N','Y');
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c005-4f01-8e15-000000000001','Created','Created',16,NULL,'Y','N',40,7);
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c006-4f01-8e15-000000000001','CreatedBy','Created By',18,110,'Y','N',50,10);
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c007-4f01-8e15-000000000001','Updated','Updated',16,NULL,'Y','N',60,7);
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c008-4f01-8e15-000000000001','UpdatedBy','Updated By',18,110,'Y','N',70,10);
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c009-4f01-8e15-000000000001','AbERP_ActivityAuditReview_UU','UUID',10,NULL,'N','N',80,36);
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c010-4f01-8e15-000000000001','C_ContactActivity_ID','Activity',30,v_ca_ref,'Y','N',90,10,'N','N','Y','Y');
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c011-4f01-8e15-000000000001','ActivityDate','Activity Date',16,NULL,'N','N',100,7,'N','N','N','Y');
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c012-4f01-8e15-000000000001','C_BPartner_ID','Client / Participant',19,NULL,'N','N',110,10,'N','N','N','Y');
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c013-4f01-8e15-000000000001','AD_User_ID','Employee',19,NULL,'N','N',120,10,'N','N','N','Y');
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c014-4f01-8e15-000000000001','ContactActivityType','Activity Type',10,NULL,'N','N',130,10,'N','N','N','Y');
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c015-4f01-8e15-000000000001','MatchedTerms','Matched Words or Phrases',14,NULL,'N','N',140,2000);
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c016-4f01-8e15-000000000001','MatchedExtract','Matched Text Extract',14,NULL,'N','N',150,4000);
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c017-4f01-8e15-000000000001','Category','Category',17,v_cat,'N','N',160,2,'N','N','N','Y');
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c018-4f01-8e15-000000000001','HighestRiskLevel','Highest Risk Level',17,v_rl,'N','N',170,2,'N','N','N','Y');
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c019-4f01-8e15-000000000001','ReviewStatus','Review Status',17,v_rs,'Y','Y',180,2,'N','N','N','Y','NW');
  -- Callout via IColumnCalloutFactory only (do not set classic AD_Column.Callout — OSGi ClassNotFound)
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c020-4f01-8e15-000000000001','IsReviewed','Reviewed',20,NULL,'Y','Y',190,1,'N','N','N','Y','N',
    NULL);
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c021-4f01-8e15-000000000001','ReviewedBy','Reviewed By',18,110,'N','N',200,10);
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c022-4f01-8e15-000000000001','ReviewedDate','Reviewed Date',16,NULL,'N','N',210,7);
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c023-4f01-8e15-000000000001','ReviewNotes','Review Notes',14,NULL,'N','Y',220,2000);
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c024-4f01-8e15-000000000001','IsFollowUpRequired','Follow-Up Required',20,NULL,'N','Y',230,1,'N','N','N','N','N');
  PERFORM pg_temp.saw027_col(v_rev,'27a02704-c025-4f01-8e15-000000000001','ActivityUpdatedAudited','Activity Updated Timestamp Audited',16,NULL,'N','N',240,7);

  -- Run
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c001-4f01-8e15-000000000001','AbERP_ActivityAuditRunt_ID','Activity Audit Run',13,NULL,'Y','N',0,10,'Y');
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c002-4f01-8e15-000000000001','AD_Client_ID','Client',19,NULL,'Y','N',10,10);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c003-4f01-8e15-000000000001','AD_Org_ID','Organisation',19,NULL,'Y','N',20,10);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c004-4f01-8e15-000000000001','IsActive','Active',20,NULL,'Y','Y',30,1,'N','N','N','N','Y');
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c005-4f01-8e15-000000000001','Created','Created',16,NULL,'Y','N',40,7);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c006-4f01-8e15-000000000001','CreatedBy','Created By',18,110,'Y','N',50,10);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c007-4f01-8e15-000000000001','Updated','Updated',16,NULL,'Y','N',60,7);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c008-4f01-8e15-000000000001','UpdatedBy','Updated By',18,110,'Y','N',70,10);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c009-4f01-8e15-000000000001','AbERP_ActivityAuditRunt_UU','UUID',10,NULL,'N','N',80,36);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c010-4f01-8e15-000000000001','StartTime','Start Time',16,NULL,'Y','N',90,7);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c011-4f01-8e15-000000000001','EndTime','End Time',16,NULL,'N','N',100,7);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c012-4f01-8e15-000000000001','PeriodFrom','Period From',16,NULL,'N','N',110,7);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c013-4f01-8e15-000000000001','PeriodTo','Period To',16,NULL,'N','N',120,7);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c014-4f01-8e15-000000000001','TriggerType','Trigger',17,v_tr,'Y','N',130,2);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c015-4f01-8e15-000000000001','OrgsProcessed','Organisations Processed',14,NULL,'N','N',140,500);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c016-4f01-8e15-000000000001','ActivitiesIdentified','Activities Identified',11,NULL,'N','N',150,10);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c017-4f01-8e15-000000000001','ActivitiesSkipped','Activities Skipped',11,NULL,'N','N',160,10);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c018-4f01-8e15-000000000001','ActivitiesProcessed','Activities Processed',11,NULL,'N','N',170,10);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c019-4f01-8e15-000000000001','ActivitiesNoMatch','Activities No Match',11,NULL,'N','N',180,10);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c020-4f01-8e15-000000000001','ReviewsCreated','Reviews Created',11,NULL,'N','N',190,10);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c021-4f01-8e15-000000000001','ReviewsReopened','Reviews Reopened',11,NULL,'N','N',200,10);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c022-4f01-8e15-000000000001','TermsAppliedCount','Terms Applied',11,NULL,'N','N',210,10);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c023-4f01-8e15-000000000001','ErrorCount','Errors',11,NULL,'N','N',220,10);
  PERFORM pg_temp.saw027_col(v_runt,'27a02705-c024-4f01-8e15-000000000001','SummaryMsg','Summary',14,NULL,'N','N',230,2000);

  RAISE NOTICE 'SAW027 AD tables/columns ready';
END $$;
