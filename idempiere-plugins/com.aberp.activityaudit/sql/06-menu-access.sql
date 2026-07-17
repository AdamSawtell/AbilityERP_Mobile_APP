-- =============================================================================
-- SAW027 â€” Menu + window access
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_menu_id),0)+1 FROM ad_menu))
WHERE name='AD_Menu' AND istableid='Y';

DO $$
DECLARE
  v_folder_uu CONSTANT TEXT := '27a02780-c0d4-4f01-8e15-000000000001';
  v_folder_id INTEGER;
  v_parent_id INTEGER := -1;
  v_ability INTEGER;
  v_seq INTEGER;
  v_win INTEGER;
  v_menu INTEGER;
  rec RECORD;
BEGIN
  SELECT menu.ad_menu_id INTO v_ability
  FROM ad_menu menu
  WHERE menu.issummary = 'Y' AND menu.name IN ('Ability ERP', 'AbilityERP')
  ORDER BY CASE WHEN menu.name = 'Ability ERP' THEN 0 ELSE 1 END, menu.ad_menu_id
  LIMIT 1;
  IF v_ability IS NOT NULL THEN
    v_parent_id := v_ability;
  END IF;

  SELECT ad_menu_id INTO v_folder_id FROM ad_menu WHERE ad_menu_uu = v_folder_uu;
  IF v_folder_id IS NULL THEN
    SELECT ad_menu_id INTO v_folder_id FROM ad_menu
    WHERE name = 'Activity Audit' AND issummary = 'Y';
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
      'Activity Audit',
      'Configurable Activity keyword audit and review',
      'Y', 'N', 'N',
      NULL, 'Ab_ERP', v_folder_uu
    ) RETURNING ad_menu_id INTO v_folder_id;
  ELSE
    UPDATE ad_menu SET
      name = 'Activity Audit', issummary = 'Y', isactive = 'Y',
      entitytype = 'Ab_ERP', ad_menu_uu = COALESCE(ad_menu_uu, v_folder_uu), updated = NOW()
    WHERE ad_menu_id = v_folder_id;
  END IF;

  -- Tree node under Ability ERP
  IF v_parent_id > 0 THEN
    IF NOT EXISTS (
      SELECT 1 FROM ad_treenodemm WHERE node_id = v_folder_id
    ) THEN
      INSERT INTO ad_treenodemm (ad_tree_id, node_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, parent_id, seqno)
      SELECT (SELECT ad_tree_id FROM ad_tree WHERE treetype = 'MM' AND ad_client_id = 0 LIMIT 1),
             v_folder_id, 0, 0, 'Y', NOW(), 100, NOW(), 100, v_parent_id, 900;
    ELSE
      UPDATE ad_treenodemm SET parent_id = v_parent_id, updated = NOW()
      WHERE node_id = v_folder_id AND parent_id <> v_parent_id;
    END IF;
  END IF;

  FOR rec IN
    SELECT * FROM (VALUES
      ('27a02781-c0d4-4f01-8e15-000000000001', 'Activity Audit Terms', '27a02740-c0d4-4f01-8e15-000000000001', 10),
      ('27a02782-c0d4-4f01-8e15-000000000001', 'Activity Audit Review', '27a02750-c0d4-4f01-8e15-000000000001', 20),
      ('27a02783-c0d4-4f01-8e15-000000000001', 'Activity Audit Runs', '27a02760-c0d4-4f01-8e15-000000000001', 30)
    ) AS t(menu_uu, menu_name, win_uu, seq)
  LOOP
    SELECT ad_window_id INTO v_win FROM ad_window WHERE ad_window_uu = rec.win_uu OR name = rec.menu_name LIMIT 1;
    IF v_win IS NULL THEN
      RAISE EXCEPTION 'SAW027: window % missing', rec.menu_name;
    END IF;

    SELECT ad_menu_id INTO v_menu FROM ad_menu WHERE ad_menu_uu = rec.menu_uu;
    IF v_menu IS NULL THEN
      SELECT ad_menu_id INTO v_menu FROM ad_menu WHERE name = rec.menu_name AND ad_window_id = v_win;
    END IF;
    IF v_menu IS NULL THEN
      INSERT INTO ad_menu (
        ad_menu_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby,
        name, description, issummary, issotrx, isreadonly,
        action, ad_window_id, entitytype, ad_menu_uu
      ) VALUES (
        nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Menu' AND istableid = 'Y')::integer, 'N'),
        0, 0, 'Y', NOW(), 100, NOW(), 100,
        rec.menu_name, rec.menu_name, 'N', 'N', 'N',
        'W', v_win, 'Ab_ERP', rec.menu_uu
      ) RETURNING ad_menu_id INTO v_menu;
    ELSE
      UPDATE ad_menu SET ad_window_id = v_win, action = 'W', isactive = 'Y',
        ad_menu_uu = COALESCE(ad_menu_uu, rec.menu_uu), updated = NOW()
      WHERE ad_menu_id = v_menu;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ad_treenodemm WHERE node_id = v_menu) THEN
      INSERT INTO ad_treenodemm (ad_tree_id, node_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, parent_id, seqno)
      SELECT (SELECT ad_tree_id FROM ad_tree WHERE treetype = 'MM' AND ad_client_id = 0 LIMIT 1),
             v_menu, 0, 0, 'Y', NOW(), 100, NOW(), 100, v_folder_id, rec.seq;
    ELSE
      UPDATE ad_treenodemm SET parent_id = v_folder_id, seqno = rec.seq, updated = NOW()
      WHERE node_id = v_menu;
    END IF;
  END LOOP;

  -- Process menus
  FOR rec IN
    SELECT * FROM (VALUES
      ('27a02784-c0d4-4f01-8e15-000000000001', 'Activity Audit Nightly', 'AbERP_ActivityAudit_Nightly', 40),
      ('27a02785-c0d4-4f01-8e15-000000000001', 'Historical Activity Audit', 'AbERP_ActivityAudit_Historical', 50)
    ) AS t(menu_uu, menu_name, proc_value, seq)
  LOOP
    SELECT ad_menu_id INTO v_menu FROM ad_menu WHERE ad_menu_uu = rec.menu_uu;
    IF v_menu IS NULL THEN
      INSERT INTO ad_menu (
        ad_menu_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby,
        name, description, issummary, issotrx, isreadonly,
        action, ad_process_id, entitytype, ad_menu_uu
      )
      SELECT
        nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Menu' AND istableid = 'Y')::integer, 'N'),
        0, 0, 'Y', NOW(), 100, NOW(), 100,
        rec.menu_name, rec.menu_name, 'N', 'N', 'N',
        'P', p.ad_process_id, 'Ab_ERP', rec.menu_uu
      FROM ad_process p WHERE p.value = rec.proc_value
      RETURNING ad_menu_id INTO v_menu;
    END IF;

    IF v_menu IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ad_treenodemm WHERE node_id = v_menu) THEN
      INSERT INTO ad_treenodemm (ad_tree_id, node_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, parent_id, seqno)
      SELECT (SELECT ad_tree_id FROM ad_tree WHERE treetype = 'MM' AND ad_client_id = 0 LIMIT 1),
             v_menu, 0, 0, 'Y', NOW(), 100, NOW(), 100, v_folder_id, rec.seq;
    END IF;
  END LOOP;

  -- Window access
  INSERT INTO ad_window_access (
    ad_window_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, isreadwrite
  )
  SELECT w.ad_window_id, r.ad_role_id, r.ad_client_id, 0, 'Y',
         NOW(), 100, NOW(), 100, 'Y'
  FROM ad_role r
  CROSS JOIN (
    SELECT ad_window_id FROM ad_window
    WHERE ad_window_uu IN (
      '27a02740-c0d4-4f01-8e15-000000000001',
      '27a02750-c0d4-4f01-8e15-000000000001',
      '27a02760-c0d4-4f01-8e15-000000000001'
    )
  ) w
  WHERE r.name IN ('AbilityERP Admin', 'Admin', 'System Administrator')
    AND NOT EXISTS (
      SELECT 1 FROM ad_window_access x
      WHERE x.ad_window_id = w.ad_window_id AND x.ad_role_id = r.ad_role_id
    );

  RAISE NOTICE 'SAW027 menu/access ready';
END $$;
