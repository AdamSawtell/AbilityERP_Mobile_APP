-- SAW024-33 — Open Findings under all category tabs (Client / Incidents / Rostering / Documentation)
-- Clones Employee Open Findings pattern: Included_Tab_ID + TabLevel 2 + category whereclause + Open & Fix
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_tab_id),0)+1 FROM ad_tab))
WHERE name='AD_Tab' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_toolbarbutton_id),0)+1 FROM ad_toolbarbutton))
WHERE name='AD_ToolBarButton' AND istableid='Y';

-- Keep parent link populated
UPDATE aberp_complianceresult
SET aberp_compliancedashboard_id = ad_client_id
WHERE aberp_compliancedashboard_id IS NULL;

DO $$
DECLARE
  v_window_id INTEGER;
  v_result_table INTEGER;
  v_dash_pk INTEGER;
  v_link_col INTEGER;
  v_process_id INTEGER;
  v_btn_col INTEGER;
  v_template_tab INTEGER;
  r RECORD;
  v_parent_tab INTEGER;
  v_find_tab INTEGER;
  v_ttb INTEGER;
  f RECORD;
  v_field_id INTEGER;
  v_field_uu TEXT;
  v_where TEXT;
BEGIN
  SELECT ad_window_id INTO v_window_id
  FROM ad_window
  WHERE ad_window_uu = '23a02305-c0d4-4f01-8e15-000000000001'
     OR name = 'NDIS Audit Tool'
  LIMIT 1;
  IF v_window_id IS NULL THEN
    RAISE EXCEPTION 'SAW024-33: NDIS Audit Tool window missing';
  END IF;

  SELECT ad_table_id INTO v_result_table FROM ad_table WHERE tablename = 'AbERP_ComplianceResult';
  SELECT ad_column_id INTO v_dash_pk
  FROM ad_column
  WHERE ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_ComplianceDashboard')
    AND columnname = 'AbERP_ComplianceDashboard_ID';
  SELECT ad_column_id INTO v_link_col
  FROM ad_column
  WHERE ad_table_id = v_result_table AND columnname = 'AbERP_ComplianceDashboard_ID';
  SELECT ad_process_id INTO v_process_id FROM ad_process WHERE value = 'AbERP_Compliance_OpenSource';
  SELECT ad_column_id INTO v_btn_col
  FROM ad_column
  WHERE ad_table_id = v_result_table AND columnname = 'AbERP_OpenSource';
  SELECT ad_tab_id INTO v_template_tab
  FROM ad_tab WHERE ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001';

  IF v_result_table IS NULL OR v_link_col IS NULL OR v_template_tab IS NULL OR v_process_id IS NULL THEN
    RAISE EXCEPTION 'SAW024-33: prerequisite tabs/columns/process missing — run Employee Open Findings first';
  END IF;

  -- Ensure Open & Fix stays physical (not virtual)
  UPDATE ad_column SET
    columnsql = NULL,
    ad_reference_id = 28,
    ad_process_id = v_process_id,
    isupdateable = 'Y',
    isalwaysupdateable = 'Y',
    updated = NOW()
  WHERE ad_column_id = v_btn_col;

  FOR r IN
    SELECT * FROM (VALUES
      ('P', '23a02312-c0d4-4f01-8e15-000000000001', 'Client',
       '24a02411-c0d4-4f01-8e15-000000000001', 35,
       '24a02461-c0d4-4f01-8e15-000000000001',
       'Client Findings',
       'Client open findings — risks, service agreements, and related sources'),
      ('I', '23a02313-c0d4-4f01-8e15-000000000001', 'Incidents',
       '24a02412-c0d4-4f01-8e15-000000000001', 45,
       '24a02462-c0d4-4f01-8e15-000000000001',
       'Incident Findings',
       'Incident open findings — investigations and follow-up actions'),
      ('R', '23a02314-c0d4-4f01-8e15-000000000001', 'Rostering',
       '24a02413-c0d4-4f01-8e15-000000000001', 55,
       '24a02463-c0d4-4f01-8e15-000000000001',
       'Rostering Findings',
       'Rostering open findings — unfilled shifts and credential gaps'),
      ('D', '23a02315-c0d4-4f01-8e15-000000000001', 'Documentation',
       '24a02414-c0d4-4f01-8e15-000000000001', 65,
       '24a02464-c0d4-4f01-8e15-000000000001',
       'Documentation Findings',
       'Documentation open findings — onboarding / credential documents')
    ) AS t(cat, parent_uu, parent_name, find_uu, seqno, ttb_uu, find_name, help)
  LOOP
    SELECT ad_tab_id INTO v_parent_tab
    FROM ad_tab
    WHERE ad_tab_uu = r.parent_uu
       OR (ad_window_id = v_window_id AND name = r.parent_name)
    LIMIT 1;
    IF v_parent_tab IS NULL THEN
      RAISE EXCEPTION 'SAW024-33: parent tab % missing', r.parent_name;
    END IF;

    -- Parent must not be readonly or Open & Fix stays dead
    UPDATE ad_tab SET
      isreadonly = 'N',
      updated = NOW()
    WHERE ad_tab_id = v_parent_tab;
    UPDATE ad_field SET
      isreadonly = 'Y',
      updated = NOW()
    WHERE ad_tab_id = v_parent_tab;

    v_where := format(
      'AbERP_ComplianceRule_ID IN (SELECT AbERP_ComplianceRule_ID FROM AbERP_ComplianceRule WHERE ComplianceCategory=''%s'') AND IsResolved=''N'' AND IsActive=''Y''',
      r.cat);

    SELECT ad_tab_id INTO v_find_tab FROM ad_tab WHERE ad_tab_uu = r.find_uu;
    IF v_find_tab IS NULL THEN
      INSERT INTO ad_tab (
        ad_tab_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby,
        name, description, help, ad_table_id, ad_window_id,
        seqno, tablevel, issinglerow, isreadonly, isinsertrecord,
        isinfotab, istranslationtab, isadvancedtab,
        ad_column_id, parent_column_id,
        whereclause, orderbyclause, entitytype, ad_tab_uu
      ) VALUES (
        nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Tab' AND istableid = 'Y')::integer, 'N'),
        0, 0, 'Y', NOW(), 100, NOW(), 100,
        r.find_name,
        r.parent_name || ' open findings — why, resolve, open source',
        r.help,
        v_result_table, v_window_id,
        r.seqno, 2, 'N', 'N', 'N',
        'N', 'N', 'N',
        v_link_col, v_dash_pk,
        v_where,
        'Severity, DueDate, AbERP_ComplianceResult_ID',
        'Ab_ERP', r.find_uu
      ) RETURNING ad_tab_id INTO v_find_tab;
    ELSE
      UPDATE ad_tab SET
        name = r.find_name,
        description = r.parent_name || ' open findings — why, resolve, open source',
        help = r.help,
        ad_table_id = v_result_table,
        ad_window_id = v_window_id,
        seqno = r.seqno,
        tablevel = 2,
        issinglerow = 'N',
        isreadonly = 'N',
        isinsertrecord = 'N',
        ad_column_id = v_link_col,
        parent_column_id = v_dash_pk,
        whereclause = v_where,
        orderbyclause = 'Severity, DueDate, AbERP_ComplianceResult_ID',
        entitytype = 'Ab_ERP',
        isactive = 'Y',
        updated = NOW()
      WHERE ad_tab_id = v_find_tab;
    END IF;

    UPDATE ad_tab SET
      included_tab_id = v_find_tab,
      description = COALESCE(description, r.parent_name || ' compliance KPIs'),
      help = 'KPIs for this category. Open Findings underneath lists each open issue. Use Open & Fix to jump to the source record, then Refresh Compliance.',
      updated = NOW()
    WHERE ad_tab_id = v_parent_tab;

    -- Copy fields from Employee Open Findings template
    FOR f IN
      SELECT tf.*, c.columnname
      FROM ad_field tf
      JOIN ad_column c ON c.ad_column_id = tf.ad_column_id
      WHERE tf.ad_tab_id = v_template_tab AND tf.isactive = 'Y'
      ORDER BY tf.seqno, tf.ad_field_id
    LOOP
      -- UUID 8-4-4-4-12; prefix from findings tab UU, middle from column id
      v_field_uu := substr(r.find_uu, 1, 8) || '-'
        || lpad((f.ad_column_id % 10000)::text, 4, '0')
        || '-4f01-8e15-000000000001';

      SELECT ad_field_id INTO v_field_id
      FROM ad_field
      WHERE ad_field_uu = v_field_uu
         OR (ad_tab_id = v_find_tab AND ad_column_id = f.ad_column_id)
      LIMIT 1;

      IF v_field_id IS NULL THEN
        INSERT INTO ad_field (
          ad_field_id, ad_client_id, ad_org_id, isactive,
          created, createdby, updated, updatedby,
          name, description, help, iscentrallymaintained,
          ad_tab_id, ad_column_id,
          isdisplayed, displaylength, isreadonly, seqno, seqnogrid,
          issameline, isheading, isfieldonly, isencrypted, entitytype,
          isdisplayedgrid, xposition, columnspan, numlines,
          istoolbarbutton, ad_field_uu
        ) VALUES (
          nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
          0, 0, 'Y', NOW(), 100, NOW(), 100,
          f.name, f.description, f.help, COALESCE(f.iscentrallymaintained, 'N'),
          v_find_tab, f.ad_column_id,
          f.isdisplayed, COALESCE(f.displaylength, 0),
          CASE WHEN f.columnname = 'AbERP_OpenSource' THEN 'N' ELSE 'Y' END,
          f.seqno, COALESCE(f.seqnogrid, f.seqno),
          COALESCE(f.issameline, 'N'), COALESCE(f.isheading, 'N'),
          COALESCE(f.isfieldonly, 'N'), COALESCE(f.isencrypted, 'N'), 'Ab_ERP',
          f.isdisplayedgrid, COALESCE(f.xposition, 1), COALESCE(f.columnspan, 1), COALESCE(f.numlines, 1),
          f.istoolbarbutton, v_field_uu
        );
      ELSE
        UPDATE ad_field SET
          name = f.name,
          description = f.description,
          help = f.help,
          isdisplayed = f.isdisplayed,
          isdisplayedgrid = f.isdisplayedgrid,
          isreadonly = CASE WHEN f.columnname = 'AbERP_OpenSource' THEN 'N' ELSE 'Y' END,
          seqno = f.seqno,
          seqnogrid = COALESCE(f.seqnogrid, f.seqno),
          ad_field_uu = COALESCE(ad_field_uu, v_field_uu),
          isactive = 'Y',
          updated = NOW()
        WHERE ad_field_id = v_field_id;
      END IF;
    END LOOP;

    -- Category UX tweaks
    IF r.cat IN ('P', 'I', 'R') THEN
      -- Assignment Value often blank for non-CA sources — keep hidden; show Employee only when useful
      UPDATE ad_field SET
        name = 'Source',
        isdisplayed = 'N',
        isdisplayedgrid = 'N',
        updated = NOW()
      WHERE ad_tab_id = v_find_tab
        AND ad_column_id = (
          SELECT ad_column_id FROM ad_column
          WHERE ad_table_id = v_result_table AND columnname = 'AbERP_AssignmentLabel'
        );
    ELSE
      -- Documentation uses Credential Assignment like Employee
      UPDATE ad_field SET
        name = 'Assignment',
        isdisplayed = 'Y',
        isdisplayedgrid = 'Y',
        updated = NOW()
      WHERE ad_tab_id = v_find_tab
        AND ad_column_id = (
          SELECT ad_column_id FROM ad_column
          WHERE ad_table_id = v_result_table AND columnname = 'AbERP_AssignmentLabel'
        );
    END IF;

    UPDATE ad_field SET
      name = 'Open & Fix',
      isdisplayed = 'Y',
      isdisplayedgrid = 'Y',
      isreadonly = 'N',
      seqno = 5,
      seqnogrid = 5,
      updated = NOW()
    WHERE ad_tab_id = v_find_tab AND ad_column_id = v_btn_col;

    -- Toolbar Open & Fix
    SELECT ad_toolbarbutton_id INTO v_ttb
    FROM ad_toolbarbutton WHERE ad_toolbarbutton_uu = r.ttb_uu;
    IF v_ttb IS NULL THEN
      INSERT INTO ad_toolbarbutton (
        ad_toolbarbutton_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby,
        name, componentname, action, ad_tab_id, ad_process_id,
        seqno, isadvancedbutton, iscustomization, entitytype,
        ad_toolbarbutton_uu
      ) VALUES (
        nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_ToolBarButton' AND istableid = 'Y')::integer, 'N'),
        0, 0, 'Y', NOW(), 100, NOW(), 100,
        'Open & Fix', 'Open & Fix', 'W', v_find_tab, v_process_id,
        10, 'N', 'N', 'Ab_ERP',
        r.ttb_uu
      );
    ELSE
      UPDATE ad_toolbarbutton SET
        isactive = 'Y',
        name = 'Open & Fix',
        componentname = 'Open & Fix',
        action = 'W',
        ad_tab_id = v_find_tab,
        ad_process_id = v_process_id,
        seqno = 10,
        updated = NOW()
      WHERE ad_toolbarbutton_id = v_ttb;
    END IF;

    RAISE NOTICE 'SAW024-33 % Open Findings tab=% parent=%', r.parent_name, v_find_tab, v_parent_tab;
  END LOOP;

  -- Employee parent already nested; keep readonly off
  UPDATE ad_tab SET isreadonly = 'N', updated = NOW()
  WHERE ad_tab_uu = '23a02311-c0d4-4f01-8e15-000000000001';
END $$;

SELECT p.name AS parent, c.name AS child, c.tablevel, c.seqno,
       left(c.whereclause, 80) AS where_preview,
       (SELECT COUNT(*) FROM ad_field f WHERE f.ad_tab_id = c.ad_tab_id) AS fields
FROM ad_tab c
JOIN ad_tab p ON p.included_tab_id = c.ad_tab_id
WHERE c.ad_tab_uu LIKE '24a0241%'
ORDER BY c.seqno;
