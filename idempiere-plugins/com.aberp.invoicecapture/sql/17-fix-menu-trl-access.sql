-- =============================================================================
-- SAW019 — AD_*_Trl for Invoice Capture (menu/window/tab/field/process)
-- Under system languages (en_AU / es_CO), missing Menu_Trl can hide menu items.
-- =============================================================================
SET search_path TO adempiere;

-- Ensure Ability ERP / AbilityERP summary folders have Menu_Trl (parent must be visible)
INSERT INTO ad_menu_trl (
  ad_menu_id, ad_language, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, description, istranslated, ad_menu_trl_uu
)
SELECT m.ad_menu_id, l.ad_language, 0, 0, 'Y',
       NOW(), 100, NOW(), 100,
       m.name, m.description, 'N', generate_uuid()::text
FROM ad_menu m
CROSS JOIN ad_language l
WHERE m.issummary = 'Y'
  AND m.name IN ('Ability ERP', 'AbilityERP')
  AND l.issystemlanguage = 'Y' AND l.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_menu_trl t
    WHERE t.ad_menu_id = m.ad_menu_id AND t.ad_language = l.ad_language
  );

-- Menu
INSERT INTO ad_menu_trl (
  ad_menu_id, ad_language, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, description, istranslated, ad_menu_trl_uu
)
SELECT m.ad_menu_id, l.ad_language, 0, 0, 'Y',
       NOW(), 100, NOW(), 100,
       m.name, m.description, 'N', generate_uuid()::text
FROM ad_menu m
CROSS JOIN ad_language l
WHERE m.ad_menu_uu IN (
        '19a01906-c0d4-4f01-8e15-000000000001',
        '19a0190e-c0d4-4f01-8e15-000000000001'
      )
  AND l.issystemlanguage = 'Y' AND l.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_menu_trl t
    WHERE t.ad_menu_id = m.ad_menu_id AND t.ad_language = l.ad_language
  );

-- Window
INSERT INTO ad_window_trl (
  ad_window_id, ad_language, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, description, help, istranslated, ad_window_trl_uu
)
SELECT w.ad_window_id, l.ad_language, 0, 0, 'Y',
       NOW(), 100, NOW(), 100,
       w.name, w.description, w.help, 'N', generate_uuid()::text
FROM ad_window w
CROSS JOIN ad_language l
WHERE w.ad_window_uu = '19a01903-c0d4-4f01-8e15-000000000001'
  AND l.issystemlanguage = 'Y' AND l.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_window_trl t
    WHERE t.ad_window_id = w.ad_window_id AND t.ad_language = l.ad_language
  );

-- Tabs
INSERT INTO ad_tab_trl (
  ad_tab_id, ad_language, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, description, help, commitwarning, istranslated, ad_tab_trl_uu
)
SELECT tb.ad_tab_id, l.ad_language, 0, 0, 'Y',
       NOW(), 100, NOW(), 100,
       tb.name, tb.description, tb.help, tb.commitwarning, 'N', generate_uuid()::text
FROM ad_tab tb
JOIN ad_window w ON w.ad_window_id = tb.ad_window_id
CROSS JOIN ad_language l
WHERE w.ad_window_uu = '19a01903-c0d4-4f01-8e15-000000000001'
  AND l.issystemlanguage = 'Y' AND l.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_tab_trl t
    WHERE t.ad_tab_id = tb.ad_tab_id AND t.ad_language = l.ad_language
  );

-- Fields on those tabs
INSERT INTO ad_field_trl (
  ad_field_id, ad_language, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, description, help, istranslated, ad_field_trl_uu
)
SELECT f.ad_field_id, l.ad_language, 0, 0, 'Y',
       NOW(), 100, NOW(), 100,
       f.name, f.description, f.help, 'N', generate_uuid()::text
FROM ad_field f
JOIN ad_tab tb ON tb.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = tb.ad_window_id
CROSS JOIN ad_language l
WHERE w.ad_window_uu = '19a01903-c0d4-4f01-8e15-000000000001'
  AND l.issystemlanguage = 'Y' AND l.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_field_trl t
    WHERE t.ad_field_id = f.ad_field_id AND t.ad_language = l.ad_language
  );

