-- =============================================================================
-- SAW019 — Menu + window access
-- Menu UU: 19a01906-c0d4-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_menu_id),0)+1 FROM ad_menu))
WHERE name='AD_Menu' AND istableid='Y';

DO $$
DECLARE
  v_menu_uu CONSTANT TEXT := '19a01906-c0d4-4f01-8e15-000000000001';
  v_window_id INTEGER;
  v_menu_id INTEGER;
  v_parent_id INTEGER := -1;
  v_seq INTEGER;
  v_ability INTEGER;
BEGIN
  SELECT ad_window_id INTO v_window_id
  FROM ad_window
  WHERE ad_window_uu = '19a01903-c0d4-4f01-8e15-000000000001'
     OR name = 'Invoice Capture'
  LIMIT 1;
  IF v_window_id IS NULL THEN
    RAISE EXCEPTION 'SAW019: Invoice Capture window missing — run 04 first';
  END IF;

  -- Prefer Ability ERP summary folder when present
  SELECT m.ad_menu_id INTO v_ability
  FROM ad_menu m
  WHERE m.issummary = 'Y' AND m.name IN ('Ability ERP', 'AbilityERP')
  ORDER BY m.ad_menu_id
  LIMIT 1;
  IF v_ability IS NOT NULL THEN
    v_parent_id := v_ability;
  END IF;

  SELECT ad_menu_id INTO v_menu_id FROM ad_menu WHERE ad_menu_uu = v_menu_uu;
  IF v_menu_id IS NULL THEN
    SELECT ad_menu_id INTO v_menu_id FROM ad_menu WHERE name = 'Invoice Capture' AND ad_window_id = v_window_id;
  END IF;

  IF v_menu_id IS NULL THEN
    INSERT INTO ad_menu (
      ad_menu_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, issummary, issotrx, isreadonly,
      action, ad_window_id, entitytype, ad_menu_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Menu' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Invoice Capture',
      'Capture and process vendor invoice PDFs',
      'N', 'N', 'N',
      'W', v_window_id, 'Ab_ERP', v_menu_uu
    ) RETURNING ad_menu_id INTO v_menu_id;
  ELSE
    UPDATE ad_menu SET
      name = 'Invoice Capture',
      ad_window_id = v_window_id,
      action = 'W',
      isactive = 'Y',
      entitytype = 'Ab_ERP',
      ad_menu_uu = COALESCE(ad_menu_uu, v_menu_uu),
      updated = NOW()
    WHERE ad_menu_id = v_menu_id;
  END IF;

  SELECT COALESCE(MAX(seqno), 0) + 10 INTO v_seq
  FROM ad_treenodemm WHERE parent_id = v_parent_id AND ad_tree_id = 10;

  IF NOT EXISTS (SELECT 1 FROM ad_treenodemm WHERE node_id = v_menu_id AND ad_tree_id = 10) THEN
    INSERT INTO ad_treenodemm (
      ad_tree_id, node_id, parent_id, seqno, ad_client_id, ad_org_id,
      created, createdby, updated, updatedby, isactive
    ) VALUES (
      10, v_menu_id, v_parent_id, v_seq, 0, 0, NOW(), 100, NOW(), 100, 'Y'
    );
  ELSE
    UPDATE ad_treenodemm SET
      parent_id = v_parent_id,
      updated = NOW()
    WHERE node_id = v_menu_id AND ad_tree_id = 10;
  END IF;

  INSERT INTO ad_window_access (
    ad_window_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, isreadwrite, ad_window_access_uu
  )
  SELECT v_window_id, r.ad_role_id, r.ad_client_id, 0, 'Y',
         NOW(), 100, NOW(), 100, 'Y', NULL
  FROM ad_role r
  WHERE r.name IN ('AbilityERP Admin', 'Admin', 'System Administrator')
    AND r.isactive = 'Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_window_access wa
      WHERE wa.ad_window_id = v_window_id
        AND wa.ad_role_id = r.ad_role_id
        AND wa.ad_client_id = r.ad_client_id
    );

  RAISE NOTICE 'SAW019 menu=% parent=% window=%', v_menu_id, v_parent_id, v_window_id;
END $$;
