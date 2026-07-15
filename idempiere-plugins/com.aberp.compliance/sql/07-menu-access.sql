-- =============================================================================
-- SAW023 — Menu + window access (Admin + AbilityERP Admin)
-- Folder UU:  23a02330-c0d4-4f01-8e15-000000000001
-- Summary UU: 23a02331-c0d4-4f01-8e15-000000000001
-- Rules UU:   23a02332-c0d4-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_menu_id),0)+1 FROM ad_menu))
WHERE name='AD_Menu' AND istableid='Y';

DO $$
DECLARE
  v_folder_uu  CONSTANT TEXT := '23a02330-c0d4-4f01-8e15-000000000001';
  v_summary_uu CONSTANT TEXT := '23a02331-c0d4-4f01-8e15-000000000001';
  v_rules_uu   CONSTANT TEXT := '23a02332-c0d4-4f01-8e15-000000000001';
  v_folder_id INTEGER;
  v_summary_menu INTEGER;
  v_rules_menu INTEGER;
  v_summary_win INTEGER;
  v_rules_win INTEGER;
  v_parent_id INTEGER := -1;
  v_ability INTEGER;
  v_seq INTEGER;
BEGIN
  SELECT ad_window_id INTO v_summary_win
  FROM ad_window
  WHERE ad_window_uu = '23a02305-c0d4-4f01-8e15-000000000001'
     OR name = 'Compliance Summary'
  LIMIT 1;
  SELECT ad_window_id INTO v_rules_win
  FROM ad_window
  WHERE ad_window_uu = '23a02306-c0d4-4f01-8e15-000000000001'
     OR name = 'Compliance Rules'
  LIMIT 1;
  IF v_summary_win IS NULL OR v_rules_win IS NULL THEN
    RAISE EXCEPTION 'SAW023: windows missing — run 05/06 first';
  END IF;

  SELECT m.ad_menu_id INTO v_ability
  FROM ad_menu m
  WHERE m.issummary = 'Y' AND m.name IN ('Ability ERP', 'AbilityERP')
  ORDER BY CASE WHEN m.name = 'Ability ERP' THEN 0 ELSE 1 END, m.ad_menu_id
  LIMIT 1;
  IF v_ability IS NOT NULL THEN
    v_parent_id := v_ability;
  END IF;

  -- Summary folder
  SELECT ad_menu_id INTO v_folder_id FROM ad_menu WHERE ad_menu_uu = v_folder_uu;
  IF v_folder_id IS NULL THEN
    SELECT ad_menu_id INTO v_folder_id FROM ad_menu
    WHERE name = 'Compliance & Audit Hub' AND issummary = 'Y';
  END IF;
  IF v_folder_id IS NULL THEN
    INSERT INTO ad_menu (
      ad_menu_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, issummary, issotrx, isreadonly,
      action, entitytype, ad_menu_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Menu' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Compliance & Audit Hub',
      'NDIS compliance summary, rules, and audit results',
      'Y', 'N', 'N',
      NULL, 'Ab_ERP', v_folder_uu
    ) RETURNING ad_menu_id INTO v_folder_id;
  ELSE
    UPDATE ad_menu SET
      name = 'Compliance & Audit Hub',
      issummary = 'Y',
      isactive = 'Y',
      entitytype = 'Ab_ERP',
      ad_menu_uu = COALESCE(ad_menu_uu, v_folder_uu),
      updated = NOW()
    WHERE ad_menu_id = v_folder_id;
  END IF;

  SELECT COALESCE(MAX(seqno), 0) + 10 INTO v_seq
  FROM ad_treenodemm WHERE parent_id = v_parent_id AND ad_tree_id = 10;

  IF NOT EXISTS (SELECT 1 FROM ad_treenodemm WHERE node_id = v_folder_id AND ad_tree_id = 10) THEN
    INSERT INTO ad_treenodemm (ad_tree_id, node_id, parent_id, seqno, ad_client_id, ad_org_id, created, createdby, updated, updatedby, isactive)
    VALUES (10, v_folder_id, v_parent_id, v_seq, 0, 0, NOW(), 100, NOW(), 100, 'Y');
  ELSE
    UPDATE ad_treenodemm SET parent_id = v_parent_id, updated = NOW()
    WHERE node_id = v_folder_id AND ad_tree_id = 10;
  END IF;

  -- Summary window menu
  SELECT ad_menu_id INTO v_summary_menu FROM ad_menu WHERE ad_menu_uu = v_summary_uu;
  IF v_summary_menu IS NULL THEN
    SELECT ad_menu_id INTO v_summary_menu FROM ad_menu
    WHERE name = 'Compliance Summary' AND ad_window_id = v_summary_win;
  END IF;
  IF v_summary_menu IS NULL THEN
    INSERT INTO ad_menu (
      ad_menu_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, issummary, issotrx, isreadonly,
      action, ad_window_id, entitytype, ad_menu_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Menu' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Compliance Summary',
      'NDIS Audit Readiness summary',
      'N', 'N', 'N',
      'W', v_summary_win, 'Ab_ERP', v_summary_uu
    ) RETURNING ad_menu_id INTO v_summary_menu;
  ELSE
    UPDATE ad_menu SET
      ad_window_id = v_summary_win, action = 'W', isactive = 'Y',
      entitytype = 'Ab_ERP', ad_menu_uu = COALESCE(ad_menu_uu, v_summary_uu), updated = NOW()
    WHERE ad_menu_id = v_summary_menu;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_treenodemm WHERE node_id = v_summary_menu AND ad_tree_id = 10) THEN
    INSERT INTO ad_treenodemm (ad_tree_id, node_id, parent_id, seqno, ad_client_id, ad_org_id, created, createdby, updated, updatedby, isactive)
    VALUES (10, v_summary_menu, v_folder_id, 10, 0, 0, NOW(), 100, NOW(), 100, 'Y');
  ELSE
    UPDATE ad_treenodemm SET parent_id = v_folder_id, seqno = 10, updated = NOW()
    WHERE node_id = v_summary_menu AND ad_tree_id = 10;
  END IF;

  -- Rules window menu
  SELECT ad_menu_id INTO v_rules_menu FROM ad_menu WHERE ad_menu_uu = v_rules_uu;
  IF v_rules_menu IS NULL THEN
    SELECT ad_menu_id INTO v_rules_menu FROM ad_menu
    WHERE name = 'Compliance Rules' AND ad_window_id = v_rules_win;
  END IF;
  IF v_rules_menu IS NULL THEN
    INSERT INTO ad_menu (
      ad_menu_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, issummary, issotrx, isreadonly,
      action, ad_window_id, entitytype, ad_menu_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Menu' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Compliance Rules',
      'Configure compliance audit rules (Admin)',
      'N', 'N', 'N',
      'W', v_rules_win, 'Ab_ERP', v_rules_uu
    ) RETURNING ad_menu_id INTO v_rules_menu;
  ELSE
    UPDATE ad_menu SET
      ad_window_id = v_rules_win, action = 'W', isactive = 'Y',
      entitytype = 'Ab_ERP', ad_menu_uu = COALESCE(ad_menu_uu, v_rules_uu), updated = NOW()
    WHERE ad_menu_id = v_rules_menu;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_treenodemm WHERE node_id = v_rules_menu AND ad_tree_id = 10) THEN
    INSERT INTO ad_treenodemm (ad_tree_id, node_id, parent_id, seqno, ad_client_id, ad_org_id, created, createdby, updated, updatedby, isactive)
    VALUES (10, v_rules_menu, v_folder_id, 20, 0, 0, NOW(), 100, NOW(), 100, 'Y');
  ELSE
    UPDATE ad_treenodemm SET parent_id = v_folder_id, seqno = 20, updated = NOW()
    WHERE node_id = v_rules_menu AND ad_tree_id = 10;
  END IF;

  -- Window access
  INSERT INTO ad_window_access (
    ad_window_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, isreadwrite, ad_window_access_uu
  )
  SELECT w.ad_window_id, r.ad_role_id, r.ad_client_id, 0, 'Y',
         NOW(), 100, NOW(), 100, 'Y', NULL
  FROM ad_role r
  CROSS JOIN (VALUES (v_summary_win), (v_rules_win)) AS w(ad_window_id)
  WHERE r.name IN ('AbilityERP Admin', 'Admin', 'System Administrator')
    AND r.isactive = 'Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_window_access wa
      WHERE wa.ad_window_id = w.ad_window_id
        AND wa.ad_role_id = r.ad_role_id
        AND wa.ad_client_id = r.ad_client_id
    );

  RAISE NOTICE 'SAW023 menu folder=% summary=% rules=% parent=%',
    v_folder_id, v_summary_menu, v_rules_menu, v_parent_id;
END $$;
