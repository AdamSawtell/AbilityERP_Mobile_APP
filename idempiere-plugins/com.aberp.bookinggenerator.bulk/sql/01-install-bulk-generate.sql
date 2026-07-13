-- =============================================================================
-- SAW017 — Bulk Generate Bookings (additive AD)
-- =============================================================================
-- New process + optional toolbar button on Booking Generator.
-- Does NOT change existing Generate Bookings (AbERP_GenerateBookings) behaviour.
-- Resolves by UU / name. Never hardcodes target AD_*_ID across clients.
--
-- Fixed AbERP-owned UUs:
--   Process          17a01701-b017-4017-8017-000000000001
--   Para DateFrom    17a01702-b017-4017-8017-000000000002
--   Para DateTo      17a01703-b017-4017-8017-000000000003
--   Para Activity    17a01704-b017-4017-8017-000000000004
--   Para InclIrr     17a01705-b017-4017-8017-000000000005
--   Para InclSTR     17a01706-b017-4017-8017-000000000006
--   Para InvoiceRule 17a01707-b017-4017-8017-000000000007
--   Para ForceIR     17a01708-b017-4017-8017-000000000008
--   Para DocAction   17a01709-b017-4017-8017-000000000009
--   Element          17a01710-b017-4017-8017-000000000010
--   Column           17a01711-b017-4017-8017-000000000011
--   Field            17a01712-b017-4017-8017-000000000012
--   Menu             17a01713-b017-4017-8017-000000000013
-- =============================================================================

SET search_path TO adempiere;

ALTER TABLE aberp_bookinggenerator
  ADD COLUMN IF NOT EXISTS aberp_bulkgeneratebookings character(1);

-- ---------------------------------------------------------------------------
-- Process
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_uu CONSTANT TEXT := '17a01701-b017-4017-8017-000000000001';
  v_id INTEGER;
  v_help TEXT :=
    'Generates Service Bookings for active STANDARD Booking Generator rows in the selected period/block. '
    || 'Does not change the single-record Generate Bookings button. '
    || 'Requires com.aberp.servicebooking.generator (Generate Bookings) to be installed. '
    || 'Default excludes Irregular Hrs (STANDARD IRR*) and Short Term Respite / STA unless opted in. '
    || 'Excludes Templates, Programs of Support, Non Binding Offer doctypes, and *Do Not Use* activities.';
BEGIN
  SELECT ad_process_id INTO v_id FROM ad_process WHERE ad_process_uu = v_uu;
  IF v_id IS NULL THEN
    SELECT ad_process_id INTO v_id FROM ad_process WHERE value = 'AbERP_BG_BulkGenerateBookings' LIMIT 1;
  END IF;

  IF v_id IS NULL THEN
    INSERT INTO ad_process (
      ad_process_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      value, name, description, help,
      accesslevel, entitytype,
      isreport, isdirectprint,
      classname,
      isbetafunctionality, isserverprocess, showhelp,
      copyfromprocess, ad_process_uu,
      allowmultipleexecution, isprinterpreview
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_BG_BulkGenerateBookings', 'Bulk Generate Bookings',
      'Bulk/block generate Service Bookings from Booking Generator (Standards).',
      v_help,
      '3', 'Ab_ERP',
      'N', 'N',
      'com.aberp.bookinggenerator.bulk.BulkGenerateBookings',
      'N', 'N', 'Y',
      'N', v_uu,
      'P', 'N'
    );
  ELSE
    UPDATE ad_process SET
      value = 'AbERP_BG_BulkGenerateBookings',
      name = 'Bulk Generate Bookings',
      description = 'Bulk/block generate Service Bookings from Booking Generator (Standards).',
      help = v_help,
      classname = 'com.aberp.bookinggenerator.bulk.BulkGenerateBookings',
      showhelp = 'Y',
      entitytype = 'Ab_ERP',
      isactive = 'Y',
      updated = NOW(),
      updatedby = 100,
      ad_process_uu = COALESCE(NULLIF(ad_process_uu, ''), v_uu)
    WHERE ad_process_id = v_id;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- Parameters
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_process_id INTEGER;
  v_ref_yesno INTEGER;
  v_ref_invoice INTEGER;
  v_ref_docaction INTEGER;
  v_ref_activity INTEGER;
