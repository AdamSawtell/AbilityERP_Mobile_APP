-- SAW016 rollback (AD + physical). Does not touch AbERP_Unavailability_Leave data.
SET search_path TO adempiere;

DO $$
DECLARE
  v_window_id INTEGER;
  v_proc_id INTEGER;
  v_menu_id INTEGER;
  v_table_id INTEGER;
  v_rv_id INTEGER;
  v_view_table INTEGER;
BEGIN
  SELECT ad_window_id INTO v_window_id FROM ad_window
  WHERE ad_window_uu = '16a01602-c0d4-4f01-8e15-000000000001' OR name = 'Leave Planning' LIMIT 1;

  SELECT ad_process_id INTO v_proc_id FROM ad_process
  WHERE ad_process_uu = '16a01608-c0d4-4f01-8e15-000000000001' OR value = 'AbERP_LeavePlanning_Report' LIMIT 1;

  SELECT ad_menu_id INTO v_menu_id FROM ad_menu
  WHERE ad_menu_uu = '16a01605-c0d4-4f01-8e15-000000000001' OR (name = 'Leave Planning' AND action = 'W') LIMIT 1;

  SELECT ad_table_id INTO v_table_id FROM ad_table
  WHERE ad_table_uu = '16a01601-c0d4-4f01-8e15-000000000001' OR tablename = 'AbERP_Leave_Planning' LIMIT 1;

  SELECT ad_reportview_id INTO v_rv_id FROM ad_reportview
  WHERE ad_reportview_uu = '16a01609-c0d4-4f01-8e15-000000000001' OR name = 'Leave Planning Report' LIMIT 1;

  SELECT ad_table_id INTO v_view_table FROM ad_table WHERE tablename = 'aberp_leave_planning_rv';

  IF v_proc_id IS NOT NULL THEN
    DELETE FROM ad_process_access WHERE ad_process_id = v_proc_id;
    DELETE FROM ad_process_para WHERE ad_process_id = v_proc_id;
    DELETE FROM ad_menu WHERE ad_process_id = v_proc_id;
    DELETE FROM ad_process WHERE ad_process_id = v_proc_id;
  END IF;

  IF v_rv_id IS NOT NULL THEN
    DELETE FROM ad_reportview WHERE ad_reportview_id = v_rv_id;
  END IF;

  IF v_window_id IS NOT NULL THEN
    DELETE FROM ad_window_access WHERE ad_window_id = v_window_id;
    DELETE FROM ad_field WHERE ad_tab_id IN (SELECT ad_tab_id FROM ad_tab WHERE ad_window_id = v_window_id);
    DELETE FROM ad_tab WHERE ad_window_id = v_window_id;
    DELETE FROM ad_menu WHERE ad_window_id = v_window_id;
    DELETE FROM ad_treenodemm WHERE node_id IN (SELECT ad_menu_id FROM ad_menu WHERE ad_window_id = v_window_id);
    DELETE FROM ad_window WHERE ad_window_id = v_window_id;
  END IF;

  IF v_menu_id IS NOT NULL THEN
    DELETE FROM ad_treenodemm WHERE node_id = v_menu_id;
    DELETE FROM ad_menu WHERE ad_menu_id = v_menu_id;
  END IF;

  IF v_table_id IS NOT NULL THEN
    DELETE FROM ad_column WHERE ad_table_id = v_table_id;
    DELETE FROM ad_table WHERE ad_table_id = v_table_id;
  END IF;

  IF v_view_table IS NOT NULL THEN
    DELETE FROM ad_column WHERE ad_table_id = v_view_table;
    DELETE FROM ad_table WHERE ad_table_id = v_view_table;
  END IF;

  -- Leave virtual columns + their fields
  DELETE FROM ad_field WHERE ad_column_id IN (
    SELECT c.ad_column_id FROM ad_column c
    JOIN ad_table t ON t.ad_table_id = c.ad_table_id
    WHERE t.tablename = 'AbERP_Unavailability_Leave'
      AND c.columnname IN ('AbERP_LP_EmployeeNumber','AbERP_LP_ServiceLocation','AbERP_LP_CalendarDays')
  );
  DELETE FROM ad_column WHERE ad_column_uu LIKE '16a016lc-%'
     OR (columnname IN ('AbERP_LP_EmployeeNumber','AbERP_LP_ServiceLocation','AbERP_LP_CalendarDays')
         AND ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename='AbERP_Unavailability_Leave'));

  DELETE FROM ad_val_rule WHERE ad_val_rule_uu = '16a01606-c0d4-4f01-8e15-000000000001';
  DELETE FROM ad_ref_table WHERE ad_reference_id IN (
    SELECT ad_reference_id FROM ad_reference WHERE ad_reference_uu = '16a01607-c0d4-4f01-8e15-000000000001'
  );
  DELETE FROM ad_reference WHERE ad_reference_uu = '16a01607-c0d4-4f01-8e15-000000000001';
END $$;

DROP TRIGGER IF EXISTS aberp_lp_refresh_lines_trg ON aberp_leave_planning;
DROP FUNCTION IF EXISTS aberp_lp_refresh_lines_trg();
DROP FUNCTION IF EXISTS aberp_lp_refresh_lines(numeric);
DROP FUNCTION IF EXISTS aberp_lp_summary_by_status(numeric);
DROP FUNCTION IF EXISTS aberp_lp_summary_by_type(numeric);
DROP FUNCTION IF EXISTS aberp_lp_primary_support_location(numeric);
DROP FUNCTION IF EXISTS aberp_lp_info_summary_by_status(timestamp without time zone, timestamp without time zone, numeric, text, numeric, numeric);
DROP FUNCTION IF EXISTS aberp_lp_info_summary_by_type(timestamp without time zone, timestamp without time zone, numeric, text, numeric, numeric);
DROP VIEW IF EXISTS aberp_leave_planning_rv;
DROP TABLE IF EXISTS aberp_leave_planning_line;
DROP TABLE IF EXISTS aberp_leave_planning;
