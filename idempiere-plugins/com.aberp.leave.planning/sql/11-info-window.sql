-- =============================================================================
-- SAW016 — Leave Planning as Info Window (static query + results)
-- Replaces the record-based window as the primary UX.
-- Fixed UU: InfoWindow 16a016iw-c0d4-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

-- Bump sequences
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_infowindow_id),0)+1 FROM ad_infowindow))
WHERE name='AD_InfoWindow' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_infocolumn_id),0)+1 FROM ad_infocolumn))
WHERE name='AD_InfoColumn' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_menu_id),0)+1 FROM ad_menu))
WHERE name='AD_Menu' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw016_iw_col(
  p_iw INTEGER,
  p_uu TEXT,
  p_seqno INTEGER,
  p_columnname TEXT,
  p_name TEXT,
  p_select TEXT,
  p_ref INTEGER,
  p_ref_value INTEGER,
  p_query CHAR,
  p_display CHAR,
  p_operator TEXT,
  p_mandatory CHAR DEFAULT 'N',
  p_multisel CHAR DEFAULT 'N',
  p_iskey CHAR DEFAULT 'N',
  p_identifier CHAR DEFAULT 'N',
  p_val_rule INTEGER DEFAULT NULL
) RETURNS void AS $$
DECLARE
  v_id INTEGER;
  v_el INTEGER;
BEGIN
  SELECT ad_element_id INTO v_el FROM ad_element WHERE columnname = p_columnname LIMIT 1;
  IF v_el IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_Element' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100, p_columnname, 'Ab_ERP', p_name, p_name,
      '16a01600-0000-4003-8000-' || lpad(substr(md5(p_columnname),1,12),12,'0')
    ) RETURNING ad_element_id INTO v_el;
  END IF;

  SELECT ad_infocolumn_id INTO v_id FROM ad_infocolumn WHERE ad_infocolumn_uu = p_uu;
  IF v_id IS NULL THEN
    SELECT ad_infocolumn_id INTO v_id FROM ad_infocolumn
    WHERE ad_infowindow_id = p_iw AND columnname = p_columnname AND seqno = p_seqno;
  END IF;

  IF v_id IS NULL THEN
    INSERT INTO ad_infocolumn (
      ad_infocolumn_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, ad_infowindow_id, entitytype, selectclause, seqno,
      isdisplayed, isquerycriteria, ad_element_id, ad_reference_id, ad_reference_value_id,
      ad_infocolumn_uu, ad_val_rule_id, iscentrallymaintained, columnname,
      queryoperator, isidentifier, ismandatory, iskey, isreadonly,
      ishideinfocolumn, ismultiselectcriteria
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_InfoColumn' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100,
      p_name, NULL, p_iw, 'Ab_ERP', p_select, p_seqno,
      p_display, p_query, v_el, p_ref, p_ref_value,
      p_uu, p_val_rule, 'Y', p_columnname,
      p_operator, p_identifier, p_mandatory, p_iskey, 'N',
      'N', p_multisel
    );
  ELSE
    UPDATE ad_infocolumn SET
      name = p_name, selectclause = p_select, seqno = p_seqno,
      isdisplayed = p_display, isquerycriteria = p_query,
      ad_reference_id = p_ref, ad_reference_value_id = p_ref_value,
      queryoperator = p_operator, ismandatory = p_mandatory,
      ismultiselectcriteria = p_multisel, iskey = p_iskey,
      isidentifier = p_identifier, ad_val_rule_id = p_val_rule,
      isactive = 'Y', updated = NOW(), updatedby = 100,
      ad_infocolumn_uu = COALESCE(ad_infocolumn_uu, p_uu)
    WHERE ad_infocolumn_id = v_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_iw_uu CONSTANT TEXT := '16a016iw-c0d4-4f01-8e15-000000000001';
  v_iw INTEGER;
  v_leave_table INTEGER;
  v_ref_approver INTEGER;
  v_ref_submitter INTEGER;
  v_ref_user INTEGER;
  v_val_loc INTEGER;
  v_menu_id INTEGER;
  v_old_menu INTEGER;