-- Processes (Selected / Batch / Upload)
INSERT INTO ad_process_trl (
  ad_process_id, ad_language, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, description, help, istranslated, ad_process_trl_uu
)
SELECT p.ad_process_id, l.ad_language, 0, 0, 'Y',
       NOW(), 100, NOW(), 100,
       p.name, p.description, p.help, 'N', generate_uuid()::text
FROM ad_process p
CROSS JOIN ad_language l
WHERE p.ad_process_uu IN (
        '19a01908-c0d4-4f01-8e15-000000000001',
        '19a01909-c0d4-4f01-8e15-000000000001',
        '19a01910-c0d4-4f01-8e15-000000000001'
      )
  AND l.issystemlanguage = 'Y' AND l.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_process_trl t
    WHERE t.ad_process_id = p.ad_process_id AND t.ad_language = l.ad_language
  );

-- Ensure window access for AbilityERP Admin + Admin (+ System Administrator)
INSERT INTO ad_window_access (
  ad_window_id, ad_role_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby, isreadwrite, ad_window_access_uu
)
SELECT w.ad_window_id, r.ad_role_id, r.ad_client_id, 0, 'Y',
       NOW(), 100, NOW(), 100, 'Y', generate_uuid()::text
FROM ad_window w
CROSS JOIN ad_role r
WHERE w.ad_window_uu = '19a01903-c0d4-4f01-8e15-000000000001'
  AND r.name IN ('AbilityERP Admin', 'Admin', 'System Administrator')
  AND r.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_window_access wa
    WHERE wa.ad_window_id = w.ad_window_id
      AND wa.ad_role_id = r.ad_role_id
      AND wa.ad_client_id = r.ad_client_id
  );

-- Ensure menu tree node under Ability ERP (or AbilityERP) on garden Menu tree (10)
DO $$
DECLARE
  v_menu INTEGER;
  v_parent INTEGER := -1;
  v_seq INTEGER;
BEGIN
  SELECT ad_menu_id INTO v_menu FROM ad_menu
  WHERE ad_menu_uu = '19a01906-c0d4-4f01-8e15-000000000001';
  IF v_menu IS NULL THEN
    RAISE EXCEPTION 'SAW019: Invoice Capture menu missing';
  END IF;

  SELECT m.ad_menu_id INTO v_parent
  FROM ad_menu m
  WHERE m.issummary = 'Y' AND m.name IN ('Ability ERP', 'AbilityERP')
  ORDER BY CASE WHEN m.name = 'Ability ERP' THEN 0 ELSE 1 END, m.ad_menu_id
  LIMIT 1;

  SELECT COALESCE(MAX(seqno), 0) + 10 INTO v_seq
  FROM ad_treenodemm WHERE parent_id = COALESCE(v_parent, -1) AND ad_tree_id = 10;

  IF NOT EXISTS (SELECT 1 FROM ad_treenodemm WHERE node_id = v_menu AND ad_tree_id = 10) THEN
    INSERT INTO ad_treenodemm (
      ad_tree_id, node_id, parent_id, seqno, ad_client_id, ad_org_id,
      created, createdby, updated, updatedby, isactive
    ) VALUES (
      10, v_menu, COALESCE(v_parent, -1), v_seq, 0, 0, NOW(), 100, NOW(), 100, 'Y'
    );
  ELSE
    UPDATE ad_treenodemm SET
      parent_id = COALESCE(v_parent, parent_id),
      isactive = 'Y',
      updated = NOW()
    WHERE node_id = v_menu AND ad_tree_id = 10;
  END IF;

  UPDATE ad_menu SET isactive = 'Y', updated = NOW() WHERE ad_menu_id = v_menu;
END $$;

DO $$
DECLARE
  v_cnt INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_cnt
  FROM ad_menu m
  JOIN ad_menu_trl t ON t.ad_menu_id = m.ad_menu_id AND t.ad_language = 'en_AU'
  WHERE m.ad_menu_uu = '19a01906-c0d4-4f01-8e15-000000000001';
  IF v_cnt < 1 THEN
    RAISE EXCEPTION 'SAW019: Invoice Capture menu still missing en_AU Menu_Trl';
  END IF;
  RAISE NOTICE 'SAW019 menu en_AU trl OK; path Ability ERP → Invoice Capture';
END $$;