BEGIN
  SELECT ad_process_id INTO v_process_id FROM ad_process
  WHERE ad_process_uu = '17a01701-b017-4017-8017-000000000001';
  IF v_process_id IS NULL THEN
    RAISE EXCEPTION 'Bulk Generate Bookings process missing';
  END IF;

  SELECT ad_reference_id INTO v_ref_yesno FROM ad_reference WHERE name = '_YesNo' LIMIT 1;
  IF v_ref_yesno IS NULL THEN v_ref_yesno := 319; END IF;

  SELECT ad_reference_id INTO v_ref_invoice FROM ad_reference WHERE name = 'C_Order InvoiceRule' LIMIT 1;
  IF v_ref_invoice IS NULL THEN v_ref_invoice := 150; END IF;

  SELECT ad_reference_id INTO v_ref_docaction FROM ad_reference WHERE name = '_Document Action' LIMIT 1;
  IF v_ref_docaction IS NULL THEN v_ref_docaction := 135; END IF;

  SELECT ad_reference_id INTO v_ref_activity FROM ad_reference WHERE name = 'C_Activity' LIMIT 1;

  IF NOT EXISTS (SELECT 1 FROM ad_process_para WHERE ad_process_para_uu = '17a01702-b017-4017-8017-000000000002') THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, ad_process_id, seqno, ad_reference_id,
      columnname, iscentrallymaintained, fieldlength, ismandatory, isrange, entitytype,
      defaultvalue, ad_process_para_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process_Para' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Date From', 'Generation period start (applied to each selected BG)', v_process_id, 10, 15,
      'DateFrom', 'Y', 7, 'Y', 'N', 'Ab_ERP',
      NULL, '17a01702-b017-4017-8017-000000000002'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_process_para WHERE ad_process_para_uu = '17a01703-b017-4017-8017-000000000003') THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, ad_process_id, seqno, ad_reference_id,
      columnname, iscentrallymaintained, fieldlength, ismandatory, isrange, entitytype,
      defaultvalue, ad_process_para_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process_Para' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Date To', 'Generation period end', v_process_id, 20, 15,
      'DateTo', 'Y', 7, 'Y', 'N', 'Ab_ERP',
      NULL, '17a01703-b017-4017-8017-000000000003'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_process_para WHERE ad_process_para_uu = '17a01704-b017-4017-8017-000000000004') THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, ad_process_id, seqno, ad_reference_id, ad_reference_value_id,
      columnname, iscentrallymaintained, fieldlength, ismandatory, isrange, entitytype,
      defaultvalue, ad_process_para_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process_Para' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Activity', 'Optional block filter (e.g. Day Program). Blank = all matching Standards.', v_process_id, 30, 19,
      v_ref_activity,
      'C_Activity_ID', 'Y', 22, 'N', 'N', 'Ab_ERP',
      NULL, '17a01704-b017-4017-8017-000000000004'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_process_para WHERE ad_process_para_uu = '17a01705-b017-4017-8017-000000000005') THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, ad_process_id, seqno, ad_reference_id,
      columnname, iscentrallymaintained, fieldlength, ismandatory, isrange, entitytype,
      defaultvalue, ad_process_para_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process_Para' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Include Irregular Hrs', 'Include Description STANDARD IRR* (default No)', v_process_id, 40, v_ref_yesno,
      'AbERP_IncludeIrregular', 'N', 1, 'Y', 'N', 'Ab_ERP',
      'N', '17a01705-b017-4017-8017-000000000005'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_process_para WHERE ad_process_para_uu = '17a01706-b017-4017-8017-000000000006') THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, ad_process_id, seqno, ad_reference_id,
      columnname, iscentrallymaintained, fieldlength, ismandatory, isrange, entitytype,
      defaultvalue, ad_process_para_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process_Para' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Include Short Term Respite', 'Include STR / Short Term Accommodation (default No)', v_process_id, 50, v_ref_yesno,
      'AbERP_IncludeSTR', 'N', 1, 'Y', 'N', 'Ab_ERP',
      'N', '17a01706-b017-4017-8017-000000000006'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_process_para WHERE ad_process_para_uu = '17a01707-b017-4017-8017-000000000007') THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, ad_process_id, seqno, ad_reference_id, ad_reference_value_id,
      columnname, iscentrallymaintained, fieldlength, ismandatory, isrange, entitytype,
      defaultvalue, ad_process_para_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process_Para' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Invoice Rule', 'Applied to newly generated Service Bookings when Force is Yes', v_process_id, 60, 17, v_ref_invoice,
      'InvoiceRule', 'Y', 1, 'N', 'N', 'Ab_ERP',
      'I', '17a01707-b017-4017-8017-000000000007'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_process_para WHERE ad_process_para_uu = '17a01708-b017-4017-8017-000000000008') THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, ad_process_id, seqno, ad_reference_id,
      columnname, iscentrallymaintained, fieldlength, ismandatory, isrange, entitytype,
      defaultvalue, ad_process_para_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process_Para' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Force Invoice Rule', 'Set Invoice Rule on generated Service Bookings', v_process_id, 70, v_ref_yesno,
      'AbERP_ForceInvoiceRule', 'N', 1, 'Y', 'N', 'Ab_ERP',
      'Y', '17a01708-b017-4017-8017-000000000008'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_process_para WHERE ad_process_para_uu = '17a01709-b017-4017-8017-000000000009') THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, ad_process_id, seqno, ad_reference_id, ad_reference_value_id,
      columnname, iscentrallymaintained, fieldlength, ismandatory, isrange, entitytype,
      defaultvalue, ad_process_para_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process_Para' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Document Action', 'Passed through to Generate Bookings (default Draft)', v_process_id, 80, 17, v_ref_docaction,
      'DocAction', 'Y', 2, 'Y', 'N', 'Ab_ERP',
      'DR', '17a01709-b017-4017-8017-000000000009'
    );
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- Element + button column + field on Booking Generator (new only)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_el_uu CONSTANT TEXT := '17a01710-b017-4017-8017-000000000010';
  v_col_uu CONSTANT TEXT := '17a01711-b017-4017-8017-000000000011';
  v_field_uu CONSTANT TEXT := '17a01712-b017-4017-8017-000000000012';
  v_el_id INTEGER;
  v_table_id INTEGER;
  v_col_id INTEGER;
  v_process_id INTEGER;
  v_tab_id INTEGER;
  v_window_id INTEGER;
  v_field_id INTEGER;
