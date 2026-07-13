-- =============================================================================
-- SAW016 — AD for Leave Planning Line + retarget Leave Records tab
-- =============================================================================
SET search_path TO adempiere;

-- Bump sequences
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_table_id),0)+1 FROM ad_table))
WHERE name='AD_Table' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_reference_id),0)+1 FROM ad_reference))
WHERE name='AD_Reference' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw016_col(
  p_table_id INTEGER, p_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_ref INTEGER, p_ref_value INTEGER, p_mandatory CHAR, p_updateable CHAR,
  p_seqno INTEGER, p_fieldlength INTEGER, p_columnsql TEXT DEFAULT NULL,
  p_isparent CHAR DEFAULT 'N', p_iskey CHAR DEFAULT 'N', p_isidentifier CHAR DEFAULT 'N',
  p_isselection CHAR DEFAULT 'N'
) RETURNS void AS $$
DECLARE
  v_col_id INTEGER; v_el INTEGER;
BEGIN
  SELECT ad_element_id INTO v_el FROM ad_element WHERE columnname = p_columnname LIMIT 1;
  IF v_el IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_Element' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100, p_columnname,'Ab_ERP',p_name,p_name,
      '16a01600-0000-4002-8000-' || lpad(substr(md5(p_columnname),1,12),12,'0')
    ) RETURNING ad_element_id INTO v_el;
  END IF;

  SELECT ad_column_id INTO v_col_id FROM ad_column WHERE ad_column_uu = p_uu;
  IF v_col_id IS NULL THEN
    SELECT ad_column_id INTO v_col_id FROM ad_column WHERE ad_table_id=p_table_id AND columnname=p_columnname;
  END IF;

  IF v_col_id IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, version, entitytype, columnname, ad_table_id, ad_reference_id, ad_reference_value_id,
      fieldlength, iskey, isparent, ismandatory, isupdateable, isidentifier, seqno,
      istranslated, isencrypted, isselectioncolumn, ad_element_id, issyncdatabase, isalwaysupdateable,
      columnsql, isallowcopy, istoolbarbutton, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_Column' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100,
      p_name,0,'Ab_ERP',p_columnname,p_table_id,p_ref,p_ref_value,
      p_fieldlength,p_iskey,p_isparent,p_mandatory,
      CASE WHEN p_columnsql IS NOT NULL THEN 'N' ELSE p_updateable END,
      p_isidentifier,p_seqno,'N','N',p_isselection,v_el,'Y','N',
      p_columnsql,'N','N',p_uu
    );
  ELSE
    UPDATE ad_column SET name=p_name, ad_reference_id=p_ref, ad_reference_value_id=p_ref_value,
      fieldlength=p_fieldlength, ismandatory=p_mandatory,
      isupdateable=CASE WHEN p_columnsql IS NOT NULL THEN 'N' ELSE p_updateable END,
      isparent=p_isparent, iskey=p_iskey, columnsql=p_columnsql, isselectioncolumn=p_isselection,
      ad_column_uu=COALESCE(ad_column_uu,p_uu), updated=NOW()
    WHERE ad_column_id=v_col_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_table_id INTEGER;
  v_plan_table INTEGER;
  v_leave_table INTEGER;
  v_window_id INTEGER;
  v_tab_id INTEGER;
  v_link_col INTEGER;
  v_ref_leave INTEGER;
  v_ref_approver INTEGER;
