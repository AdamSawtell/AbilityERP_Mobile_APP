-- =============================================================================
-- SAW023 — Rename to NDIS Audit Tool + ensure Admin role window access
-- Window UU: 23a02305-…  Menu UU: 23a02331-…  Folder UU: 23a02330-…
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_win INTEGER;
  v_rules_win INTEGER;
  v_folder INTEGER;
  v_menu INTEGER;
  v_parent INTEGER := -1;
  v_ability INTEGER;
  v_seq INTEGER;
BEGIN
  SELECT ad_window_id INTO v_win
  FROM ad_window
  WHERE ad_window_uu = '23a02305-c0d4-4f01-8e15-000000000001'
  LIMIT 1;
  IF v_win IS NULL THEN
    SELECT ad_window_id INTO v_win
    FROM ad_window
    WHERE name IN ('Compliance Summary', 'NDIS Audit Tool')
    LIMIT 1;
  END IF;
  IF v_win IS NULL THEN
    RAISE EXCEPTION 'SAW023: main window missing';
  END IF;

  SELECT ad_window_id INTO v_rules_win
  FROM ad_window
  WHERE ad_window_uu = '23a02306-c0d4-4f01-8e15-000000000001'
     OR name = 'Compliance Rules'
  LIMIT 1;

  -- Window rename
  UPDATE ad_window SET
    name = 'NDIS Audit Tool',
    description = 'Organisation NDIS Audit Readiness — overall KPIs plus category tabs',
    help = 'Organisation Audit (header) shows organisation-wide readiness. Child tabs: Employee, Client, Incidents, Rostering, Documentation.',
    isactive = 'Y',
    entitytype = 'Ab_ERP',
    updated = NOW(),
    updatedby = 100
  WHERE ad_window_id = v_win;

  UPDATE ad_window_trl SET
    name = 'NDIS Audit Tool',
    description = 'Organisation NDIS Audit Readiness — overall KPIs plus category tabs',
    help = 'Organisation Audit (header) shows organisation-wide readiness. Child tabs: Employee, Client, Incidents, Rostering, Documentation.',
    istranslated = 'Y',
    updated = NOW()
  WHERE ad_window_id = v_win AND ad_language = 'en_US';

  IF NOT EXISTS (
    SELECT 1 FROM ad_window_trl WHERE ad_window_id = v_win AND ad_language = 'en_US'
  ) THEN
    INSERT INTO ad_window_trl (
      ad_window_id, ad_language, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby, name, description, help, istranslated
    ) VALUES (
      v_win, 'en_US', 0, 0, 'Y', NOW(), 100, NOW(), 100,
      'NDIS Audit Tool',
      'Organisation NDIS Audit Readiness — overall KPIs plus category tabs',
      'Organisation Audit (header) shows organisation-wide readiness. Child tabs: Employee, Client, Incidents, Rostering, Documentation.',
      'Y'
    );
  END IF;

  -- Menu folder under Ability ERP
  SELECT m.ad_menu_id INTO v_ability
  FROM ad_menu m
  WHERE m.issummary = 'Y' AND m.name IN ('Ability ERP', 'AbilityERP')
  ORDER BY CASE WHEN m.name = 'Ability ERP' THEN 0 ELSE 1 END, m.ad_menu_id
  LIMIT 1;
  IF v_ability IS NOT NULL THEN
    v_parent := v_ability;
  END IF;

  SELECT ad_menu_id INTO v_folder
  FROM ad_menu
  WHERE ad_menu_uu = '23a02330-c0d4-4f01-8e15-000000000001'
  LIMIT 1;
  IF v_folder IS NULL THEN
    SELECT ad_menu_id INTO v_folder
    FROM ad_menu
    WHERE name IN ('Compliance & Audit Hub', 'NDIS Audit Tool') AND issummary = 'Y'
    LIMIT 1;
  END IF;

  IF v_folder IS NULL THEN
    INSERT INTO ad_menu (
      ad_menu_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, issummary, issotrx, isreadonly,
      action, entitytype, ad_menu_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Menu' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'NDIS Audit Tool',
      'NDIS Audit Tool and related configuration',
      'Y', 'N', 'N',
      NULL, 'Ab_ERP', '23a02330-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_menu_id INTO v_folder;
  ELSE
    UPDATE ad_menu SET
      name = 'NDIS Audit Tool',
      description = 'NDIS Audit Tool and related configuration',
      issummary = 'Y',
      isactive = 'Y',
      entitytype = 'Ab_ERP',
      ad_menu_uu = COALESCE(ad_menu_uu, '23a02330-c0d4-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_menu_id = v_folder;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_treenodemm WHERE node_id = v_folder AND ad_tree_id = 10) THEN
    SELECT COALESCE(MAX(seqno), 0) + 10 INTO v_seq
    FROM ad_treenodemm WHERE parent_id = v_parent AND ad_tree_id = 10;
    INSERT INTO ad_treenodemm (ad_tree_id, node_id, parent_id, seqno, ad_client_id, ad_org_id, created, createdby, updated, updatedby, isactive)
    VALUES (10, v_folder, v_parent, v_seq, 0, 0, NOW(), 100, NOW(), 100, 'Y');
  ELSE
    UPDATE ad_treenodemm SET parent_id = v_parent, isactive = 'Y', updated = NOW()
    WHERE node_id = v_folder AND ad_tree_id = 10;
  END IF;

  -- Main window menu (same display name so search finds NDIS Audit Tool)
  SELECT ad_menu_id INTO v_menu
  FROM ad_menu
  WHERE ad_menu_uu = '23a02331-c0d4-4f01-8e15-000000000001'
  LIMIT 1;
  IF v_menu IS NULL THEN
    SELECT ad_menu_id INTO v_menu
    FROM ad_menu
    WHERE ad_window_id = v_win
    LIMIT 1;
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
      'NDIS Audit Tool',
      'Organisation NDIS Audit Readiness',
      'N', 'N', 'N',
      'W', v_win, 'Ab_ERP', '23a02331-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_menu_id INTO v_menu;
  ELSE
    UPDATE ad_menu SET
      name = 'NDIS Audit Tool',
      description = 'Organisation NDIS Audit Readiness',
      action = 'W',
      ad_window_id = v_win,
      issummary = 'N',
      isactive = 'Y',
      entitytype = 'Ab_ERP',
      ad_menu_uu = COALESCE(ad_menu_uu, '23a02331-c0d4-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_menu_id = v_menu;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_treenodemm WHERE node_id = v_menu AND ad_tree_id = 10) THEN
    INSERT INTO ad_treenodemm (ad_tree_id, node_id, parent_id, seqno, ad_client_id, ad_org_id, created, createdby, updated, updatedby, isactive)
    VALUES (10, v_menu, v_folder, 10, 0, 0, NOW(), 100, NOW(), 100, 'Y');
  ELSE
    UPDATE ad_treenodemm SET parent_id = v_folder, seqno = 10, isactive = 'Y', updated = NOW()
    WHERE node_id = v_menu AND ad_tree_id = 10;
  END IF;

  -- Menu translations (search index)
  INSERT INTO ad_menu_trl (
    ad_menu_id, ad_language, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, name, description, istranslated
  )
  SELECT m.ad_menu_id, 'en_US', 0, 0, 'Y', NOW(), 100, NOW(), 100, m.name, COALESCE(m.description, m.name), 'Y'
  FROM ad_menu m
  WHERE m.ad_menu_id IN (v_folder, v_menu)
    AND NOT EXISTS (
      SELECT 1 FROM ad_menu_trl t WHERE t.ad_menu_id = m.ad_menu_id AND t.ad_language = 'en_US'
    );

  UPDATE ad_menu_trl SET
    name = 'NDIS Audit Tool',
    description = 'Organisation NDIS Audit Readiness',
    istranslated = 'Y',
    updated = NOW()
  WHERE ad_menu_id IN (v_folder, v_menu) AND ad_language = 'en_US';

  -- Window access: Admin + AbilityERP Admin + System Administrator on every active client role of that name
  INSERT INTO ad_window_access (
    ad_window_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, isreadwrite, ad_window_access_uu
  )
  SELECT w.ad_window_id, r.ad_role_id, r.ad_client_id, 0, 'Y',
         NOW(), 100, NOW(), 100, 'Y', NULL
  FROM ad_role r
  CROSS JOIN LATERAL (
    SELECT v_win AS ad_window_id
    UNION ALL
    SELECT v_rules_win WHERE v_rules_win IS NOT NULL
  ) w
  WHERE r.name IN ('Admin', 'AbilityERP Admin', 'System Administrator')
    AND r.isactive = 'Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_window_access wa
      WHERE wa.ad_window_id = w.ad_window_id
        AND wa.ad_role_id = r.ad_role_id
        AND wa.ad_client_id = r.ad_client_id
    );

  -- Ensure existing Admin grants are active + read/write
  UPDATE ad_window_access wa SET
    isactive = 'Y',
    isreadwrite = 'Y',
    updated = NOW()
  FROM ad_role r
  WHERE wa.ad_role_id = r.ad_role_id
    AND wa.ad_client_id = r.ad_client_id
    AND r.name IN ('Admin', 'AbilityERP Admin', 'System Administrator')
    AND wa.ad_window_id IN (v_win, COALESCE(v_rules_win, -1));

  RAISE NOTICE 'SAW023 renamed to NDIS Audit Tool window=% menu=% folder=% parent=%',
    v_win, v_menu, v_folder, v_parent;
END $$;

SELECT w.name AS window, m.name AS menu, r.name AS role, r.ad_client_id, wa.isreadwrite
FROM ad_window w
JOIN ad_window_access wa ON wa.ad_window_id = w.ad_window_id
JOIN ad_role r ON r.ad_role_id = wa.ad_role_id AND r.ad_client_id = wa.ad_client_id
LEFT JOIN ad_menu m ON m.ad_window_id = w.ad_window_id AND m.ad_menu_uu = '23a02331-c0d4-4f01-8e15-000000000001'
WHERE w.ad_window_uu = '23a02305-c0d4-4f01-8e15-000000000001'
ORDER BY r.ad_client_id, r.name;
