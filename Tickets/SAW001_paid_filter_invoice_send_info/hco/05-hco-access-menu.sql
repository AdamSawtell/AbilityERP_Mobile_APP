-- HCO SAW001 follow-up: grant Admin IW access + place menu under Ability ERP
-- Does NOT change any existing *_UU values.
SET search_path TO adempiere;

DO $$
DECLARE
  v_iw NUMERIC;
  v_menu NUMERIC;
  v_role NUMERIC;
  v_tree NUMERIC := 10;
  v_parent NUMERIC;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '8fb1cd46-ed81-4cb9-8b83-7662caed9e62';
  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'Info Window UU missing';
  END IF;

  SELECT ad_menu_id INTO v_menu
  FROM ad_menu
  WHERE ad_menu_uu = 'c1d2e3f4-a5b6-7788-9900-aabbccdde001';
  IF v_menu IS NULL THEN
    RAISE EXCEPTION 'Menu UU missing';
  END IF;

  -- Prefer Ability ERP summary folder by name (HCO-local ID may differ)
  SELECT m.ad_menu_id INTO v_parent
  FROM ad_menu m
  JOIN ad_treenodemm t ON t.node_id = m.ad_menu_id AND t.ad_tree_id = v_tree
  WHERE m.name = 'Ability ERP' AND m.issummary = 'Y' AND m.isactive = 'Y'
  ORDER BY m.ad_menu_id
  LIMIT 1;
  IF v_parent IS NULL THEN
    v_parent := 0;
  END IF;

  UPDATE ad_treenodemm
  SET parent_id = v_parent, seqno = 999, updated = NOW(), updatedby = 100
  WHERE ad_tree_id = v_tree AND node_id = v_menu;

  -- Grant Info Window access to Admin (by name) if missing
  SELECT ad_role_id INTO v_role FROM ad_role WHERE name = 'Admin' AND isactive = 'Y' ORDER BY ad_role_id LIMIT 1;
  IF v_role IS NULL THEN
    RAISE EXCEPTION 'Admin role not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM ad_infowindow_access
    WHERE ad_role_id = v_role AND ad_infowindow_id = v_iw
  ) THEN
    INSERT INTO ad_infowindow_access (
      ad_infowindow_id, ad_role_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby
    ) VALUES (
      v_iw, v_role, 0, 0, 'Y', NOW(), 100, NOW(), 100
    );
  ELSE
    UPDATE ad_infowindow_access
    SET isactive = 'Y', updated = NOW(), updatedby = 100
    WHERE ad_role_id = v_role AND ad_infowindow_id = v_iw;
  END IF;

  -- Ensure AbilityERP Admin still has access
  SELECT ad_role_id INTO v_role FROM ad_role WHERE name = 'AbilityERP Admin' AND isactive = 'Y' ORDER BY ad_role_id LIMIT 1;
  IF v_role IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM ad_infowindow_access WHERE ad_role_id = v_role AND ad_infowindow_id = v_iw
  ) THEN
    INSERT INTO ad_infowindow_access (
      ad_infowindow_id, ad_role_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby
    ) VALUES (
      v_iw, v_role, 0, 0, 'Y', NOW(), 100, NOW(), 100
    );
  END IF;

  UPDATE ad_infowindow SET updated = NOW(), updatedby = 100 WHERE ad_infowindow_id = v_iw;

  RAISE NOTICE 'HCO access/menu fix: iw=% menu=% parent=%', v_iw, v_menu, v_parent;
END $$;

SELECT m.name AS menu, t.parent_id, p.name AS parent_name
FROM ad_menu m
JOIN ad_treenodemm t ON t.node_id = m.ad_menu_id AND t.ad_tree_id = 10
LEFT JOIN ad_menu p ON p.ad_menu_id = t.parent_id
WHERE m.ad_menu_uu = 'c1d2e3f4-a5b6-7788-9900-aabbccdde001';

SELECT r.name, ia.isactive
FROM ad_infowindow_access ia
JOIN ad_role r ON r.ad_role_id = ia.ad_role_id
JOIN ad_infowindow iw ON iw.ad_infowindow_id = ia.ad_infowindow_id
WHERE iw.ad_infowindow_uu = '8fb1cd46-ed81-4cb9-8b83-7662caed9e62'
ORDER BY 1;