BEGIN
  SELECT ad_table_id INTO v_plan_table FROM ad_table WHERE tablename='AbERP_Leave_Planning';
  SELECT ad_table_id INTO v_leave_table FROM ad_table WHERE tablename='AbERP_Unavailability_Leave';
  SELECT ad_window_id INTO v_window_id FROM ad_window WHERE name='Leave Planning';

  SELECT ad_reference_id INTO v_ref_approver FROM ad_reference WHERE name='AbERP_ApproverStatus_List' LIMIT 1;

  -- Table ref for leave zoom
  SELECT ad_reference_id INTO v_ref_leave FROM ad_reference
  WHERE ad_reference_uu='16a0160c-c0d4-4f01-8e15-000000000001';
  IF v_ref_leave IS NULL THEN
    INSERT INTO ad_reference (
      ad_reference_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, validationtype, entitytype, ad_reference_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_Reference' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100,
      'AbERP Leave Planning -> Unavailability Leave','T','Ab_ERP','16a0160c-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_reference_id INTO v_ref_leave;

    INSERT INTO ad_ref_table (
      ad_reference_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      ad_table_id, ad_key, ad_display, isvaluedisplayed, entitytype, whereclause, orderbyclause
    ) VALUES (
      v_ref_leave,0,0,'Y',NOW(),100,NOW(),100,
      v_leave_table,
      (SELECT ad_column_id FROM ad_column WHERE ad_table_id=v_leave_table AND columnname='AbERP_Unavailability_Leave_ID'),
      (SELECT ad_column_id FROM ad_column WHERE ad_table_id=v_leave_table AND columnname='AbERP_User_Contact_ID'),
      'N','Ab_ERP', NULL, NULL
    );
  END IF;

  SELECT ad_table_id INTO v_table_id FROM ad_table
  WHERE ad_table_uu='16a0160b-c0d4-4f01-8e15-000000000001' OR tablename='AbERP_Leave_Planning_Line';
  IF v_table_id IS NULL THEN
    INSERT INTO ad_table (
      ad_table_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, tablename, isview, accesslevel, entitytype, ad_window_id,
      issecurityenabled, isdeleteable, ishighvolume, importtable, ischangelog, replicationtype,
      ad_table_uu, iscentrallymaintained
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_Table' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100,
      'Leave Planning Line', 'Matching leave rows for a planning header',
      'AbERP_Leave_Planning_Line', 'N', '3', 'Ab_ERP', v_window_id,
      'N','Y','N','N','Y','L',
      '16a0160b-c0d4-4f01-8e15-000000000001','Y'
    ) RETURNING ad_table_id INTO v_table_id;
  END IF;

  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0001-4f01-8e15-000000000001','AbERP_Leave_Planning_Line_ID','Leave Planning Line',13,NULL,'Y','N',0,22,NULL,'N','Y','N');
  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0002-4f01-8e15-000000000001','AD_Client_ID','Client',19,NULL,'Y','N',10,22,NULL,'N','N','N');
  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0003-4f01-8e15-000000000001','AD_Org_ID','Organization',19,NULL,'Y','N',20,22,NULL,'N','N','N');
  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0004-4f01-8e15-000000000001','IsActive','Active',20,NULL,'Y','Y',30,1);
  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0005-4f01-8e15-000000000001','Created','Created',16,NULL,'Y','N',40,7);
  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0006-4f01-8e15-000000000001','CreatedBy','Created By',18,110,'Y','N',50,22);
  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0007-4f01-8e15-000000000001','Updated','Updated',16,NULL,'Y','N',60,7);
  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0008-4f01-8e15-000000000001','UpdatedBy','Updated By',18,110,'Y','N',70,22);
  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0009-4f01-8e15-000000000001','AbERP_Leave_Planning_Line_UU','UU',10,NULL,'N','Y',80,36);
  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0010-4f01-8e15-000000000001','AbERP_Leave_Planning_ID','Leave Planning',19,NULL,'Y','N',90,22,NULL,'Y','N','N');
  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0011-4f01-8e15-000000000001','AbERP_Unavailability_Leave_ID','Leave Record',30,v_ref_leave,'Y','N',100,22,NULL,'N','N','Y','Y');

  -- Display ColumnSQL from leave
  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0012-4f01-8e15-000000000001','AbERP_User_Contact_ID','Employee',30,
    (SELECT ad_reference_value_id::integer FROM ad_column WHERE ad_table_id=v_leave_table AND columnname='AbERP_User_Contact_ID'),
    'N','N',110,22,
    '(SELECT ul.AbERP_User_Contact_ID FROM AbERP_Unavailability_Leave ul WHERE ul.AbERP_Unavailability_Leave_ID=AbERP_Leave_Planning_Line.AbERP_Unavailability_Leave_ID)',
    'N','N','N','Y');

  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0013-4f01-8e15-000000000001','AbERP_LP_EmployeeNumber','Employee Number',10,NULL,'N','N',120,40,
    '(SELECT u.Value FROM AbERP_Unavailability_Leave ul JOIN AD_User u ON u.AD_User_ID=ul.AbERP_User_Contact_ID WHERE ul.AbERP_Unavailability_Leave_ID=AbERP_Leave_Planning_Line.AbERP_Unavailability_Leave_ID)',
    'N','N','N','Y');

  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0014-4f01-8e15-000000000001','AbERP_LP_ServiceLocation','Service Location',10,NULL,'N','N',130,120,
    '(SELECT bpl.Name FROM AbERP_Unavailability_Leave ul JOIN AD_User u ON u.AD_User_ID=ul.AbERP_User_Contact_ID JOIN C_BPartner_Location bpl ON bpl.C_BPartner_Location_ID=u.C_BPartner_Location_ID WHERE ul.AbERP_Unavailability_Leave_ID=AbERP_Leave_Planning_Line.AbERP_Unavailability_Leave_ID)',
    'N','N','N','Y');

  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0015-4f01-8e15-000000000001','AbERP_CurrentSupervisor','Current Supervisor',30,286,'N','N',140,22,
    '(SELECT bp.Supervisor_ID FROM AbERP_Unavailability_Leave ul JOIN AD_User u ON u.AD_User_ID=ul.AbERP_User_Contact_ID JOIN C_BPartner bp ON bp.C_BPartner_ID=u.C_BPartner_ID WHERE ul.AbERP_Unavailability_Leave_ID=AbERP_Leave_Planning_Line.AbERP_Unavailability_Leave_ID)');

  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0016-4f01-8e15-000000000001','AbERP_Unavailability_Type_ID','Unavailability Type',19,NULL,'N','N',150,22,
    '(SELECT ul.AbERP_Unavailability_Type_ID FROM AbERP_Unavailability_Leave ul WHERE ul.AbERP_Unavailability_Leave_ID=AbERP_Leave_Planning_Line.AbERP_Unavailability_Leave_ID)',
    'N','N','N','Y');

  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0017-4f01-8e15-000000000001','StartDate','Start Date',16,NULL,'N','N',160,7,
    '(SELECT ul.StartDate FROM AbERP_Unavailability_Leave ul WHERE ul.AbERP_Unavailability_Leave_ID=AbERP_Leave_Planning_Line.AbERP_Unavailability_Leave_ID)');

  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0018-4f01-8e15-000000000001','EndDate','End Date',16,NULL,'N','N',170,7,
    '(SELECT ul.EndDate FROM AbERP_Unavailability_Leave ul WHERE ul.AbERP_Unavailability_Leave_ID=AbERP_Leave_Planning_Line.AbERP_Unavailability_Leave_ID)');

  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0019-4f01-8e15-000000000001','AbERP_LP_CalendarDays','Calendar Days',11,NULL,'N','N',180,10,
    '(SELECT ((ul.EndDate::date - ul.StartDate::date) + 1) FROM AbERP_Unavailability_Leave ul WHERE ul.AbERP_Unavailability_Leave_ID=AbERP_Leave_Planning_Line.AbERP_Unavailability_Leave_ID)');

  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0020-4f01-8e15-000000000001','AbERP_ApproverStatus','Approver Status',17,v_ref_approver,'N','N',190,4,
    '(SELECT ul.AbERP_ApproverStatus FROM AbERP_Unavailability_Leave ul WHERE ul.AbERP_Unavailability_Leave_ID=AbERP_Leave_Planning_Line.AbERP_Unavailability_Leave_ID)',
    'N','N','N','Y');

  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0021-4f01-8e15-000000000001','AbERP_SubmitterStatus','Submitter Status',17,
    (SELECT ad_reference_value_id::integer FROM ad_column WHERE ad_table_id=v_leave_table AND columnname='AbERP_SubmitterStatus'),
    'N','N',200,4,
    '(SELECT ul.AbERP_SubmitterStatus FROM AbERP_Unavailability_Leave ul WHERE ul.AbERP_Unavailability_Leave_ID=AbERP_Leave_Planning_Line.AbERP_Unavailability_Leave_ID)');

  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0022-4f01-8e15-000000000001','Note','Note',14,NULL,'N','N',210,2000,
    '(SELECT ul.Note FROM AbERP_Unavailability_Leave ul WHERE ul.AbERP_Unavailability_Leave_ID=AbERP_Leave_Planning_Line.AbERP_Unavailability_Leave_ID)');

  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0023-4f01-8e15-000000000001','LeaveCreated','Created',16,NULL,'N','N',220,7,
    '(SELECT ul.Created FROM AbERP_Unavailability_Leave ul WHERE ul.AbERP_Unavailability_Leave_ID=AbERP_Leave_Planning_Line.AbERP_Unavailability_Leave_ID)');

  PERFORM pg_temp.saw016_col(v_table_id,'16a016l0-0024-4f01-8e15-000000000001','LeaveUpdated','Updated',16,NULL,'N','N',230,7,
    '(SELECT ul.Updated FROM AbERP_Unavailability_Leave ul WHERE ul.AbERP_Unavailability_Leave_ID=AbERP_Leave_Planning_Line.AbERP_Unavailability_Leave_ID)');

  -- Link column on line table
  SELECT ad_column_id INTO v_link_col FROM ad_column
  WHERE ad_table_id=v_table_id AND columnname='AbERP_Leave_Planning_ID';

  -- Retarget Leave Records tab
  SELECT ad_tab_id INTO v_tab_id FROM ad_tab WHERE ad_tab_uu='16a01604-c0d4-4f01-8e15-000000000001';
  UPDATE ad_tab SET
    ad_table_id = v_table_id,
    tablevel = 1,
    ad_column_id = v_link_col,
    whereclause = NULL,
    orderbyclause = 'AbERP_ApproverStatus, StartDate, AbERP_User_Contact_ID',
    isinsertrecord = 'N',
    isreadonly = 'Y',
    issinglerow = 'N',
    updated = NOW()
  WHERE ad_tab_id = v_tab_id;

  -- Replace fields on Leave Records tab
  DELETE FROM ad_field WHERE ad_tab_id = v_tab_id;

  -- Recreate fields via simple inserts for displayed columns
  INSERT INTO ad_field (
    ad_field_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
    name, iscentrallymaintained, ad_tab_id, ad_column_id,
    isdisplayed, isreadonly, seqno, issameline, isheading, isfieldonly, isencrypted,
    entitytype, isdisplayedgrid, seqnogrid, xposition, columnspan, numlines,
    isquickentry, isdefaultfocus, ad_field_uu
  )
  SELECT
    nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_Field' AND istableid='Y')::integer,'N'),
    0,0,'Y',NOW(),100,NOW(),100,
    c.name, 'Y', v_tab_id, c.ad_column_id,
    CASE WHEN c.columnname IN ('AbERP_Leave_Planning_Line_ID','AbERP_Leave_Planning_Line_UU','AbERP_Leave_Planning_ID','AD_Client_ID','Created','CreatedBy','Updated','UpdatedBy') THEN 'N' ELSE 'Y' END,
    'Y',
    CASE c.columnname
      WHEN 'AbERP_Unavailability_Leave_ID' THEN 10
      WHEN 'AbERP_User_Contact_ID' THEN 20
      WHEN 'AbERP_LP_EmployeeNumber' THEN 30
      WHEN 'AbERP_LP_ServiceLocation' THEN 40
      WHEN 'AbERP_CurrentSupervisor' THEN 50
      WHEN 'AbERP_Unavailability_Type_ID' THEN 60
      WHEN 'StartDate' THEN 70
      WHEN 'EndDate' THEN 80
      WHEN 'AbERP_LP_CalendarDays' THEN 90
      WHEN 'AbERP_ApproverStatus' THEN 100
      WHEN 'AbERP_SubmitterStatus' THEN 110
      WHEN 'Note' THEN 120
      WHEN 'LeaveCreated' THEN 130
      WHEN 'LeaveUpdated' THEN 140
      WHEN 'AD_Org_ID' THEN 150
      WHEN 'IsActive' THEN 160
      ELSE 900
    END,
    'N','N','N','N','Ab_ERP',
    CASE WHEN c.columnname IN ('AbERP_Leave_Planning_Line_ID','AbERP_Leave_Planning_Line_UU','AbERP_Leave_Planning_ID','AD_Client_ID','Created','CreatedBy','Updated','UpdatedBy','IsActive','AD_Org_ID') THEN 'N' ELSE 'Y' END,
    CASE c.columnname
      WHEN 'AbERP_ApproverStatus' THEN 10
      WHEN 'AbERP_User_Contact_ID' THEN 20
      WHEN 'AbERP_LP_EmployeeNumber' THEN 30
      WHEN 'AbERP_LP_ServiceLocation' THEN 40
      WHEN 'AbERP_Unavailability_Type_ID' THEN 50
      WHEN 'StartDate' THEN 60
      WHEN 'EndDate' THEN 70
      WHEN 'AbERP_LP_CalendarDays' THEN 80
      WHEN 'AbERP_SubmitterStatus' THEN 90
      WHEN 'AbERP_Unavailability_Leave_ID' THEN 5
      ELSE 200
    END,
    1,2,1,'N','N',
    generate_uuid()
  FROM ad_column c
  WHERE c.ad_table_id = v_table_id;

  RAISE NOTICE 'SAW016 line table=% tab=% link=%', v_table_id, v_tab_id, v_link_col;
END $$;
