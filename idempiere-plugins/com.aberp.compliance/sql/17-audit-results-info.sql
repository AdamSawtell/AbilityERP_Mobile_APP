-- =============================================================================
-- SAW023 Phase 4 — Compliance Results Info Window
-- IW UU: 23a02360-…  Menu UU: 23a02361-…
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_infowindow_id),0)+1 FROM ad_infowindow))
WHERE name='AD_InfoWindow' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_infocolumn_id),0)+1 FROM ad_infocolumn))
WHERE name='AD_InfoColumn' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_menu_id),0)+1 FROM ad_menu))
WHERE name='AD_Menu' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw023_iw_col(
  p_iw INTEGER, p_uu TEXT, p_seqno INTEGER, p_columnname TEXT, p_name TEXT,
  p_select TEXT, p_ref INTEGER, p_ref_value INTEGER,
  p_query CHAR, p_display CHAR, p_operator TEXT,
  p_mandatory CHAR DEFAULT 'N', p_multisel CHAR DEFAULT 'N',
  p_iskey CHAR DEFAULT 'N', p_identifier CHAR DEFAULT 'N'
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
      '23a02360-0000-4003-8000-' || lpad(substr(md5(p_columnname),1,12),12,'0')
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
      name, ad_infowindow_id, entitytype, selectclause, seqno,
      isdisplayed, isquerycriteria, ad_element_id, ad_reference_id, ad_reference_value_id,
      ad_infocolumn_uu, iscentrallymaintained, columnname,
      queryoperator, isidentifier, ismandatory, iskey, isreadonly, ishideinfocolumn, ismultiselectcriteria
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_InfoColumn' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100, p_name, p_iw, 'Ab_ERP', p_select, p_seqno,
      p_display, p_query, v_el, p_ref, p_ref_value, p_uu, 'Y', p_columnname,
      p_operator, p_identifier, p_mandatory, p_iskey, 'N', 'N', p_multisel
    );
  ELSE
    UPDATE ad_infocolumn SET
      name = p_name, selectclause = p_select, seqno = p_seqno,
      isdisplayed = p_display, isquerycriteria = p_query,
      ad_reference_id = p_ref, ad_reference_value_id = p_ref_value,
      queryoperator = p_operator, ismandatory = p_mandatory,
      ismultiselectcriteria = p_multisel, iskey = p_iskey, isidentifier = p_identifier,
      isactive = 'Y', updated = NOW(), updatedby = 100,
      ad_infocolumn_uu = COALESCE(ad_infocolumn_uu, p_uu)
    WHERE ad_infocolumn_id = v_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_iw_uu CONSTANT TEXT := '23a02360-c0d4-4f01-8e15-000000000001';
  v_menu_uu CONSTANT TEXT := '23a02361-c0d4-4f01-8e15-000000000001';
  v_iw INTEGER;
  v_table INTEGER;
  v_ref_sts INTEGER;
  v_ref_sev INTEGER;
  v_menu INTEGER;
  v_folder INTEGER;
  v_tree INTEGER := 10;
  v_from TEXT;
