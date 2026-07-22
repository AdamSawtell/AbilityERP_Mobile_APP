-- SAW032 — Clone Staff Rostering Info for SMS multi-select.
-- Source (Find & Fill, single-select): 2b4ab146-0809-47c6-96f3-8b841d60a6bf
-- Clone (SMS process, multi-select):   7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11
-- Idempotent: safe to re-run (skips if SMS UU already exists).
-- Multi-select is enforced in Java by UU (AD has no IsMultipleSelection on this build).
SET search_path TO adempiere;

DO $$
DECLARE
  v_src_uu CONSTANT varchar := '2b4ab146-0809-47c6-96f3-8b841d60a6bf';
  v_sms_uu CONSTANT varchar := '7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11';
  v_src_iw numeric;
  v_new_iw numeric;
  v_src_col record;
  v_new_col numeric;
  v_rel record;
  v_new_rel numeric;
  v_parent_new numeric;
BEGIN
  SELECT ad_infowindow_id INTO v_src_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = v_src_uu AND isactive = 'Y';
  IF v_src_iw IS NULL THEN
    RAISE EXCEPTION 'Source Staff Rostering Info UU % not found', v_src_uu;
  END IF;

  IF EXISTS (SELECT 1 FROM ad_infowindow WHERE ad_infowindow_uu = v_sms_uu) THEN
    RAISE NOTICE 'SMS Staff Rostering Info UU % already exists — skip clone', v_sms_uu;
    RETURN;
  END IF;

  v_new_iw := nextidfunc(
    (SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_InfoWindow' AND istableid = 'Y')::integer,
    'N');

  INSERT INTO ad_infowindow (
    ad_infowindow_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
    name, description, help, ad_table_id, entitytype, fromclause, otherclause, processing,
    ad_infowindow_uu, whereclause, isdefault, isdistinct, orderbyclause, isvalid,
    ad_ctxhelp_id, imageurl, seqno, isshowindashboard, ad_process_id, maxqueryrecords,
    isloadpagenum, pagingsize, pagesize, ischuboeshownotificationrun
  )
  SELECT
    v_new_iw, ad_client_id, ad_org_id, 'Y', NOW(), 100, NOW(), 100,
    'Employee (User) / Agency Staff Rostering Info (SMS)',
    COALESCE(description, '') || ' Multi-select clone for SMS. Do not use for Shift Employee Find & Fill.',
    COALESCE(help, '') || E'\nOpened from SMS process — multi-select contacts. Find & Fill uses the single-select Info Window.',
    ad_table_id, entitytype, fromclause, otherclause, processing,
    v_sms_uu, whereclause, 'N', isdistinct, orderbyclause, isvalid,
    ad_ctxhelp_id, imageurl, seqno, isshowindashboard, ad_process_id, maxqueryrecords,
    isloadpagenum, pagingsize, pagesize, ischuboeshownotificationrun
  FROM ad_infowindow
  WHERE ad_infowindow_id = v_src_iw;

  CREATE TEMP TABLE tmp_staffinfo_col_map (
    old_id numeric PRIMARY KEY,
    new_id numeric NOT NULL
  ) ON COMMIT DROP;

  FOR v_src_col IN
    SELECT * FROM ad_infocolumn
    WHERE ad_infowindow_id = v_src_iw
    ORDER BY seqno, ad_infocolumn_id
  LOOP
    v_new_col := nextidfunc(
      (SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_InfoColumn' AND istableid = 'Y')::integer,
      'N');
    INSERT INTO tmp_staffinfo_col_map(old_id, new_id) VALUES (v_src_col.ad_infocolumn_id, v_new_col);

    INSERT INTO ad_infocolumn (
      ad_infocolumn_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, help, ad_infowindow_id, entitytype, columnname, ad_element_id,
      ad_reference_id, ad_reference_value_id, ad_val_rule_id, selectclause,
      seqno, isdisplayed, isquerycriteria, isidentifier, ismandatory, iskey,
      iscentrallymaintained, queryfunction, queryoperator, defaultvalue, isreadonly,
      displaylogic, seqnoselection, ishideinfocolumn, ismultiselectcriteria,
      placeholder, inputfieldvalidation, ad_fieldstyle_id, tooltip_infocolumn_id,
      ad_infocolumn_uu
    )
    SELECT
      v_new_col, ad_client_id, ad_org_id, isactive, NOW(), 100, NOW(), 100,
      name, description, help, v_new_iw, entitytype, columnname, ad_element_id,
      ad_reference_id, ad_reference_value_id, ad_val_rule_id, selectclause,
      seqno, isdisplayed, isquerycriteria, isidentifier, ismandatory, iskey,
      iscentrallymaintained, queryfunction, queryoperator, defaultvalue, isreadonly,
      displaylogic, seqnoselection, ishideinfocolumn, ismultiselectcriteria,
      placeholder, inputfieldvalidation, ad_fieldstyle_id, NULL,
      generate_uuid()
    FROM ad_infocolumn
    WHERE ad_infocolumn_id = v_src_col.ad_infocolumn_id;
  END LOOP;

  -- Fix tooltip_infocolumn_id after all columns exist
  UPDATE ad_infocolumn c
  SET tooltip_infocolumn_id = m_new.new_id,
      updated = NOW(),
      updatedby = 100
  FROM tmp_staffinfo_col_map m_old
  JOIN ad_infocolumn src ON src.ad_infocolumn_id = m_old.old_id
  JOIN tmp_staffinfo_col_map m_new ON m_new.old_id = src.tooltip_infocolumn_id
  WHERE c.ad_infowindow_id = v_new_iw
    AND c.ad_infocolumn_id = m_old.new_id
    AND src.tooltip_infocolumn_id IS NOT NULL;

  INSERT INTO ad_infocolumn_trl (
    ad_infocolumn_id, ad_language, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, name, description, help, istranslated,
    ad_infocolumn_trl_uu, placeholder
  )
  SELECT
    m.new_id, t.ad_language, t.ad_client_id, t.ad_org_id, t.isactive,
    NOW(), 100, NOW(), 100, t.name, t.description, t.help, t.istranslated,
    generate_uuid(), t.placeholder
  FROM ad_infocolumn_trl t
  JOIN tmp_staffinfo_col_map m ON m.old_id = t.ad_infocolumn_id;

  FOR v_rel IN
    SELECT * FROM ad_inforelated
    WHERE ad_infowindow_id = v_src_iw
    ORDER BY seqno, ad_inforelated_id
  LOOP
    v_new_rel := nextidfunc(
      (SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_InfoRelated' AND istableid = 'Y')::integer,
      'N');
    SELECT new_id INTO v_parent_new FROM tmp_staffinfo_col_map WHERE old_id = v_rel.parentrelatedcolumn_id;

    INSERT INTO ad_inforelated (
      ad_inforelated_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, help, ad_infowindow_id, relatedinfo_id, relatedcolumn_id,
      parentrelatedcolumn_id, seqno, entitytype, ad_inforelated_uu
    ) VALUES (
      v_new_rel, v_rel.ad_client_id, v_rel.ad_org_id, v_rel.isactive, NOW(), 100, NOW(), 100,
      v_rel.name, v_rel.description, v_rel.help, v_new_iw, v_rel.relatedinfo_id,
      v_rel.relatedcolumn_id,
      COALESCE(v_parent_new, v_rel.parentrelatedcolumn_id),
      v_rel.seqno, v_rel.entitytype, generate_uuid()
    );
  END LOOP;

  INSERT INTO ad_infowindow_trl (
    ad_infowindow_id, ad_language, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, name, description, help, istranslated,
    ad_infowindow_trl_uu
  )
  SELECT
    v_new_iw, t.ad_language, t.ad_client_id, t.ad_org_id, t.isactive,
    NOW(), 100, NOW(), 100,
    'Employee (User) / Agency Staff Rostering Info (SMS)',
    COALESCE(t.description, '') || ' Multi-select for SMS.',
    t.help, 'Y', generate_uuid()
  FROM ad_infowindow_trl t
  WHERE t.ad_infowindow_id = v_src_iw;

  INSERT INTO ad_infowindow_access (
    ad_infowindow_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, ad_infowindow_access_uu
  )
  SELECT
    v_new_iw, a.ad_role_id, a.ad_client_id, a.ad_org_id, a.isactive,
    NOW(), 100, NOW(), 100, generate_uuid()
  FROM ad_infowindow_access a
  WHERE a.ad_infowindow_id = v_src_iw;

  RAISE NOTICE 'Cloned Staff Rostering Info SMS: AD_InfoWindow_ID=% UU=%', v_new_iw, v_sms_uu;
END $$;

-- Menu entry so SMS Info Window can be opened without the SMS process (idempotent).
DO $$
DECLARE
  v_sms_iw numeric;
  v_src_menu numeric;
  v_new_menu numeric;
  v_menu_uu CONSTANT varchar := 'a8f3c2d1-5e6b-4a7c-9d0e-1f2a3b4c5d6e';
  v_src_uu CONSTANT varchar := '2b4ab146-0809-47c6-96f3-8b841d60a6bf';
  v_sms_uu CONSTANT varchar := '7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11';
  v_tree record;
BEGIN
  SELECT ad_infowindow_id INTO v_sms_iw FROM ad_infowindow WHERE ad_infowindow_uu = v_sms_uu;
  IF v_sms_iw IS NULL THEN
    RAISE EXCEPTION 'SMS Info Window UU % missing — run clone first', v_sms_uu;
  END IF;

  IF EXISTS (SELECT 1 FROM ad_menu WHERE ad_menu_uu = v_menu_uu) THEN
    RAISE NOTICE 'SMS menu UU % already exists — skip', v_menu_uu;
    RETURN;
  END IF;

  SELECT ad_menu_id INTO v_src_menu
  FROM ad_menu
  WHERE ad_infowindow_id = (SELECT ad_infowindow_id FROM ad_infowindow WHERE ad_infowindow_uu = v_src_uu)
    AND action = 'I'
    AND isactive = 'Y'
  ORDER BY ad_menu_id
  LIMIT 1;

  IF v_src_menu IS NULL THEN
    RAISE NOTICE 'No source menu for Find & Fill Info — skip SMS menu';
    RETURN;
  END IF;

  v_new_menu := nextidfunc(
    (SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Menu' AND istableid = 'Y')::integer,
    'N');

  INSERT INTO ad_menu (
    ad_menu_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
    name, description, issummary, issotrx, isreadonly, action, entitytype,
    iscentrallymaintained, ad_menu_uu, ad_infowindow_id
  )
  SELECT
    v_new_menu, ad_client_id, ad_org_id, 'Y', NOW(), 100, NOW(), 100,
    'Employee (User) / Agency Staff Rostering Info (SMS)',
    'Multi-select clone for SMS. Do not use for Shift Find & Fill.',
    issummary, issotrx, isreadonly, 'I', entitytype,
    iscentrallymaintained, v_menu_uu, v_sms_iw
  FROM ad_menu WHERE ad_menu_id = v_src_menu;

  FOR v_tree IN
    SELECT ad_tree_id, parent_id, seqno FROM ad_treenodemm WHERE node_id = v_src_menu
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM ad_treenodemm WHERE ad_tree_id = v_tree.ad_tree_id AND node_id = v_new_menu
    ) THEN
      -- Prefer Rostering folder when present; else same parent as Find & Fill menu
      INSERT INTO ad_treenodemm (
        ad_tree_id, node_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, parent_id, seqno
      )
      SELECT
        v_tree.ad_tree_id, v_new_menu, 0, 0, 'Y',
        NOW(), 100, NOW(), 100,
        -- Same placement as "Staff Rostering Info Search" (parent 0) so HCO roles see it
        COALESCE(
          (SELECT t.parent_id FROM ad_treenodemm t
           JOIN ad_menu m ON m.ad_menu_id = t.node_id
           WHERE t.ad_tree_id = v_tree.ad_tree_id
             AND m.name ILIKE '%Staff Rostering Info Search%'
             AND m.action = 'I'
           LIMIT 1),
          v_tree.parent_id
        ),
        COALESCE(v_tree.seqno, 0) + 1;
    END IF;
  END LOOP;

  RAISE NOTICE 'Created SMS menu AD_Menu_ID=% UU=%', v_new_menu, v_menu_uu;
END $$;

SELECT ad_infowindow_id, name, ad_infowindow_uu, isactive, isvalid
FROM ad_infowindow
WHERE ad_infowindow_uu IN (
  '2b4ab146-0809-47c6-96f3-8b841d60a6bf',
  '7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11'
)
ORDER BY name;

SELECT iw.name, COUNT(c.*) AS columns, COUNT(DISTINCT r.ad_inforelated_id) AS related
FROM ad_infowindow iw
LEFT JOIN ad_infocolumn c ON c.ad_infowindow_id = iw.ad_infowindow_id
LEFT JOIN ad_inforelated r ON r.ad_infowindow_id = iw.ad_infowindow_id
WHERE iw.ad_infowindow_uu IN (
  '2b4ab146-0809-47c6-96f3-8b841d60a6bf',
  '7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11'
)
GROUP BY iw.name
ORDER BY 1;

SELECT m.ad_menu_id, m.name, m.ad_infowindow_id, m.ad_menu_uu
FROM ad_menu m
WHERE m.ad_menu_uu = 'a8f3c2d1-5e6b-4a7c-9d0e-1f2a3b4c5d6e';
