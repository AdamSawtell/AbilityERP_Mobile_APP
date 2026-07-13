-- =============================================================================
-- SAW016 — Report view + process for Leave Planning export/print
-- Uses active criteria parameters (dates + all locations / location list).
-- Process UU: 16a01608-c0d4-4f01-8e15-000000000001
-- ReportView UU: 16a01609-c0d4-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

-- Reporting view (deduped leave + employee location)
CREATE OR REPLACE VIEW aberp_leave_planning_rv AS
SELECT
  ul.aberp_unavailability_leave_id,
  ul.ad_client_id,
  ul.ad_org_id,
  ul.isactive,
  ul.created,
  ul.createdby,
  ul.updated,
  ul.updatedby,
  ul.aberp_user_contact_id,
  u.value AS aberp_lp_employeenumber,
  u.name AS employee_name,
  bpl.c_bpartner_location_id,
  bpl.name AS aberp_lp_servicelocation,
  ul.aberp_unavailability_type_id,
  ut.name AS leave_type_name,
  ul.startdate,
  ul.enddate,
  ((ul.enddate::date - ul.startdate::date) + 1) AS aberp_lp_calendardays,
  ul.aberp_approverstatus,
  ul.aberp_submitterstatus,
  ul.note,
  (SELECT bp.supervisor_id FROM c_bpartner bp WHERE bp.c_bpartner_id = u.c_bpartner_id) AS aberp_currentsupervisor
FROM aberp_unavailability_leave ul
JOIN ad_user u ON u.ad_user_id = ul.aberp_user_contact_id
LEFT JOIN c_bpartner_location bpl ON bpl.c_bpartner_location_id = u.c_bpartner_location_id
LEFT JOIN aberp_unavailability_type ut ON ut.aberp_unavailability_type_id = ul.aberp_unavailability_type_id
WHERE ul.isactive = 'Y';

DO $$
DECLARE
  v_rv_uu CONSTANT TEXT := '16a01609-c0d4-4f01-8e15-000000000001';
  v_proc_uu CONSTANT TEXT := '16a01608-c0d4-4f01-8e15-000000000001';
  v_table_id INTEGER;
  v_rv_id INTEGER;
  v_proc_id INTEGER;
  v_window_id INTEGER;
