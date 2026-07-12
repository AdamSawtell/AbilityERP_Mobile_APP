-- SAW010 preflight: Timesheet Approval Info Window must exist by UUID.
-- Fail closed — do not apply 01 if this raises.
-- AD_InfoWindow_UU = 40d6a2d7-3bbc-431e-940c-ce75829a68e4 (seed ID 1000033)

SET search_path TO adempiere;

DO $$
DECLARE
  v_iw NUMERIC;
  v_from TEXT;
  v_table TEXT;
  v_proc_col NUMERIC;
BEGIN
  SELECT iw.ad_infowindow_id, iw.fromclause, t.tablename
    INTO v_iw, v_from, v_table
  FROM ad_infowindow iw
  LEFT JOIN ad_table t ON t.ad_table_id = iw.ad_table_id
  WHERE iw.ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4';

  IF v_iw IS NULL THEN
    RAISE EXCEPTION
      'PREFLIGHT FAIL: AD_InfoWindow UU 40d6a2d7-3bbc-431e-940c-ce75829a68e4 not found. '
      'Do not apply SAW010 SQL until Timesheet Approval Info Window is present (same UU). '
      'Numeric AD_InfoWindow_ID differs between clients — never patch by ID alone.';
  END IF;

  IF v_table IS DISTINCT FROM 'AbERP_TimesheetAndExpenses' THEN
    RAISE EXCEPTION
      'PREFLIGHT FAIL: Info Window ID=% expected table AbERP_TimesheetAndExpenses, got %.',
      v_iw, v_table;
  END IF;

  IF v_from IS NULL OR v_from !~* 'AbERP_TimesheetAndExpenses[[:space:]]+t' THEN
    RAISE EXCEPTION
      'PREFLIGHT FAIL: Info Window ID=% UU ok but FROM clause does not expose AbERP_TimesheetAndExpenses alias t (fromclause=%).',
      v_iw, v_from;
  END IF;

  -- Break columns must already exist on the timesheet table (do not create physical columns).
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'adempiere'
      AND table_name = 'aberp_timesheetandexpenses'
      AND column_name = 'aberp_break_start'
  ) OR NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'adempiere'
      AND table_name = 'aberp_timesheetandexpenses'
      AND column_name = 'aberp_break_end'
  ) THEN
    RAISE EXCEPTION
      'PREFLIGHT FAIL: AbERP_TimesheetAndExpenses missing aberp_break_start / aberp_break_end physical columns.';
  END IF;

  -- Approval process must keep binding to the hidden Timesheet ID InfoColumn.
  SELECT ip.ad_infocolumn_id INTO v_proc_col
  FROM ad_infoprocess ip
  JOIN ad_process p ON p.ad_process_id = ip.ad_process_id
  WHERE ip.ad_infowindow_id = v_iw
    AND p.ad_process_uu = '3a3c2c41-995c-41ba-9fde-caeaacee1d75'
    AND ip.isactive = 'Y'
  LIMIT 1;

  IF v_proc_col IS NULL THEN
    RAISE EXCEPTION
      'PREFLIGHT FAIL: AbERP Set Timesheet Approved Status (UU 3a3c2c41-995c-41ba-9fde-caeaacee1d75) not linked to Info Window %.',
      v_iw;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM ad_infocolumn
    WHERE ad_infocolumn_id = v_proc_col
      AND ad_infowindow_id = v_iw
      AND columnname = 'AbERP_TimesheetAndExpenses_ID'
      AND selectclause ILIKE '%AbERP_TimesheetAndExpenses_ID%'
  ) THEN
    RAISE EXCEPTION
      'PREFLIGHT FAIL: InfoProcess binds to AD_InfoColumn_ID=% but that is not AbERP_TimesheetAndExpenses_ID — aborting to protect approval.',
      v_proc_col;
  END IF;

  RAISE NOTICE 'PREFLIGHT OK: AD_InfoWindow_ID=% UU=40d6a2d7-3bbc-431e-940c-ce75829a68e4 table=% process_col=%',
    v_iw, v_table, v_proc_col;
END $$;

SELECT ad_infowindow_id AS client_local_id,
       ad_infowindow_uu,
       name,
       fromclause,
       isvalid
FROM ad_infowindow
WHERE ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4';
