-- =============================================================================
-- SAW023 — AD Table + Columns (Rule / Result / Snapshot)
-- Rule UU:     23a02301-c0d4-4f01-8e15-000000000001
-- Result UU:   23a02302-c0d4-4f01-8e15-000000000001
-- Snapshot UU: 23a02303-c0d4-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_table_id),0)+1 FROM ad_table))
WHERE name='AD_Table' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw023_col(
  p_table_id INTEGER, p_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_ref INTEGER, p_ref_value INTEGER, p_mandatory CHAR, p_updateable CHAR,
  p_seqno INTEGER, p_fieldlength INTEGER,
  p_iskey CHAR DEFAULT 'N', p_isparent CHAR DEFAULT 'N', p_isidentifier CHAR DEFAULT 'N',
  p_isselection CHAR DEFAULT 'N', p_default TEXT DEFAULT NULL
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
      '23a023e0-0000-4000-8000-' || lpad(substr(md5(p_columnname), 1, 12), 12, '0')
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
      isallowcopy, defaultvalue, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, 0, 'Ab_ERP', p_columnname, p_table_id,
      p_ref, p_ref_value,
      p_fieldlength, p_iskey, p_isparent, p_mandatory, p_updateable,
      p_isidentifier, p_seqno, 'N', 'N', p_isselection,
      v_el, 'Y', 'N',
      'Y', p_default, p_uu
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
      entitytype = 'Ab_ERP',
      ad_column_uu = COALESCE(ad_column_uu, p_uu),
      updated = NOW()
    WHERE ad_column_id = v_col_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw023_table(
  p_uu TEXT, p_tablename TEXT, p_name TEXT, p_isview CHAR DEFAULT 'N'
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
      p_isview, '3', 'Ab_ERP', 'N',
      CASE WHEN p_isview='Y' THEN 'N' ELSE 'Y' END, 'N', 'N', 'Y',
      'L', p_uu, 'Y'
    ) RETURNING ad_table_id INTO v_id;
  ELSE
    UPDATE ad_table SET
      name = p_name,
      tablename = p_tablename,
      isview = p_isview,
      entitytype = 'Ab_ERP',
      ad_table_uu = COALESCE(ad_table_uu, p_uu),
      isactive = 'Y',
      updated = NOW()
    WHERE ad_table_id = v_id;
  END IF;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_rule_id INTEGER;
  v_result_id INTEGER;
  v_snap_id INTEGER;
  v_cat INTEGER;
  v_sev INTEGER;
  v_sts INTEGER;
  v_tl INTEGER;
BEGIN
  SELECT ad_reference_id INTO v_cat FROM ad_reference
  WHERE ad_reference_uu = '23a02320-c0d4-4f01-8e15-000000000001' OR name = 'AbERP_ComplianceCategory' LIMIT 1;
  SELECT ad_reference_id INTO v_sev FROM ad_reference
  WHERE ad_reference_uu = '23a02321-c0d4-4f01-8e15-000000000001' OR name = 'AbERP_Severity' LIMIT 1;
  SELECT ad_reference_id INTO v_sts FROM ad_reference
  WHERE ad_reference_uu = '23a02322-c0d4-4f01-8e15-000000000001' OR name = 'AbERP_ComplianceStatus' LIMIT 1;
  SELECT ad_reference_id INTO v_tl FROM ad_reference
  WHERE ad_reference_uu = '23a02323-c0d4-4f01-8e15-000000000001' OR name = 'AbERP_TrafficLight' LIMIT 1;
  IF v_cat IS NULL OR v_sev IS NULL OR v_sts IS NULL OR v_tl IS NULL THEN
    RAISE EXCEPTION 'SAW023: list references missing — run 02 first';
  END IF;

  v_rule_id := pg_temp.saw023_table(
    '23a02301-c0d4-4f01-8e15-000000000001', 'AbERP_ComplianceRule', 'Compliance Rule', 'N');
  v_result_id := pg_temp.saw023_table(
    '23a02302-c0d4-4f01-8e15-000000000001', 'AbERP_ComplianceResult', 'Compliance Result', 'N');
  v_snap_id := pg_temp.saw023_table(
    '23a02303-c0d4-4f01-8e15-000000000001', 'AbERP_ComplianceSnapshot', 'Compliance Snapshot', 'N');

  -- Standard columns helper macro via repeated calls
  -- Rule
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c001-4f01-8e15-000000000001','AbERP_ComplianceRule_ID','Compliance Rule',13,NULL,'Y','N',0,10,'Y','N','Y');
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c002-4f01-8e15-000000000001','AD_Client_ID','Client',19,NULL,'Y','N',10,10);
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c003-4f01-8e15-000000000001','AD_Org_ID','Organization',19,NULL,'Y','N',20,10);
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c004-4f01-8e15-000000000001','IsActive','Active',20,NULL,'Y','Y',30,1,'N','N','N','N','Y');
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c005-4f01-8e15-000000000001','Created','Created',16,NULL,'Y','N',40,7);
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c006-4f01-8e15-000000000001','CreatedBy','Created By',18,110,'Y','N',50,10);
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c007-4f01-8e15-000000000001','Updated','Updated',16,NULL,'Y','N',60,7);
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c008-4f01-8e15-000000000001','UpdatedBy','Updated By',18,110,'Y','N',70,10);
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c009-4f01-8e15-000000000001','AbERP_ComplianceRule_UU','Immutable Universally Unique Identifier',10,NULL,'N','N',80,36);
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c010-4f01-8e15-000000000001','Name','Name',10,NULL,'Y','Y',90,100,'N','N','Y','Y');
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c011-4f01-8e15-000000000001','Description','Description',14,NULL,'N','Y',100,500);
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c012-4f01-8e15-000000000001','ComplianceCategory','Category',17,v_cat,'Y','Y',110,2,'N','N','N','Y');
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c013-4f01-8e15-000000000001','Severity','Severity',17,v_sev,'Y','Y',120,10,'N','N','N','Y');
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c014-4f01-8e15-000000000001','Weight','Weight',22,NULL,'Y','Y',130,10,'N','N','N','N','1');
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c015-4f01-8e15-000000000001','DaysBeforeExpiry','Days Before Expiry',11,NULL,'N','Y',140,10);
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c016-4f01-8e15-000000000001','AD_Window_ID','Window',19,NULL,'N','Y',150,10);
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c017-4f01-8e15-000000000001','AD_InfoWindow_ID','Info Window',19,NULL,'N','Y',160,10);
  PERFORM pg_temp.saw023_col(v_rule_id,'23a02301-c018-4f01-8e15-000000000001','AD_Table_ID','Source Table',19,NULL,'Y','Y',170,10);

  -- Result
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c001-4f01-8e15-000000000001','AbERP_ComplianceResult_ID','Compliance Result',13,NULL,'Y','N',0,10,'Y');
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c002-4f01-8e15-000000000001','AD_Client_ID','Client',19,NULL,'Y','N',10,10);
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c003-4f01-8e15-000000000001','AD_Org_ID','Organization',19,NULL,'Y','N',20,10);
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c004-4f01-8e15-000000000001','IsActive','Active',20,NULL,'Y','Y',30,1,'N','N','N','N','Y');
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c005-4f01-8e15-000000000001','Created','Created',16,NULL,'Y','N',40,7);
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c006-4f01-8e15-000000000001','CreatedBy','Created By',18,110,'Y','N',50,10);
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c007-4f01-8e15-000000000001','Updated','Updated',16,NULL,'Y','N',60,7);
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c008-4f01-8e15-000000000001','UpdatedBy','Updated By',18,110,'Y','N',70,10);
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c009-4f01-8e15-000000000001','AbERP_ComplianceResult_UU','Immutable Universally Unique Identifier',10,NULL,'N','N',80,36);
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c010-4f01-8e15-000000000001','AbERP_ComplianceRule_ID','Compliance Rule',19,NULL,'Y','Y',90,10,'N','Y','N','Y');
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c011-4f01-8e15-000000000001','AD_Table_ID','Source Table',19,NULL,'Y','Y',100,10);
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c012-4f01-8e15-000000000001','Record_ID','Record ID',11,NULL,'Y','Y',110,10);
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c013-4f01-8e15-000000000001','AD_User_ID','Employee',19,NULL,'N','Y',120,10,'N','N','N','Y');
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c014-4f01-8e15-000000000001','C_BPartner_ID','Participant',19,NULL,'N','Y',130,10,'N','N','N','Y');
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c015-4f01-8e15-000000000001','AbERP_Support_Location_ID','Support Location',19,NULL,'N','Y',140,10,'N','N','N','Y');
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c016-4f01-8e15-000000000001','DateDetected','Date Detected',16,NULL,'Y','Y',150,7);
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c017-4f01-8e15-000000000001','DateChecked','Date Checked',16,NULL,'N','Y',160,7);
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c018-4f01-8e15-000000000001','DueDate','Due Date',16,NULL,'N','Y',170,7);
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c019-4f01-8e15-000000000001','ComplianceStatus','Status',17,v_sts,'Y','Y',180,10,'N','N','N','Y');
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c020-4f01-8e15-000000000001','Severity','Severity',17,v_sev,'Y','Y',190,10,'N','N','N','Y');
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c021-4f01-8e15-000000000001','ResultMessage','Result Message',14,NULL,'N','Y',200,2000);
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c022-4f01-8e15-000000000001','IsResolved','Resolved',20,NULL,'Y','Y',210,1,'N','N','N','Y','N');
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c023-4f01-8e15-000000000001','ResolvedDate','Resolved Date',16,NULL,'N','Y',220,7);
  PERFORM pg_temp.saw023_col(v_result_id,'23a02302-c024-4f01-8e15-000000000001','ResolvedBy','Resolved By',18,110,'N','Y',230,10);

  -- Snapshot
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c001-4f01-8e15-000000000001','AbERP_ComplianceSnapshot_ID','Compliance Snapshot',13,NULL,'Y','N',0,10,'Y');
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c002-4f01-8e15-000000000001','AD_Client_ID','Client',19,NULL,'Y','N',10,10);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c003-4f01-8e15-000000000001','AD_Org_ID','Organization',19,NULL,'Y','N',20,10);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c004-4f01-8e15-000000000001','IsActive','Active',20,NULL,'Y','Y',30,1,'N','N','N','N','Y');
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c005-4f01-8e15-000000000001','Created','Created',16,NULL,'Y','N',40,7);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c006-4f01-8e15-000000000001','CreatedBy','Created By',18,110,'Y','N',50,10);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c007-4f01-8e15-000000000001','Updated','Updated',16,NULL,'Y','N',60,7);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c008-4f01-8e15-000000000001','UpdatedBy','Updated By',18,110,'Y','N',70,10);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c009-4f01-8e15-000000000001','AbERP_ComplianceSnapshot_UU','Immutable Universally Unique Identifier',10,NULL,'N','N',80,36);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c010-4f01-8e15-000000000001','SnapshotDate','Snapshot Date',16,NULL,'Y','Y',90,7);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c011-4f01-8e15-000000000001','AbERP_Support_Location_ID','Support Location',19,NULL,'N','Y',100,10);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c012-4f01-8e15-000000000001','ComplianceCategory','Category',17,v_cat,'Y','Y',110,2,'N','N','N','Y');
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c013-4f01-8e15-000000000001','TotalItems','Total Items',11,NULL,'Y','Y',120,10);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c014-4f01-8e15-000000000001','Compliant','Compliant',11,NULL,'Y','Y',130,10);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c015-4f01-8e15-000000000001','Warning','Warning',11,NULL,'Y','Y',140,10);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c016-4f01-8e15-000000000001','NonCompliant','Non-Compliant',11,NULL,'Y','Y',150,10);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c017-4f01-8e15-000000000001','Critical','Critical',11,NULL,'Y','Y',160,10);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c018-4f01-8e15-000000000001','Overdue','Overdue',11,NULL,'Y','Y',170,10);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c019-4f01-8e15-000000000001','AtRisk','At Risk',11,NULL,'Y','Y',180,10);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c020-4f01-8e15-000000000001','OnTrack','On Track',11,NULL,'Y','Y',190,10);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c021-4f01-8e15-000000000001','AuditReadinessScore','Audit Readiness Score',22,NULL,'Y','Y',200,10);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c022-4f01-8e15-000000000001','TrafficLight','Traffic Light',17,v_tl,'Y','Y',210,2);
  PERFORM pg_temp.saw023_col(v_snap_id,'23a02303-c023-4f01-8e15-000000000001','LastCalculated','Last Calculated',16,NULL,'Y','Y',220,7);

  RAISE NOTICE 'SAW023 AD tables rule=% result=% snap=%', v_rule_id, v_result_id, v_snap_id;
END $$;
