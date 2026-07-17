-- =============================================================================
-- SAW027 — Open Activity button (SAW024-style record-to-record link)
-- Prefer dedicated AbERP_OpenActivity Button column + process zoom to Activity Viewer.
-- Hide Search C_ContactActivity_ID as primary "link" (often does not zoom correctly).
-- =============================================================================
SET search_path TO adempiere;

ALTER TABLE aberp_activityauditreview
  ADD COLUMN IF NOT EXISTS aberp_openactivity character(1) DEFAULT NULL;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';

DO $$
DECLARE
  v_tab INTEGER;
  v_table INTEGER;
  v_process INTEGER;
  v_col INTEGER;
  v_field INTEGER;
  v_elem INTEGER;
  v_proc_col INTEGER;
BEGIN
  SELECT ad_tab_id INTO v_tab FROM ad_tab WHERE ad_tab_uu = '27a02751-c0d4-4f01-8e15-000000000001';
  IF v_tab IS NULL THEN
    SELECT t.ad_tab_id INTO v_tab
    FROM ad_tab t
    JOIN ad_window w ON w.ad_window_id = t.ad_window_id
    WHERE w.name = 'Activity Audit Review' AND t.name = 'Reviews'
    LIMIT 1;
  END IF;
  SELECT ad_table_id INTO v_table FROM ad_table WHERE tablename = 'AbERP_ActivityAuditReview';
  SELECT ad_process_id INTO v_process FROM ad_process WHERE value = 'AbERP_ActivityAudit_OpenActivity';

  IF v_tab IS NULL OR v_table IS NULL OR v_process IS NULL THEN
    RAISE EXCEPTION 'SAW027-12: Review tab / table / Open Activity process missing';
  END IF;

  UPDATE ad_process SET
    name = 'Open Activity',
    description = 'Open the linked Contact Activity (Activity Viewer) for this review row',
    help = 'Opens Activity Viewer on the C_ContactActivity linked to this review.',
    classname = 'com.aberp.activityaudit.process.OpenActivity',
    showhelp = 'N',
    updated = NOW()
  WHERE ad_process_id = v_process;

  -- Element
  SELECT ad_element_id INTO v_elem FROM ad_element WHERE columnname = 'AbERP_OpenActivity';
  IF v_elem IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, description, help, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_OpenActivity', 'Ab_ERP', 'Open Activity', 'Open Activity',
      'Open linked Contact Activity',
      'Click to open Activity Viewer for the Activity linked to this review.',
      '27a027e1-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_element_id INTO v_elem;
  END IF;

  -- Dedicated Button column (physical — virtual buttons stay disabled)
  SELECT ad_column_id INTO v_col FROM ad_column
  WHERE ad_table_id = v_table AND columnname = 'AbERP_OpenActivity';
  IF v_col IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, version, entitytype, columnname, ad_table_id,
      ad_reference_id, fieldlength, iskey, isparent, ismandatory, isupdateable,
      isidentifier, seqno, istranslated, isencrypted, isselectioncolumn,
      ad_element_id, issyncdatabase, isalwaysupdateable, isallowcopy,
      ad_process_id, description, help, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Open Activity', 0, 'Ab_ERP', 'AbERP_OpenActivity', v_table,
      28, 1, 'N', 'N', 'N', 'Y',
      'N', 5, 'N', 'N', 'N',
      v_elem, 'N', 'Y', 'N',
      v_process,
      'Open linked Contact Activity',
      'Opens Activity Viewer for the C_ContactActivity on this review.',
      '27a02704-c027-4f01-8e15-000000000001'
    ) RETURNING ad_column_id INTO v_col;
  ELSE
    UPDATE ad_column SET
      ad_reference_id = 28,
      ad_process_id = v_process,
      columnsql = NULL,
      isupdateable = 'Y',
      isalwaysupdateable = 'Y',
      istoolbarbutton = 'B',
      fieldlength = 1,
      name = 'Open Activity',
      description = 'Open linked Contact Activity',
      help = 'Opens Activity Viewer for the C_ContactActivity on this review.',
      updated = NOW()
    WHERE ad_column_id = v_col;
  END IF;

  UPDATE ad_column SET istoolbarbutton = 'B', updated = NOW()
  WHERE ad_column_id = v_col AND COALESCE(istoolbarbutton,'') <> 'B';

  -- Field: visible on form + grid (early column like SAW024 Open & Fix)
  SELECT ad_field_id INTO v_field FROM ad_field WHERE ad_field_uu = '27a02751-f019-4f01-8e15-000000000001';
  IF v_field IS NULL THEN
    SELECT ad_field_id INTO v_field FROM ad_field
    WHERE ad_tab_id = v_tab AND ad_column_id = v_col;
  END IF;
  IF v_field IS NULL THEN
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, iscentrallymaintained, ad_tab_id, ad_column_id,
      isdisplayed, displaylength, isreadonly, seqno, issameline,
      isheading, isfieldonly, isencrypted, entitytype,
      isdisplayedgrid, seqnogrid, xposition, columnspan, numlines, ad_field_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Open Activity',
      'Open linked Contact Activity',
      'Click to open Activity Viewer for this review Activity.',
      'N', v_tab, v_col,
      'Y', 0, 'N', 15, 'Y',
      'N', 'N', 'N', 'Ab_ERP',
      'Y', 15, 4, 2, 1, '27a02751-f019-4f01-8e15-000000000001'
    );
    UPDATE ad_field SET istoolbarbutton = 'B', updated = NOW()
    WHERE ad_field_uu = '27a02751-f019-4f01-8e15-000000000001';
  ELSE
    UPDATE ad_field SET
      name = 'Open Activity',
      description = 'Open linked Contact Activity',
      help = 'Click to open Activity Viewer for this review Activity.',
      isdisplayed = 'Y',
      isdisplayedgrid = 'Y',
      isreadonly = 'N',
      istoolbarbutton = 'B',
      seqno = 15,
      seqnogrid = 15,
      issameline = 'Y',
      ad_field_uu = COALESCE(ad_field_uu, '27a02751-f019-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_field_id = v_field;
  END IF;

  -- Toolbar button (same pattern as SAW024 Open & Fix — Action W = window process)
  UPDATE ad_sequence SET currentnext = GREATEST(currentnext,
    (SELECT COALESCE(MAX(ad_toolbarbutton_id),0)+1 FROM ad_toolbarbutton))
  WHERE name='AD_ToolBarButton' AND istableid='Y';

  IF NOT EXISTS (
    SELECT 1 FROM ad_toolbarbutton WHERE ad_toolbarbutton_uu = '27a02790-c0d4-4f01-8e15-000000000001'
  ) AND NOT EXISTS (
    SELECT 1 FROM ad_toolbarbutton WHERE ad_tab_id = v_tab AND name = 'Open Activity'
  ) THEN
    INSERT INTO ad_toolbarbutton (
      ad_toolbarbutton_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, componentname, action, ad_tab_id, ad_process_id,
      seqno, isadvancedbutton, isaddseparator, entitytype, iscustomization,
      displaylogic, ad_toolbarbutton_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_ToolBarButton' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Open Activity', 'Open Activity', 'W', v_tab, v_process,
      10, 'N', 'N', 'Ab_ERP', 'N',
      NULL, '27a02790-c0d4-4f01-8e15-000000000001'
    );
  ELSE
    UPDATE ad_toolbarbutton SET
      name = 'Open Activity',
      componentname = 'Open Activity',
      action = 'W',
      ad_tab_id = v_tab,
      ad_process_id = v_process,
      isactive = 'Y',
      entitytype = 'Ab_ERP',
      ad_toolbarbutton_uu = COALESCE(ad_toolbarbutton_uu, '27a02790-c0d4-4f01-8e15-000000000001'),
      updated = NOW()
    WHERE ad_toolbarbutton_uu = '27a02790-c0d4-4f01-8e15-000000000001'
       OR (ad_tab_id = v_tab AND name = 'Open Activity');
  END IF;

  -- Hide legacy Processing button field (keep column for old packs; unbind process)
  SELECT ad_column_id INTO v_proc_col FROM ad_column
  WHERE ad_table_id = v_table AND columnname = 'Processing';
  IF v_proc_col IS NOT NULL THEN
    UPDATE ad_column SET
      ad_process_id = NULL,
      name = 'Processing',
      updated = NOW()
    WHERE ad_column_id = v_proc_col;
    UPDATE ad_field SET
      isdisplayed = 'N',
      isdisplayedgrid = 'N',
      updated = NOW()
    WHERE ad_tab_id = v_tab AND ad_column_id = v_proc_col;
  END IF;

  -- Hide Search Activity PK as clickable link — use Open Activity button instead
  UPDATE ad_field SET
    name = 'Activity ID',
    isdisplayed = 'N',
    isdisplayedgrid = 'N',
    isreadonly = 'Y',
    updated = NOW()
  WHERE ad_tab_id = v_tab
    AND ad_column_id = (
      SELECT ad_column_id FROM ad_column
      WHERE ad_table_id = v_table AND columnname = 'C_ContactActivity_ID'
    );

  -- Tab must be writable for button to fire
  UPDATE ad_tab SET isreadonly = 'N', updated = NOW() WHERE ad_tab_id = v_tab;

  RAISE NOTICE 'SAW027-12 Open Activity button ready (tab=%)', v_tab;
END $$;