BEGIN
  -- Register view as AD_Table (IsView=Y) if needed for Report View
  SELECT ad_table_id INTO v_table_id FROM ad_table WHERE tablename = 'aberp_leave_planning_rv';
  IF v_table_id IS NULL THEN
    INSERT INTO ad_table (
      ad_table_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, tablename, isview, accesslevel, entitytype,
      issecurityenabled, isdeleteable, ishighvolume, importtable,
      ischangelog, replicationtype, ad_table_uu, iscentrallymaintained
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Table' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Leave Planning Report',
      'SAW016 reporting view for leave planning export',
      'aberp_leave_planning_rv', 'Y', '3', 'Ab_ERP',
      'N', 'N', 'N', 'N',
      'N', 'L', '16a0160a-c0d4-4f01-8e15-000000000001', 'Y'
    ) RETURNING ad_table_id INTO v_table_id;
  END IF;

  SELECT ad_reportview_id INTO v_rv_id FROM ad_reportview WHERE ad_reportview_uu = v_rv_uu;
  IF v_rv_id IS NULL THEN
    SELECT ad_reportview_id INTO v_rv_id FROM ad_reportview WHERE name = 'Leave Planning Report';
  END IF;

  IF v_rv_id IS NULL THEN
    INSERT INTO ad_reportview (
      ad_reportview_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_table_id, whereclause, orderbyclause,
      entitytype, ad_reportview_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_ReportView' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Leave Planning Report',
      'Leave overlapping planning period; filter via process parameters where used',
      v_table_id,
      NULL,
      'aberp_approverstatus, aberp_lp_servicelocation, startdate, employee_name',
      'Ab_ERP', v_rv_uu
    ) RETURNING ad_reportview_id INTO v_rv_id;
  END IF;

  SELECT ad_process_id INTO v_proc_id FROM ad_process WHERE ad_process_uu = v_proc_uu;
  IF v_proc_id IS NULL THEN
    SELECT ad_process_id INTO v_proc_id FROM ad_process WHERE value = 'AbERP_LeavePlanning_Report';
  END IF;

  IF v_proc_id IS NULL THEN
    INSERT INTO ad_process (
      ad_process_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      value, name, description, help,
      accesslevel, entitytype, isreport, isdirectprint,
      ad_reportview_id, classname,
      isbetafunctionality, isserverprocess, showhelp,
      ad_process_uu, allowmultipleexecution
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_LeavePlanning_Report', 'Leave Planning Report',
      'Print/export leave overlapping a planning period (and optional service locations)',
      'Set Start Date / End Date. Optional: All Locations, or Service Location IDs (comma-separated). Output includes employee, location, leave type, dates, statuses, notes. Use Print or export from the report dialog. Grid CSV export from Leave Records tab also works for the active window filters.',
      '3', 'Ab_ERP', 'Y', 'N',
      v_rv_id, NULL,
      'N', 'N', 'Y',
      v_proc_uu, 'P'
    ) RETURNING ad_process_id INTO v_proc_id;
  ELSE
    UPDATE ad_process SET
      name = 'Leave Planning Report',
      isreport = 'Y',
      ad_reportview_id = v_rv_id,
      entitytype = 'Ab_ERP',
      ad_process_uu = COALESCE(ad_process_uu, v_proc_uu),
      updated = NOW()
    WHERE ad_process_id = v_proc_id;
  END IF;

  -- Parameters
  IF NOT EXISTS (SELECT 1 FROM ad_process_para WHERE ad_process_id = v_proc_id AND columnname = 'StartDate') THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_process_id,
      seqno, ad_reference_id, columnname, iscentrallymaintained,
      fieldlength, ismandatory, isrange, entitytype, ad_process_para_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process_Para' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Start Date', 'Planning period start', v_proc_id,
      10, 15, 'StartDate', 'Y',
      7, 'Y', 'N', 'Ab_ERP', '16a016pp-0001-4f01-8e15-000000000001'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_process_para WHERE ad_process_id = v_proc_id AND columnname = 'EndDate') THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_process_id,
      seqno, ad_reference_id, columnname, iscentrallymaintained,
      fieldlength, ismandatory, isrange, entitytype, ad_process_para_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process_Para' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'End Date', 'Planning period end', v_proc_id,
      20, 15, 'EndDate', 'Y',
      7, 'Y', 'N', 'Ab_ERP', '16a016pp-0002-4f01-8e15-000000000001'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_process_para WHERE ad_process_id = v_proc_id AND columnname = 'IsAllLocations') THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_process_id,
      seqno, ad_reference_id, columnname, iscentrallymaintained,
      fieldlength, ismandatory, isrange, defaultvalue, entitytype, ad_process_para_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process_Para' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'All Locations', 'Y = ignore location filter', v_proc_id,
      30, 20, 'IsAllLocations', 'Y',
      1, 'Y', 'N', 'Y', 'Ab_ERP', '16a016pp-0003-4f01-8e15-000000000001'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_process_para WHERE ad_process_id = v_proc_id AND columnname = 'C_BPartner_Location_IDs') THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, ad_process_id,
      seqno, ad_reference_id, columnname, iscentrallymaintained,
      fieldlength, ismandatory, isrange, entitytype, ad_process_para_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Process_Para' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Service Location IDs', 'Comma-separated C_BPartner_Location_ID list when All Locations = N',
      'Copy from Leave Planning Service Locations field, or leave blank with All Locations = Y',
      v_proc_id,
      40, 10, 'C_BPartner_Location_IDs', 'Y',
      4000, 'N', 'N', 'Ab_ERP', '16a016pp-0004-4f01-8e15-000000000001'
    );
  END IF;

  -- Apply report where from parameters via Report View whereclause using @params@
  UPDATE ad_reportview SET
    whereclause =
      'TRUNC(startdate) <= ''@EndDate@'' AND TRUNC(enddate) >= ''@StartDate@'''
      || ' AND (''@IsAllLocations@''=''Y'' OR (COALESCE(''@C_BPartner_Location_IDs@'','''')<>'''''
      || ' AND c_bpartner_location_id IN (@C_BPartner_Location_IDs@)))',
    updated = NOW()
  WHERE ad_reportview_id = v_rv_id;

  -- Process access
  INSERT INTO ad_process_access (
    ad_process_id, ad_role_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, isreadwrite, ad_process_access_uu
  )
  SELECT v_proc_id, r.ad_role_id, r.ad_client_id, 0, 'Y',
         NOW(), 100, NOW(), 100, 'Y',
         NULL
  FROM ad_role r
  WHERE r.name IN ('AbilityERP Admin', 'Admin', 'System Administrator', 'Rostering', 'Rostering TL', 'People and Culture', 'Manager People and Culture')
    AND r.isactive = 'Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_process_access x
      WHERE x.ad_process_id = v_proc_id AND x.ad_role_id = r.ad_role_id AND x.ad_client_id = r.ad_client_id
    );

  -- Attach report as toolbar process on planning window (optional menu process)
  SELECT ad_window_id INTO v_window_id FROM ad_window
  WHERE ad_window_uu = '16a01602-c0d4-4f01-8e15-000000000001' OR name = 'Leave Planning' LIMIT 1;

  IF v_window_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM ad_menu WHERE ad_process_id = v_proc_id AND name = 'Leave Planning Report'
  ) THEN
    INSERT INTO ad_menu (
      ad_menu_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, issummary, issotrx, isreadonly,
      action, ad_process_id, entitytype, ad_menu_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Menu' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Leave Planning Report', 'Report/export leave for a planning period',
      'N', 'Y', 'N',
      'P', v_proc_id, 'Ab_ERP', '16a01605-c0d4-4f01-8e15-000000000002'
    );
  END IF;

  RAISE NOTICE 'SAW016 report process=% reportview=%', v_proc_id, v_rv_id;
END $$;
