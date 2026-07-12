SET search_path TO adempiere;

-- SAW013 preflight: HCO Forms / AbERP_ShiftChange must exist (resolve by UU or name).
DO $$
DECLARE
  v_table NUMERIC;
  v_window NUMERIC;
  v_tab NUMERIC;
  v_status_col NUMERIC;
  v_btn_col NUMERIC;
BEGIN
  SELECT ad_table_id INTO v_table
  FROM ad_table
  WHERE ad_table_uu = '136fd0b7-e2b0-40a1-846f-1e198b8c232d'
     OR tablename = 'AbERP_ShiftChange'
  LIMIT 1;
  IF v_table IS NULL THEN
    RAISE EXCEPTION 'SAW013 preflight: AbERP_ShiftChange table not found';
  END IF;

  SELECT ad_window_id INTO v_window
  FROM ad_window
  WHERE ad_window_uu = 'b3919637-5125-4d2d-a9f7-6d751835f537'
     OR name = 'HCO Forms and Approvals'
  LIMIT 1;
  IF v_window IS NULL THEN
    RAISE EXCEPTION 'SAW013 preflight: window HCO Forms and Approvals not found';
  END IF;

  SELECT ad_tab_id INTO v_tab
  FROM ad_tab
  WHERE ad_tab_uu = 'a22481e4-c47f-43e3-ab9e-6c54a31ce2a1'
     OR (ad_window_id = v_window AND ad_table_id = v_table AND tablevel = 0)
  LIMIT 1;
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'SAW013 preflight: main tab for AbERP_ShiftChange not found';
  END IF;

  SELECT ad_column_id INTO v_status_col
  FROM ad_column
  WHERE ad_table_id = v_table AND columnname = 'R_Status_ID';
  IF v_status_col IS NULL THEN
    RAISE EXCEPTION 'SAW013 preflight: R_Status_ID column missing on AbERP_ShiftChange';
  END IF;

  SELECT ad_column_id INTO v_btn_col
  FROM ad_column
  WHERE ad_table_id = v_table AND columnname = 'AbERP_CreateShiftChangeRequest';
  IF v_btn_col IS NULL THEN
    RAISE EXCEPTION 'SAW013 preflight: AbERP_CreateShiftChangeRequest button column missing';
  END IF;

  RAISE NOTICE 'SAW013 preflight OK: table=%, window=%, tab=%', v_table, v_window, v_tab;
END $$;
