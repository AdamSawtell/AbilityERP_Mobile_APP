-- Menu + tree node so Notification SR Invoice Send Info opens directly (Action=I).
-- Needed for smoke testing; Create From uses Logilite form which is missing on some hosts.

SET search_path TO adempiere;

DO $$
DECLARE
  v_menu NUMERIC;
  v_uu VARCHAR(36) := 'c1d2e3f4-a5b6-7788-9900-aabbccdde001';
  v_iw NUMERIC;
  v_seq INTEGER;
  v_tree NUMERIC;
  v_parent NUMERIC := 1000175;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '8fb1cd46-ed81-4cb9-8b83-7662caed9e62';

  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'Info Window not found';
  END IF;

  SELECT ad_menu_id INTO v_menu FROM ad_menu WHERE ad_menu_uu = v_uu;

  IF v_menu IS NULL THEN
    SELECT ad_menu_id INTO v_menu FROM ad_menu
    WHERE name = 'Notification SR Invoice Send Info' AND action = 'I'
    LIMIT 1;
  END IF;

  IF v_menu IS NULL THEN
    SELECT ad_sequence_id::integer INTO v_seq FROM ad_sequence WHERE name = 'AD_Menu' AND istableid = 'Y' LIMIT 1;
    UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_menu_id),0)+1 FROM ad_menu))
    WHERE ad_sequence_id = v_seq;
    v_menu := nextid(v_seq, 'N'::varchar);

    INSERT INTO ad_menu (
      ad_menu_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, issummary, issotrx, isreadonly, action, ad_infowindow_id,
      entitytype, ad_menu_uu, iscentrallymaintained
    ) VALUES (
      v_menu, 0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Notification SR Invoice Send Info',
      'Open invoice send Info Window (Paid filter)',
      'N', 'N', 'N', 'I', v_iw,
      'U', v_uu, 'Y'
    );
  ELSE
    UPDATE ad_menu SET
      name = 'Notification SR Invoice Send Info',
      action = 'I',
      ad_infowindow_id = v_iw,
      ad_menu_uu = v_uu,
      isactive = 'Y',
      updated = NOW(),
      updatedby = 100
    WHERE ad_menu_id = v_menu;
  END IF;

  SELECT ad_tree_id INTO v_tree FROM ad_tree WHERE treetype = 'MM' AND ad_client_id = 0 ORDER BY ad_tree_id LIMIT 1;
  SELECT parent_id INTO v_parent FROM ad_treenodemm WHERE node_id = 1000229 AND ad_tree_id = v_tree;
  IF v_parent IS NULL THEN
    v_parent := 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_treenodemm WHERE ad_tree_id = v_tree AND node_id = v_menu) THEN
    INSERT INTO ad_treenodemm (ad_tree_id, node_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby, parent_id, seqno)
    VALUES (v_tree, v_menu, 0, 0, 'Y', NOW(), 100, NOW(), 100, v_parent, 999);
  END IF;

  RAISE NOTICE 'Menu AD_Menu_ID=% InfoWindow=% tree=% parent=%', v_menu, v_iw, v_tree, v_parent;
END $$;