BEGIN
  SELECT ad_table_id INTO v_table FROM ad_table WHERE tablename = 'AbERP_ComplianceResult';
  IF v_table IS NULL THEN
    RAISE EXCEPTION 'SAW023: AbERP_ComplianceResult missing';
  END IF;

  SELECT ad_reference_id INTO v_ref_sts FROM ad_reference
  WHERE ad_reference_uu = '23a02322-c0d4-4f01-8e15-000000000001' OR name = 'AbERP_ComplianceStatus' LIMIT 1;
  SELECT ad_reference_id INTO v_ref_sev FROM ad_reference
  WHERE ad_reference_uu = '23a02321-c0d4-4f01-8e15-000000000001' OR name = 'AbERP_Severity' LIMIT 1;
  IF v_ref_sts IS NULL OR v_ref_sev IS NULL THEN
    RAISE EXCEPTION 'SAW023: status/severity refs missing — run 02';
  END IF;

  v_from := 'AbERP_ComplianceResult r'
    || ' INNER JOIN AbERP_ComplianceRule cr ON (cr.AbERP_ComplianceRule_ID=r.AbERP_ComplianceRule_ID)'
    || ' LEFT JOIN AD_User u ON (u.AD_User_ID=r.AD_User_ID)';

  SELECT ad_infowindow_id INTO v_iw FROM ad_infowindow WHERE ad_infowindow_uu = v_iw_uu;
  IF v_iw IS NULL THEN
    SELECT ad_infowindow_id INTO v_iw FROM ad_infowindow
    WHERE name = 'Compliance Results' AND entitytype = 'Ab_ERP' LIMIT 1;
  END IF;

  IF v_iw IS NULL THEN
    INSERT INTO ad_infowindow (
      ad_infowindow_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, ad_table_id, entitytype,
      fromclause, otherclause, whereclause, orderbyclause, isvalid,
      isdefault, isdistinct, isshowindashboard, maxqueryrecords, isloadpagenum, ad_infowindow_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_InfoWindow' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100,
      'Compliance Results', 'Query NDIS audit findings by status, severity, rule, and date',
      v_table, 'Ab_ERP',
      v_from, NULL, 'r.IsActive=''Y''',
      'r.Severity, r.DateDetected DESC, cr.Name',
      'Y', 'N', 'N', 'N', 500, 'Y', v_iw_uu
    ) RETURNING ad_infowindow_id INTO v_iw;
  ELSE
    UPDATE ad_infowindow SET
      name = 'Compliance Results',
      fromclause = v_from,
      whereclause = 'r.IsActive=''Y''',
      orderbyclause = 'r.Severity, r.DateDetected DESC, cr.Name',
      isvalid = 'Y', maxqueryrecords = 500, isloadpagenum = 'Y',
      entitytype = 'Ab_ERP', updated = NOW(), updatedby = 100,
      ad_infowindow_uu = COALESCE(ad_infowindow_uu, v_iw_uu)
    WHERE ad_infowindow_id = v_iw;
  END IF;

  -- Criteria
  PERFORM pg_temp.saw023_iw_col(v_iw,'23a0236c-0001-4f01-8e15-000000000001',10,
    'ComplianceStatus','Status','r.ComplianceStatus',17,v_ref_sts,'Y','N','=');
  PERFORM pg_temp.saw023_iw_col(v_iw,'23a0236c-0002-4f01-8e15-000000000001',20,
    'Severity','Severity','r.Severity',17,v_ref_sev,'Y','N','=');
  PERFORM pg_temp.saw023_iw_col(v_iw,'23a0236c-0003-4f01-8e15-000000000001',30,
    'Name','Rule Name','cr.Name',10,NULL,'Y','N','Like');
  PERFORM pg_temp.saw023_iw_col(v_iw,'23a0236c-0004-4f01-8e15-000000000001',40,
    'DateDetected','Date Detected','r.DateDetected',15,NULL,'Y','N','>=');

  -- Grid
  PERFORM pg_temp.saw023_iw_col(v_iw,'23a0236c-0006-4f01-8e15-000000000001',60,
    'AbERP_ComplianceResult_ID','Result','r.AbERP_ComplianceResult_ID',13,NULL,'N','Y','=','N','N','Y','N');
  PERFORM pg_temp.saw023_iw_col(v_iw,'23a0236c-0007-4f01-8e15-000000000001',70,
    'Name','Rule','cr.Name',10,NULL,'N','Y',NULL,'N','N','N','Y');
  PERFORM pg_temp.saw023_iw_col(v_iw,'23a0236c-0008-4f01-8e15-000000000001',80,
    'ComplianceStatus','Status','r.ComplianceStatus',17,v_ref_sts,'N','Y','=');
  PERFORM pg_temp.saw023_iw_col(v_iw,'23a0236c-0009-4f01-8e15-000000000001',90,
    'Severity','Severity','r.Severity',17,v_ref_sev,'N','Y','=');
  PERFORM pg_temp.saw023_iw_col(v_iw,'23a0236c-0010-4f01-8e15-000000000001',100,
    'ResultMessage','Message','r.ResultMessage',14,NULL,'N','Y',NULL);
  PERFORM pg_temp.saw023_iw_col(v_iw,'23a0236c-0011-4f01-8e15-000000000001',110,
    'DateDetected','Detected','r.DateDetected',16,NULL,'N','Y',NULL);
  PERFORM pg_temp.saw023_iw_col(v_iw,'23a0236c-0012-4f01-8e15-000000000001',120,
    'AD_User_ID','Employee','r.AD_User_ID',19,NULL,'N','Y','=');
  PERFORM pg_temp.saw023_iw_col(v_iw,'23a0236c-0013-4f01-8e15-000000000001',130,
    'Record_ID','Record','r.Record_ID',11,NULL,'N','Y',NULL);
  PERFORM pg_temp.saw023_iw_col(v_iw,'23a0236c-0014-4f01-8e15-000000000001',140,
    'AD_Table_ID','Source Table','r.AD_Table_ID',19,NULL,'N','Y','=');

  -- Access by role name
  INSERT INTO ad_infowindow_access (
    ad_infowindow_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby
  )
  SELECT v_iw, r.ad_role_id, r.ad_client_id, 0, 'Y', NOW(), 100, NOW(), 100
  FROM ad_role r
  WHERE r.name IN ('Admin', 'AbilityERP Admin', 'System Administrator')
    AND r.isactive = 'Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_infowindow_access x
      WHERE x.ad_infowindow_id = v_iw AND x.ad_role_id = r.ad_role_id
        AND x.ad_client_id = r.ad_client_id
    );

  UPDATE ad_infowindow_access x SET isactive = 'Y', updated = NOW()
  FROM ad_role r
  WHERE x.ad_role_id = r.ad_role_id AND x.ad_client_id = r.ad_client_id
    AND x.ad_infowindow_id = v_iw
    AND r.name IN ('Admin', 'AbilityERP Admin', 'System Administrator');

  -- Menu under NDIS Audit Tool folder
  SELECT ad_menu_id INTO v_folder FROM ad_menu
  WHERE ad_menu_uu = '23a02330-c0d4-4f01-8e15-000000000001'
     OR (name = 'NDIS Audit Tool' AND issummary = 'Y')
  LIMIT 1;
  IF v_folder IS NULL THEN
    RAISE EXCEPTION 'SAW023: NDIS Audit Tool folder missing — run 13';
  END IF;

  SELECT ad_menu_id INTO v_menu FROM ad_menu WHERE ad_menu_uu = v_menu_uu;
  IF v_menu IS NULL THEN
    SELECT ad_menu_id INTO v_menu FROM ad_menu WHERE name = 'Compliance Results' AND action = 'I' LIMIT 1;
  END IF;

  IF v_menu IS NULL THEN
    INSERT INTO ad_menu (
      ad_menu_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, issummary, issotrx, isreadonly,
      action, ad_infowindow_id, entitytype, ad_menu_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_Menu' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100,
      'Compliance Results', 'Query NDIS audit findings',
      'N','N','N',
      'I', v_iw, 'Ab_ERP', v_menu_uu
    ) RETURNING ad_menu_id INTO v_menu;
  ELSE
    UPDATE ad_menu SET
      action = 'I', ad_infowindow_id = v_iw, isactive = 'Y',
      name = 'Compliance Results',
      updated = NOW(), updatedby = 100,
      ad_menu_uu = COALESCE(ad_menu_uu, v_menu_uu)
    WHERE ad_menu_id = v_menu;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_treenodemm WHERE ad_tree_id = v_tree AND node_id = v_menu) THEN
    INSERT INTO ad_treenodemm (ad_tree_id, node_id, parent_id, seqno, ad_client_id, ad_org_id,
      created, createdby, updated, updatedby, isactive)
    VALUES (v_tree, v_menu, v_folder, 20, 0, 0, NOW(), 100, NOW(), 100, 'Y');
  ELSE
    UPDATE ad_treenodemm SET parent_id = v_folder, seqno = 20, isactive = 'Y', updated = NOW()
    WHERE ad_tree_id = v_tree AND node_id = v_menu;
  END IF;

  RAISE NOTICE 'SAW023 Compliance Results InfoWindow=% menu=%', v_iw, v_menu;
END $$;

SELECT iw.name AS infowindow, m.name AS menu, r.name AS role, r.ad_client_id
FROM ad_infowindow iw
JOIN ad_infowindow_access a ON a.ad_infowindow_id = iw.ad_infowindow_id
JOIN ad_role r ON r.ad_role_id = a.ad_role_id AND r.ad_client_id = a.ad_client_id
LEFT JOIN ad_menu m ON m.ad_infowindow_id = iw.ad_infowindow_id
WHERE iw.ad_infowindow_uu = '23a02360-c0d4-4f01-8e15-000000000001'
ORDER BY r.ad_client_id, r.name;
