-- =============================================================================
-- SAW016 — Menu + window/process access (Admin + AbilityERP Admin by name)
-- Menu UU: 16a01605-c0d4-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_menu_uu CONSTANT TEXT := '16a01605-c0d4-4f01-8e15-000000000001';
  v_window_id INTEGER;
  v_menu_id INTEGER;
  v_parent_id INTEGER;
  v_seq INTEGER;
BEGIN
  SELECT ad_window_id INTO v_window_id
  FROM ad_window
  WHERE ad_window_uu = '16a01602-c0d4-4f01-8e15-000000000001'
     OR name = 'Leave Planning'
  LIMIT 1;
  IF v_window_id IS NULL THEN
    RAISE EXCEPTION 'SAW016: Leave Planning window missing — run 04 first';
  END IF;

  -- Prefer root (-1) like other Unavailability menus so search/menu find it reliably;
  -- Rostering folder is secondary if present for documentation only.
  v_parent_id := -1;

  SELECT ad_menu_id INTO v_menu_id FROM ad_menu WHERE ad_menu_uu = v_menu_uu;
  IF v_menu_id IS NULL THEN
    SELECT ad_menu_id INTO v_menu_id FROM ad_menu WHERE name = 'Leave Planning' AND ad_window_id = v_window_id;
  END IF;

  IF v_menu_id IS NULL THEN
    INSERT INTO ad_menu (
      ad_menu_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, issummary, issotrx, isreadonly,
      action, ad_window_id, ad_workflow_id, ad_task_id,
      ad_process_id, ad_form_id, ad_workbench_id,
      entitytype, ad_menu_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Menu' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Leave Planning',
      'Workforce leave planning by period and service location',
      'N', 'Y', 'N',
      'W', v_window_id, NULL, NULL,
      NULL, NULL, NULL,
      'Ab_ERP', v_menu_uu
    ) RETURNING ad_menu_id INTO v_menu_id;
  ELSE
    UPDATE ad_menu SET
      name = 'Leave Planning',
      ad_window_id = v_window_id,
      action = 'W',
      isactive = 'Y',
      entitytype = 'Ab_ERP',
      ad_menu_uu = COALESCE(ad_menu_uu, v_menu_uu),
      updated = NOW()
    WHERE ad_menu_id = v_menu_id;
  END IF;

  SELECT COALESCE(MAX(seqno), 0) + 10 INTO v_seq
  FROM ad_treenodemm WHERE parent_id = v_parent_id;

  IF NOT EXISTS (
    SELECT 1 FROM ad_treenodemm WHERE node_id = v_menu_id
  ) THEN
    INSERT INTO ad_treenodemm (ad_tree_id, node_id, parent_id, seqno, ad_client_id, ad_org_id, created, createdby, updated, updatedby, isactive)
    VALUES (10, v_menu_id, COALESCE(NULLIF(v_parent_id,0), -1), v_seq, 0, 0, NOW(), 100, NOW(), 100, 'Y');
  ELSE
    UPDATE ad_treenodemm SET
      parent_id = COALESCE(NULLIF(v_parent_id,0), parent_id),
      updated = NOW()
    WHERE node_id = v_menu_id AND ad_tree_id = 10;
  END IF;

  -- Window access by role name (portable)
  INSERT INTO ad_window_access (
    ad_window_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, isreadwrite, ad_window_access_uu
  )
  SELECT v_window_id, r.ad_role_id, r.ad_client_id, 0, 'Y',
         NOW(), 100, NOW(), 100, 'Y',
         NULL
  FROM ad_role r
  WHERE r.name IN ('AbilityERP Admin', 'Admin', 'System Administrator', 'Rostering', 'Rostering TL', 'People and Culture', 'Manager People and Culture')
    AND r.isactive = 'Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_window_access wa
      WHERE wa.ad_window_id = v_window_id
        AND wa.ad_role_id = r.ad_role_id
        AND wa.ad_client_id = r.ad_client_id
    );

  -- Also grant to same roles that can open Unavailability & Leave (all)
  INSERT INTO ad_window_access (
    ad_window_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, isreadwrite, ad_window_access_uu
  )
  SELECT v_window_id, wa.ad_role_id, wa.ad_client_id, 0, 'Y',
         NOW(), 100, NOW(), 100, wa.isreadwrite,
         NULL
  FROM ad_window_access wa
  JOIN ad_window w ON w.ad_window_id = wa.ad_window_id
  WHERE (w.ad_window_uu = '80352010-b3bd-47e6-a783-71de6b046da8' OR w.name = 'Unavailability & Leave (all)')
    AND wa.isactive = 'Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_window_access x
      WHERE x.ad_window_id = v_window_id
        AND x.ad_role_id = wa.ad_role_id
        AND x.ad_client_id = wa.ad_client_id
    );

  RAISE NOTICE 'SAW016 menu=% parent=% window=%', v_menu_id, v_parent_id, v_window_id;
END $$;