BEGIN
  SELECT ad_table_id INTO v_leave_table FROM ad_table WHERE tablename = 'AbERP_Unavailability_Leave';
  IF v_leave_table IS NULL THEN
    RAISE EXCEPTION 'AbERP_Unavailability_Leave missing';
  END IF;

  SELECT ad_reference_id INTO v_ref_approver FROM ad_reference WHERE name = 'AbERP_ApproverStatus_List' LIMIT 1;
  SELECT ad_reference_id INTO v_ref_submitter FROM ad_reference WHERE name = 'AbERP_SubmitterStatus_List' LIMIT 1;
  SELECT ad_reference_value_id INTO v_ref_user FROM ad_column c
  JOIN ad_table t ON t.ad_table_id=c.ad_table_id
  WHERE t.tablename='AbERP_Unavailability_Leave' AND c.columnname='AbERP_User_Contact_ID';

  SELECT ad_val_rule_id INTO v_val_loc FROM ad_val_rule
  WHERE ad_val_rule_uu = '16a01606-c0d4-4f01-8e15-000000000001';

  SELECT ad_infowindow_id INTO v_iw FROM ad_infowindow WHERE ad_infowindow_uu = v_iw_uu;
  IF v_iw IS NULL THEN
    SELECT ad_infowindow_id INTO v_iw FROM ad_infowindow WHERE name = 'Leave Planning' AND entitytype = 'Ab_ERP';
  END IF;

  IF v_iw IS NULL THEN
    INSERT INTO ad_infowindow (
      ad_infowindow_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, help, ad_table_id, entitytype,
      fromclause, whereclause, orderbyclause, isvalid,
      isdefault, isdistinct, isshowindashboard, maxqueryrecords,
      isloadpagenum, ad_infowindow_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_InfoWindow' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100,
      'Leave Planning',
      'Query leave overlapping a planning period and optional service locations',
      'Set Planning Start and Planning End (date only). Leave Start/End overlap that period. Service Locations is multi-select — leave blank for all locations (subject to role/org security). Results update when you Search. Double-click / Zoom opens the leave record for submit/approve.',
      v_leave_table, 'Ab_ERP',
      'AbERP_Unavailability_Leave ul'
        || ' INNER JOIN AD_User u ON (u.AD_User_ID=ul.AbERP_User_Contact_ID)'
        || ' LEFT JOIN C_BPartner_Location bpl ON (bpl.C_BPartner_Location_ID=u.C_BPartner_Location_ID)'
        || ' LEFT JOIN C_BPartner bp ON (bp.C_BPartner_ID=u.C_BPartner_ID)'
        || ' LEFT JOIN AbERP_Unavailability_Type ut ON (ut.AbERP_Unavailability_Type_ID=ul.AbERP_Unavailability_Type_ID)',
      'ul.IsActive=''Y''',
      'CASE ul.AbERP_ApproverStatus WHEN ''DC'' THEN 1 WHEN ''RV'' THEN 2 WHEN ''AP'' THEN 3 ELSE 9 END, ul.StartDate, u.Name',
      'Y', 'N', 'N', 'N', 500,
      'Y', v_iw_uu
    ) RETURNING ad_infowindow_id INTO v_iw;
  ELSE
    UPDATE ad_infowindow SET
      name = 'Leave Planning',
      description = 'Query leave overlapping a planning period and optional service locations',
      help = 'Set Planning Start and Planning End (date only). Leave Start/End overlap that period. Service Locations is multi-select — leave blank for all locations (subject to role/org security). Results update when you Search. Double-click / Zoom opens the leave record for submit/approve.',
      fromclause = 'AbERP_Unavailability_Leave ul'
        || ' INNER JOIN AD_User u ON (u.AD_User_ID=ul.AbERP_User_Contact_ID)'
        || ' LEFT JOIN C_BPartner_Location bpl ON (bpl.C_BPartner_Location_ID=u.C_BPartner_Location_ID)'
        || ' LEFT JOIN C_BPartner bp ON (bp.C_BPartner_ID=u.C_BPartner_ID)'
        || ' LEFT JOIN AbERP_Unavailability_Type ut ON (ut.AbERP_Unavailability_Type_ID=ul.AbERP_Unavailability_Type_ID)',
      whereclause = 'ul.IsActive=''Y''',
      orderbyclause = 'CASE ul.AbERP_ApproverStatus WHEN ''DC'' THEN 1 WHEN ''RV'' THEN 2 WHEN ''AP'' THEN 3 ELSE 9 END, ul.StartDate, u.Name',
      isvalid = 'Y', maxqueryrecords = 500, isloadpagenum = 'Y',
      entitytype = 'Ab_ERP', updated = NOW(), updatedby = 100,
      ad_infowindow_uu = COALESCE(ad_infowindow_uu, v_iw_uu)
    WHERE ad_infowindow_id = v_iw;
  END IF;

  -- Criteria (static query strip)
  -- Overlap: leave.EndDate >= PlanningStart AND leave.StartDate <= PlanningEnd
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0001-4f01-8e15-000000000001',10,
    'AbERP_PlanningStart','Planning Start','ul.EndDate',15,NULL,'Y','N','>=','Y');
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0002-4f01-8e15-000000000001',20,
    'AbERP_PlanningEnd','Planning End','ul.StartDate',15,NULL,'Y','N','<=','Y');

  -- Optional single Service Location (blank = all).
  -- Multi Select Table + All/Any is a cramped weird Info editor and can emit -1 when empty.
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0003-4f01-8e15-000000000001',30,
    'C_BPartner_Location_ID','Service Location','u.C_BPartner_Location_ID',19,NULL,'Y','N','=','N','N',
    'N','N', v_val_loc);

  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0004-4f01-8e15-000000000001',40,
    'AbERP_ApproverStatus','Approver Status','ul.AbERP_ApproverStatus',17,v_ref_approver,'Y','Y','=');
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0005-4f01-8e15-000000000001',50,
    'AbERP_Unavailability_Type_ID','Unavailability Type','ul.AbERP_Unavailability_Type_ID',19,NULL,'Y','Y','=');
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0006-4f01-8e15-000000000001',60,
    'AbERP_User_Contact_ID','Employee', 'ul.AbERP_User_Contact_ID',30,v_ref_user,'Y','Y','=');

  -- Result grid
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0007-4f01-8e15-000000000001',70,
    'AbERP_Unavailability_Leave_ID','Leave', 'ul.AbERP_Unavailability_Leave_ID',13,NULL,'N','N','=',
    'N','N','Y','N');
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0008-4f01-8e15-000000000001',80,
    'Value','Employee Number','u.Value',10,NULL,'N','N',NULL);
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0009-4f01-8e15-000000000001',90,
    'Name','Employee Name','u.Name',10,NULL,'N','N',NULL,'N','N','N','Y');
  -- Display only in grid (location filter is the multi-select above)
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0010-4f01-8e15-000000000001',100,
    'AbERP_LP_ServiceLocation','Service Location','bpl.Name',10,NULL,'N','Y',NULL);
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0011-4f01-8e15-000000000001',110,
    'Supervisor_ID','Current Supervisor','bp.Supervisor_ID',30,110,'N','Y','=');
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0012-4f01-8e15-000000000001',120,
    'StartDate','Leave Start','ul.StartDate',15,NULL,'N','Y',NULL);
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0013-4f01-8e15-000000000001',130,
    'EndDate','Leave End','ul.EndDate',15,NULL,'N','Y',NULL);
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0014-4f01-8e15-000000000001',140,
    'AbERP_LP_CalendarDays','Calendar Days',
    '((ul.EndDate::date - ul.StartDate::date) + 1)',11,NULL,'N','Y',NULL);
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0015-4f01-8e15-000000000001',150,
    'AbERP_SubmitterStatus','Submitter Status','ul.AbERP_SubmitterStatus',17,v_ref_submitter,'N','N','=');
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0016-4f01-8e15-000000000001',160,
    'Note','Note','ul.Note',14,NULL,'N','Y',NULL);
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0017-4f01-8e15-000000000001',170,
    'Created','Created','ul.Created',16,NULL,'N','Y',NULL);
  PERFORM pg_temp.saw016_iw_col(v_iw,'16a016ic-0018-4f01-8e15-000000000001',180,
    'Updated','Updated','ul.Updated',16,NULL,'N','N',NULL);

  -- Info Window access (same roles as before)
  INSERT INTO ad_infowindow_access (
    ad_infowindow_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, ad_infowindow_access_uu
  )
  SELECT v_iw, r.ad_role_id, r.ad_client_id, 0, 'Y', NOW(), 100, NOW(), 100, NULL
  FROM ad_role r
  WHERE r.name IN ('AbilityERP Admin','Admin','System Administrator','Rostering','Rostering TL',
                   'People and Culture','Manager People and Culture')
    AND r.isactive='Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_infowindow_access x
      WHERE x.ad_infowindow_id=v_iw AND x.ad_role_id=r.ad_role_id AND x.ad_client_id=r.ad_client_id
    );

  -- Mirror from Unavailability window access
  INSERT INTO ad_infowindow_access (
    ad_infowindow_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, ad_infowindow_access_uu
  )
  SELECT v_iw, wa.ad_role_id, wa.ad_client_id, 0, 'Y', NOW(), 100, NOW(), 100, NULL
  FROM ad_window_access wa
  JOIN ad_window w ON w.ad_window_id=wa.ad_window_id
  WHERE (w.ad_window_uu='80352010-b3bd-47e6-a783-71de6b046da8' OR w.name='Unavailability & Leave (all)')
    AND wa.isactive='Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_infowindow_access x
      WHERE x.ad_infowindow_id=v_iw AND x.ad_role_id=wa.ad_role_id AND x.ad_client_id=wa.ad_client_id
    );

  -- Repoint Leave Planning menu from Window → Info Window (static query UX)
  SELECT ad_menu_id INTO v_old_menu FROM ad_menu
  WHERE ad_menu_uu='16a01605-c0d4-4f01-8e15-000000000001' OR name='Leave Planning'
  LIMIT 1;

  IF v_old_menu IS NOT NULL THEN
    UPDATE ad_menu SET
      action = 'I',
      ad_window_id = NULL,
      ad_infowindow_id = v_iw,
      description = 'Leave planning query — period, locations, summaries via Search',
      updated = NOW(), updatedby = 100
    WHERE ad_menu_id = v_old_menu;
  ELSE
    INSERT INTO ad_menu (
      ad_menu_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, issummary, issotrx, isreadonly, action, ad_infowindow_id, entitytype, ad_menu_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_Menu' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100,
      'Leave Planning', 'Leave planning query — period and locations',
      'N','Y','N','I', v_iw, 'Ab_ERP', '16a01605-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_menu_id INTO v_menu_id;

    INSERT INTO ad_treenodemm (ad_tree_id, node_id, parent_id, seqno, ad_client_id, ad_org_id,
      created, createdby, updated, updatedby, isactive)
    VALUES (10, v_menu_id, -1, 9990, 0,0, NOW(),100,NOW(),100,'Y')
    ON CONFLICT DO NOTHING;
  END IF;

  -- Soft-retire record window (keep for rollback; remove from menu tree if separate)
  UPDATE ad_window SET
    isactive = 'N',
    name = 'Leave Planning (Records — retired)',
    updated = NOW()
  WHERE ad_window_uu = '16a01602-c0d4-4f01-8e15-000000000001';

  RAISE NOTICE 'SAW016 Info Window Leave Planning id=%', v_iw;
END $$;
