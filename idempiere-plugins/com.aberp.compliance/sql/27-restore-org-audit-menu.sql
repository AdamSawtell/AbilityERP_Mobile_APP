-- SAW024-27 — Restore Organisation Audit menu group (items gone after leaf moved to Ability ERP root)
-- Folder renamed Organisation Audit; window leaf = Audit Hub (must differ from folder or ZK hides it).
SET search_path TO adempiere;

DO $$
DECLARE
  v_ability   INTEGER;
  v_folder    INTEGER;
  v_window_m  INTEGER;
  v_rules_m   INTEGER;
  v_results_m INTEGER;
  v_tree      INTEGER := 10;
BEGIN
  SELECT m.ad_menu_id INTO v_ability
  FROM ad_menu m
  JOIN ad_treenodemm tn ON tn.node_id = m.ad_menu_id AND tn.ad_tree_id = v_tree
  WHERE m.name = 'Ability ERP' AND m.issummary = 'Y'
  ORDER BY m.ad_menu_id
  LIMIT 1;
  IF v_ability IS NULL THEN
    RAISE EXCEPTION 'SAW024-27: Ability ERP menu folder missing';
  END IF;

  SELECT ad_menu_id INTO v_folder
  FROM ad_menu
  WHERE ad_menu_uu = '23a02330-c0d4-4f01-8e15-000000000001';
  IF v_folder IS NULL THEN
    RAISE EXCEPTION 'SAW024-27: Organisation Audit folder UU missing';
  END IF;

  SELECT ad_menu_id INTO v_window_m
  FROM ad_menu
  WHERE ad_menu_uu = '23a02331-c0d4-4f01-8e15-000000000001';
  IF v_window_m IS NULL THEN
    RAISE EXCEPTION 'SAW024-27: Audit Hub window menu UU missing';
  END IF;

  SELECT ad_menu_id INTO v_rules_m
  FROM ad_menu
  WHERE ad_menu_uu = '23a02332-c0d4-4f01-8e15-000000000001';
  SELECT ad_menu_id INTO v_results_m
  FROM ad_menu
  WHERE ad_menu_uu = '23a02361-c0d4-4f01-8e15-000000000001';

  -- Folder: Organisation Audit (the rename users look for)
  UPDATE ad_menu SET
    name = 'Organisation Audit',
    description = 'Organisation Audit hub — readiness, rules, and results',
    issummary = 'Y',
    isactive = 'Y',
    updated = NOW()
  WHERE ad_menu_id = v_folder;

  -- Window leaf must NOT share the folder name (ZK drops the duplicate)
  UPDATE ad_menu SET
    name = 'Audit Hub',
    description = 'NDIS Organisation Audit — KPIs, Employee Open Findings',
    issummary = 'N',
    isactive = 'Y',
    updated = NOW()
  WHERE ad_menu_id = v_window_m;

  UPDATE ad_menu_trl SET
    name = 'Organisation Audit',
    description = 'Organisation Audit hub — readiness, rules, and results',
    istranslated = 'Y',
    updated = NOW()
  WHERE ad_menu_id = v_folder AND ad_language = 'en_US';

  UPDATE ad_menu_trl SET
    name = 'Audit Hub',
    description = 'NDIS Organisation Audit — KPIs, Employee Open Findings',
    istranslated = 'Y',
    updated = NOW()
  WHERE ad_menu_id = v_window_m AND ad_language = 'en_US';

  -- Folder under Ability ERP (visible seq near other AbERP groups)
  UPDATE ad_treenodemm SET
    parent_id = v_ability,
    seqno = 27,
    updated = NOW(),
    updatedby = 100
  WHERE ad_tree_id = v_tree AND node_id = v_folder;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'SAW024-27: treenode missing for Organisation Audit folder %', v_folder;
  END IF;

  -- Children under Organisation Audit folder
  UPDATE ad_treenodemm SET
    parent_id = v_folder,
    seqno = 10,
    updated = NOW(),
    updatedby = 100
  WHERE ad_tree_id = v_tree AND node_id = v_window_m;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'SAW024-27: treenode missing for Audit Hub menu %', v_window_m;
  END IF;

  IF v_rules_m IS NOT NULL THEN
    UPDATE ad_treenodemm SET
      parent_id = v_folder,
      seqno = 20,
      updated = NOW(),
      updatedby = 100
    WHERE ad_tree_id = v_tree AND node_id = v_rules_m;
  END IF;

  IF v_results_m IS NOT NULL THEN
    UPDATE ad_treenodemm SET
      parent_id = v_folder,
      seqno = 30,
      updated = NOW(),
      updatedby = 100
    WHERE ad_tree_id = v_tree AND node_id = v_results_m;
  END IF;

  RAISE NOTICE 'SAW024-27 restored Organisation Audit folder=% hub=% rules=% results=%',
    v_folder, v_window_m, v_rules_m, v_results_m;
END $$;

SELECT m.name, m.action, m.issummary, p.name AS parent, tn.seqno
FROM ad_menu m
LEFT JOIN ad_treenodemm tn ON tn.node_id = m.ad_menu_id AND tn.ad_tree_id = 10
LEFT JOIN ad_menu p ON p.ad_menu_id = tn.parent_id
WHERE m.ad_menu_uu IN (
  '23a02330-c0d4-4f01-8e15-000000000001',
  '23a02331-c0d4-4f01-8e15-000000000001',
  '23a02332-c0d4-4f01-8e15-000000000001',
  '23a02361-c0d4-4f01-8e15-000000000001'
)
ORDER BY COALESCE(tn.parent_id, 0), tn.seqno;
