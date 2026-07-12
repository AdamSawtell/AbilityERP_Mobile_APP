-- SAW009 preflight: fail closed if required UUs/objects are missing
SET search_path TO adempiere;

DO $$
DECLARE
  v_table NUMERIC;
  v_tab NUMERIC;
  v_ref NUMERIC;
  v_el_start NUMERIC;
  v_el_end NUMERIC;
BEGIN
  SELECT ad_table_id INTO v_table
  FROM ad_table
  WHERE ad_table_uu = 'fbab5be2-21b0-4f4f-b070-cd9d77efa238'
     OR tablename = 'C_OrderLine'
  LIMIT 1;
  IF v_table IS NULL THEN
    RAISE EXCEPTION 'SAW009 preflight: C_OrderLine table not found';
  END IF;

  SELECT ad_tab_id INTO v_tab
  FROM ad_tab
  WHERE ad_tab_uu = '8b044105-bc30-4f81-b0d6-a45835d82f98';
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'SAW009 preflight: Service Booking Line tab UU 8b044105-bc30-4f81-b0d6-a45835d82f98 not found';
  END IF;

  SELECT ad_reference_id INTO v_ref
  FROM ad_reference
  WHERE ad_reference_uu = '5ec1b0b5-7ce8-43dc-bf9d-77bc2d7afbbd';
  IF v_ref IS NULL THEN
    RAISE EXCEPTION 'SAW009 preflight: reference UU 5ec1b0b5-7ce8-43dc-bf9d-77bc2d7afbbd (14 Day Roster Period) not found';
  END IF;

  SELECT ad_element_id INTO v_el_start
  FROM ad_element
  WHERE ad_element_uu = 'ac9cf459-1755-4dfb-b46d-22091027402b'
     OR columnname = 'AbERP_Support_Start_Day'
  LIMIT 1;
  IF v_el_start IS NULL THEN
    RAISE EXCEPTION 'SAW009 preflight: element AbERP_Support_Start_Day not found';
  END IF;

  SELECT ad_element_id INTO v_el_end
  FROM ad_element
  WHERE ad_element_uu = 'fbe588b0-561d-437c-b84d-4328185f0e9b'
     OR columnname = 'AbERP_Support_End_Day'
  LIMIT 1;
  IF v_el_end IS NULL THEN
    RAISE EXCEPTION 'SAW009 preflight: element AbERP_Support_End_Day not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'adempiere' AND table_name = 'aberp_servicepattern'
  ) THEN
    RAISE EXCEPTION 'SAW009 preflight: aberp_servicepattern table not found';
  END IF;

  RAISE NOTICE 'SAW009 preflight OK (C_OrderLine=%, tab=%, ref=%, el_start=%, el_end=%)',
    v_table, v_tab, v_ref, v_el_start, v_el_end;
END $$;