BEGIN
  SELECT ad_process_id INTO v_process_id FROM ad_process
  WHERE ad_process_uu = '17a01701-b017-4017-8017-000000000001';

  SELECT ad_element_id INTO v_el_id FROM ad_element WHERE ad_element_uu = v_el_uu;
  IF v_el_id IS NULL THEN
    SELECT ad_element_id INTO v_el_id FROM ad_element WHERE columnname = 'AbERP_BulkGenerateBookings' LIMIT 1;
  END IF;
  IF v_el_id IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, description, help, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_BulkGenerateBookings', 'Ab_ERP', 'Bulk Generate Bookings', 'Bulk Generate Bookings',
      'Bulk/block generate Service Bookings from matching STANDARD Booking Generators',
      'Additive process — does not replace Generate Bookings',
      v_el_uu
    );
    SELECT ad_element_id INTO v_el_id FROM ad_element WHERE ad_element_uu = v_el_uu;
  END IF;

  SELECT ad_table_id INTO v_table_id FROM ad_table WHERE tablename = 'AbERP_BookingGenerator';
  IF v_table_id IS NULL THEN
    RAISE EXCEPTION 'Table AbERP_BookingGenerator not found';
  END IF;

  SELECT ad_column_id INTO v_col_id FROM ad_column WHERE ad_column_uu = v_col_uu;
  IF v_col_id IS NULL THEN
    SELECT ad_column_id INTO v_col_id FROM ad_column
    WHERE ad_table_id = v_table_id AND columnname = 'AbERP_BulkGenerateBookings' LIMIT 1;
  END IF;

  IF v_col_id IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, entitytype, columnname, ad_table_id,
      ad_reference_id, fieldlength, version,
      iskey, isparent, ismandatory, isupdateable, isidentifier, seqno,
      istranslated, isencrypted, isselectioncolumn,
      ad_element_id, ad_process_id, issyncdatabase, isalwaysupdateable,
      isautocomplete, isallowlogging, isallowcopy, seqnoselection,
      istoolbarbutton, issecure, fkconstrainttype,
      ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Bulk Generate Bookings', 'Bulk/block generate Service Bookings', 'Ab_ERP', 'AbERP_BulkGenerateBookings', v_table_id,
      28, 1, 0,
      'N', 'N', 'N', 'Y', 'N', 0,
      'N', 'N', 'N',
      v_el_id, v_process_id, 'Y', 'N',
      'N', 'Y', 'N', 0,
      'B', 'N', 'N',
      v_col_uu
    );
  ELSE
    UPDATE ad_column SET
      ad_process_id = v_process_id,
      istoolbarbutton = 'B',
      isactive = 'Y',
      updated = NOW(),
      updatedby = 100,
      ad_column_uu = COALESCE(NULLIF(ad_column_uu, ''), v_col_uu)
    WHERE ad_column_id = v_col_id;
  END IF;

  SELECT ad_column_id INTO v_col_id FROM ad_column
  WHERE ad_table_id = v_table_id AND columnname = 'AbERP_BulkGenerateBookings';

  SELECT w.ad_window_id INTO v_window_id FROM ad_window w
  WHERE w.ad_window_uu = 'de336034-bd4e-4445-b018-9c762c98d847' OR w.name = 'Booking Generator'
  ORDER BY CASE WHEN w.ad_window_uu = 'de336034-bd4e-4445-b018-9c762c98d847' THEN 0 ELSE 1 END
  LIMIT 1;

  IF v_window_id IS NULL THEN
    RAISE EXCEPTION 'Window Booking Generator not found';
  END IF;

  SELECT t.ad_tab_id INTO v_tab_id FROM ad_tab t
  WHERE t.ad_window_id = v_window_id AND t.ad_table_id = v_table_id AND t.isactive = 'Y'
  ORDER BY t.seqno LIMIT 1;

  IF v_tab_id IS NULL THEN
    RAISE EXCEPTION 'Booking Generator header tab not found';
  END IF;

  SELECT ad_field_id INTO v_field_id FROM ad_field WHERE ad_field_uu = v_field_uu;
  IF v_field_id IS NULL THEN
    SELECT ad_field_id INTO v_field_id FROM ad_field
    WHERE ad_tab_id = v_tab_id AND ad_column_id = v_col_id LIMIT 1;
  END IF;

  IF v_field_id IS NULL THEN
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, iscentrallymaintained, ad_tab_id, ad_column_id,
      isdisplayed, displaylength, seqno, sortno, isreadonly, isheading, isfieldonly,
      entitytype, ad_field_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Bulk Generate Bookings', 'Bulk/block generate Service Bookings', 'Y', v_tab_id, v_col_id,
      'Y', 1, 9990, NULL, 'N', 'N', 'N',
      'Ab_ERP', v_field_uu
    );
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- Menu (under Ability ERP summary if present, else root)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_menu_uu CONSTANT TEXT := '17a01713-b017-4017-8017-000000000013';
  v_menu_id INTEGER;
  v_process_id INTEGER;
  v_parent_id INTEGER;
  v_tree_id INTEGER;
  v_node_id INTEGER;
