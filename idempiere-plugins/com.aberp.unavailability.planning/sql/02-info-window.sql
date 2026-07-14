-- =============================================================================
-- SAW021 — Unavailability Planning Info Window
-- Fixed UU: 21a021iw-c0d4-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_infowindow_id),0)+1 FROM ad_infowindow))
WHERE name='AD_InfoWindow' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_infocolumn_id),0)+1 FROM ad_infocolumn))
WHERE name='AD_InfoColumn' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_menu_id),0)+1 FROM ad_menu))
WHERE name='AD_Menu' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_val_rule_id),0)+1 FROM ad_val_rule))
WHERE name='AD_Val_Rule' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw021_iw_col(
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
  p_val_rule INTEGER DEFAULT NULL,
  p_readonly CHAR DEFAULT 'N'
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
      '21a02100-0000-4003-8000-' || lpad(substr(md5(p_columnname),1,12),12,'0')
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
      p_operator, p_identifier, p_mandatory, p_iskey, p_readonly,
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
      isreadonly = p_readonly, isactive = 'Y', updated = NOW(), updatedby = 100,
      ad_infocolumn_uu = COALESCE(ad_infocolumn_uu, p_uu)
    WHERE ad_infocolumn_id = v_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_iw_uu CONSTANT TEXT := '21a021iw-c0d4-4f01-8e15-000000000001';
  v_menu_uu CONSTANT TEXT := '21a02105-c0d4-4f01-8e15-000000000001';
  v_val_uu CONSTANT TEXT := '21a02106-c0d4-4f01-8e15-000000000001';
  v_iw INTEGER;
  v_table INTEGER;
  v_ref_approver INTEGER;
  v_ref_submitter INTEGER;
  v_val_loc INTEGER;
  v_menu_id INTEGER;
  v_parent INTEGER;
  v_tree INTEGER;
BEGIN
  SELECT ad_table_id INTO v_table FROM ad_table WHERE tablename = 'AbERP_OngoingUnavailability';
  IF v_table IS NULL THEN
    RAISE EXCEPTION 'AbERP_OngoingUnavailability missing';
  END IF;

  SELECT ad_reference_id INTO v_ref_approver FROM ad_reference WHERE name = 'AbERP_ApproverStatus_List' LIMIT 1;
  SELECT ad_reference_id INTO v_ref_submitter FROM ad_reference WHERE name = 'AbERP_SubmitterStatus_List' LIMIT 1;

  -- Support Location val rule (active Support Locations)
  SELECT ad_val_rule_id INTO v_val_loc FROM ad_val_rule WHERE ad_val_rule_uu = v_val_uu;
  IF v_val_loc IS NULL THEN
    INSERT INTO ad_val_rule (
      ad_val_rule_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, type, code, entitytype, ad_val_rule_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_Val_Rule' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100,
      'AbERP Unavailability Planning Support Locations',
      'Active Support Locations only',
      'S',
      'C_BPartner_Location.C_BPartner_Location_ID IN ('
        || 'SELECT C_BPartner_Location_ID FROM AbERP_Support_Location '
        || 'WHERE IsActive=''Y'' AND C_BPartner_Location_ID IS NOT NULL)',
      'Ab_ERP', v_val_uu
    ) RETURNING ad_val_rule_id INTO v_val_loc;
  ELSE
    UPDATE ad_val_rule SET
      code = 'C_BPartner_Location.C_BPartner_Location_ID IN ('
        || 'SELECT C_BPartner_Location_ID FROM AbERP_Support_Location '
        || 'WHERE IsActive=''Y'' AND C_BPartner_Location_ID IS NOT NULL)',
      updated = NOW(), updatedby = 100
    WHERE ad_val_rule_id = v_val_loc;
  END IF;

  SELECT ad_infowindow_id INTO v_iw FROM ad_infowindow WHERE ad_infowindow_uu = v_iw_uu;
  IF v_iw IS NULL THEN
    SELECT ad_infowindow_id INTO v_iw FROM ad_infowindow
    WHERE name = 'Unavailability Planning' AND entitytype = 'Ab_ERP';
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
      'Unavailability Planning',
      'Query ongoing unavailability overlapping a planning period and optional support locations',
      'Set Planning Start and Planning End (date only). Matching uses date overlap. Support Location blank = all. Search updates results. Zoom opens Ongoing Unavailability.',
      v_table, 'Ab_ERP',
      'AbERP_OngoingUnavailability ou'
        || ' INNER JOIN AD_User u ON (u.AD_User_ID=ou.AbERP_User_Contact_ID)'
        || ' LEFT JOIN C_BPartner bp ON (bp.C_BPartner_ID=u.C_BPartner_ID)',
      'ou.IsActive=''Y''',
      'CASE ou.AbERP_ApproverStatus WHEN ''DC'' THEN 1 WHEN ''RV'' THEN 2 WHEN ''AP'' THEN 3 ELSE 9 END, ou.StartDate, u.Name',
      'Y', 'N', 'N', 'N', 500,
      'Y', v_iw_uu
    ) RETURNING ad_infowindow_id INTO v_iw;
  ELSE
    UPDATE ad_infowindow SET
      name = 'Unavailability Planning',
      description = 'Query ongoing unavailability overlapping a planning period and optional support locations',
      help = 'Set Planning Start and Planning End (date only). Matching uses date overlap. Support Location blank = all. Search updates results. Zoom opens Ongoing Unavailability.',
      ad_table_id = v_table,
      fromclause = 'AbERP_OngoingUnavailability ou'
        || ' INNER JOIN AD_User u ON (u.AD_User_ID=ou.AbERP_User_Contact_ID)'
        || ' LEFT JOIN C_BPartner bp ON (bp.C_BPartner_ID=u.C_BPartner_ID)',
      whereclause = 'ou.IsActive=''Y''',
      orderbyclause = 'CASE ou.AbERP_ApproverStatus WHEN ''DC'' THEN 1 WHEN ''RV'' THEN 2 WHEN ''AP'' THEN 3 ELSE 9 END, ou.StartDate, u.Name',
      isvalid = 'Y', maxqueryrecords = 500, isloadpagenum = 'Y',
      entitytype = 'Ab_ERP', updated = NOW(), updatedby = 100,
      ad_infowindow_uu = COALESCE(ad_infowindow_uu, v_iw_uu)
    WHERE ad_infowindow_id = v_iw;
  END IF;

  -- Criteria
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0001-4f01-8e15-000000000001',10,
    'AbERP_PlanningStart','Planning Start','ou.EndDate',15,NULL,'Y','N','>=','Y');
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0002-4f01-8e15-000000000001',20,
    'AbERP_PlanningEnd','Planning End','ou.StartDate',15,NULL,'Y','N','<=','Y');
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0003-4f01-8e15-000000000001',30,
    'C_BPartner_Location_ID','Support Location','u.C_BPartner_Location_ID',19,NULL,'Y','N','=','N','N',
    'N','N', v_val_loc);
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0004-4f01-8e15-000000000001',40,
    'AbERP_ApproverStatus','Approver Status','ou.AbERP_ApproverStatus',17,v_ref_approver,'Y','Y','=',
    'N','N','N','N',NULL,'Y');
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0005-4f01-8e15-000000000001',50,
    'AbERP_User_Contact_ID','Employee','ou.AbERP_User_Contact_ID',18,110,'Y','Y','=',
    'N','N','N','N',NULL,'Y');

  -- Result grid
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0006-4f01-8e15-000000000001',60,
    'AbERP_OngoingUnavailability_ID','Ongoing Unavailability','ou.AbERP_OngoingUnavailability_ID',13,NULL,'N','N','=',
    'N','N','Y','N',NULL,'Y');
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0007-4f01-8e15-000000000001',70,
    'Value','Employee Number','u.Value',10,NULL,'N','N',NULL,'N','N','N','N',NULL,'Y');
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0008-4f01-8e15-000000000001',80,
    'Name','Employee Name','u.Name',10,NULL,'N','Y',NULL,'N','N','N','Y',NULL,'Y');
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0009-4f01-8e15-000000000001',90,
    'AbERP_UP_SupportLocation','Support Location','aberp_up_primary_support_location(u.AD_User_ID)',10,NULL,'N','Y',NULL,
    'N','N','N','N',NULL,'Y');
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0010-4f01-8e15-000000000001',100,
    'Supervisor_ID','Current Supervisor','bp.Supervisor_ID',30,110,'N','Y','=',
    'N','N','N','N',NULL,'Y');
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0011-4f01-8e15-000000000001',110,
    'StartDate','Start','ou.StartDate',15,NULL,'N','Y',NULL,'N','N','N','N',NULL,'Y');
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0012-4f01-8e15-000000000001',120,
    'EndDate','End','ou.EndDate',15,NULL,'N','Y',NULL,'N','N','N','N',NULL,'Y');
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0013-4f01-8e15-000000000001',130,
    'AbERP_UP_CalendarDays','Calendar Days',
    '((ou.EndDate::date - ou.StartDate::date) + 1)',11,NULL,'N','Y',NULL,'N','N','N','N',NULL,'Y');
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0014-4f01-8e15-000000000001',140,
    'AbERP_UP_UnavailablePattern','Unavailable Pattern',
    'aberp_up_unavailable_pattern(ou.AbERP_OngoingUnavailability_ID)',14,NULL,'N','Y',NULL,
    'N','N','N','N',NULL,'Y');
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0015-4f01-8e15-000000000001',150,
    'AbERP_SubmitterStatus','Submitter Status','ou.AbERP_SubmitterStatus',17,v_ref_submitter,'N','N','=',
    'N','N','N','N',NULL,'Y');
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0016-4f01-8e15-000000000001',160,
    'Note','Note','ou.Note',14,NULL,'N','Y',NULL,'N','N','N','N',NULL,'Y');
  PERFORM pg_temp.saw021_iw_col(v_iw,'21a021ic-0017-4f01-8e15-000000000001',170,
    'Created','Created','ou.Created',16,NULL,'N','Y',NULL,'N','N','N','N',NULL,'Y');

  -- Access by role name (unique key is role + info window — ignore client in EXISTS)
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
      WHERE x.ad_infowindow_id=v_iw AND x.ad_role_id=r.ad_role_id
    );

  -- Mirror Ongoing Unavailability + Unavailability & Leave window access
  INSERT INTO ad_infowindow_access (
    ad_infowindow_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, ad_infowindow_access_uu
  )
  SELECT DISTINCT ON (wa.ad_role_id)
         v_iw, wa.ad_role_id, wa.ad_client_id, 0, 'Y', NOW(), 100, NOW(), 100, NULL
  FROM ad_window_access wa
  JOIN ad_window w ON w.ad_window_id=wa.ad_window_id
  WHERE (w.ad_window_uu IN ('68bcd45c-eec6-4e45-855c-0d4f0705aeb5','80352010-b3bd-47e6-a783-71de6b046da8')
         OR w.name IN ('Ongoing Unavailability','Unavailability & Leave (all)'))
    AND wa.isactive='Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_infowindow_access x
      WHERE x.ad_infowindow_id=v_iw AND x.ad_role_id=wa.ad_role_id
    )
  ORDER BY wa.ad_role_id, wa.ad_client_id;

  -- Menu
  SELECT ad_menu_id INTO v_menu_id FROM ad_menu
  WHERE ad_menu_uu = v_menu_uu OR name = 'Unavailability Planning'
  LIMIT 1;

  IF v_menu_id IS NULL THEN
    INSERT INTO ad_menu (
      ad_menu_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, issummary, issotrx, isreadonly, action, ad_infowindow_id, entitytype, ad_menu_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_Menu' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100,
      'Unavailability Planning', 'Ongoing unavailability planning query — period and locations',
      'N','Y','N','I', v_iw, 'Ab_ERP', v_menu_uu
    ) RETURNING ad_menu_id INTO v_menu_id;
  ELSE
    UPDATE ad_menu SET
      action = 'I',
      ad_window_id = NULL,
      ad_infowindow_id = v_iw,
      name = 'Unavailability Planning',
      description = 'Ongoing unavailability planning query — period and locations',
      isactive = 'Y', updated = NOW(), updatedby = 100,
      ad_menu_uu = COALESCE(ad_menu_uu, v_menu_uu)
    WHERE ad_menu_id = v_menu_id;
  END IF;

  -- Root menu (-1) like Leave Planning for reliable search/find
  v_tree := 10;
  v_parent := -1;

  IF NOT EXISTS (SELECT 1 FROM ad_treenodemm WHERE ad_tree_id = v_tree AND node_id = v_menu_id) THEN
    INSERT INTO ad_treenodemm (ad_tree_id, node_id, parent_id, seqno, ad_client_id, ad_org_id,
      created, createdby, updated, updatedby, isactive)
    VALUES (v_tree, v_menu_id, v_parent, 9991, 0,0, NOW(),100,NOW(),100,'Y');
  ELSE
    UPDATE ad_treenodemm SET
      parent_id = v_parent,
      isactive = 'Y',
      updated = NOW(),
      updatedby = 100
    WHERE ad_tree_id = v_tree AND node_id = v_menu_id;
  END IF;

  RAISE NOTICE 'SAW021 Unavailability Planning Info iw=% menu=%', v_iw, v_menu_id;
END $$;