BEGIN
  SELECT ad_process_id INTO v_process_id FROM ad_process
  WHERE ad_process_uu = '17a01701-b017-4017-8017-000000000001';

  SELECT ad_menu_id INTO v_menu_id FROM ad_menu WHERE ad_menu_uu = v_menu_uu;
  IF v_menu_id IS NULL THEN
    SELECT ad_menu_id INTO v_menu_id FROM ad_menu WHERE name = 'Bulk Generate Bookings' AND action = 'P' LIMIT 1;
  END IF;

  IF v_menu_id IS NULL THEN
    INSERT INTO ad_menu (
      ad_menu_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, description, issummary, issotrx, isreadonly, action, ad_process_id,
      entitytype, iscentrallymaintained, ad_menu_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Menu' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Bulk Generate Bookings', 'Bulk/block generate Service Bookings from Booking Generator',
      'N', 'Y', 'N', 'P', v_process_id,
      'Ab_ERP', 'Y', v_menu_uu
    );
    SELECT ad_menu_id INTO v_menu_id FROM ad_menu WHERE ad_menu_uu = v_menu_uu;
  ELSE
    UPDATE ad_menu SET
      ad_process_id = v_process_id,
      action = 'P',
      isactive = 'Y',
      updated = NOW(),
      updatedby = 100,
      ad_menu_uu = COALESCE(NULLIF(ad_menu_uu, ''), v_menu_uu)
    WHERE ad_menu_id = v_menu_id;
  END IF;

  SELECT ad_tree_id INTO v_tree_id FROM ad_tree WHERE treetype = 'MM' AND ad_client_id = 0 ORDER BY ad_tree_id LIMIT 1;
  SELECT ad_menu_id INTO v_parent_id FROM ad_menu WHERE issummary = 'Y' AND name = 'Ability ERP' AND isactive = 'Y' LIMIT 1;
  IF v_parent_id IS NULL THEN
    v_parent_id := 0;
  END IF;

  IF v_tree_id IS NOT NULL AND v_menu_id IS NOT NULL THEN
    SELECT node_id INTO v_node_id FROM ad_treenodemm WHERE ad_tree_id = v_tree_id AND node_id = v_menu_id;
    IF v_node_id IS NULL THEN
      INSERT INTO ad_treenodemm (ad_tree_id, node_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby, parent_id, seqno)
      VALUES (v_tree_id, v_menu_id, 0, 0, 'Y', NOW(), 100, NOW(), 100, v_parent_id, 999);
    END IF;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- Access: Admin + AbilityERP Admin by role name
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_process_id INTEGER;
  r RECORD;
BEGIN
  SELECT ad_process_id INTO v_process_id FROM ad_process
  WHERE ad_process_uu = '17a01701-b017-4017-8017-000000000001';
  IF v_process_id IS NULL THEN
    RAISE EXCEPTION 'Bulk process missing for access grant';
  END IF;

  FOR r IN
    SELECT ad_role_id FROM ad_role
    WHERE isactive = 'Y' AND name IN ('Admin', 'AbilityERP Admin', 'GardenWorld Admin', 'System Administrator')
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM ad_process_access WHERE ad_process_id = v_process_id AND ad_role_id = r.ad_role_id
    ) THEN
      INSERT INTO ad_process_access (
        ad_process_id, ad_role_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, isreadwrite
      ) VALUES (
        v_process_id, r.ad_role_id, 0, 0, 'Y', NOW(), 100, NOW(), 100, 'Y'
      );
    ELSE
      UPDATE ad_process_access SET isactive = 'Y', isreadwrite = 'Y', updated = NOW()
      WHERE ad_process_id = v_process_id AND ad_role_id = r.ad_role_id;
    END IF;
  END LOOP;
END $$;
