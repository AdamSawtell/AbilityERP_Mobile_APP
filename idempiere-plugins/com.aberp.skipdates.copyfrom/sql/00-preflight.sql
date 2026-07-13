-- SAW015 preflight: Skip Dates / Dates tables and window must exist (UU-safe).
SET search_path TO adempiere;

DO $$
DECLARE
  v_win TEXT := 'b3037901-e883-42f2-8e6d-c8e759ca91cd';
  v_skip TEXT := '88130ae9-2aac-4c86-9c98-f94b272af212';
  v_dates TEXT := 'bac8f234-c300-45f5-b8bb-5f7c7a0a2152';
  v_tab TEXT := '4224ab0d-fa68-44ac-9371-eb5fd100c3b3';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ad_window WHERE ad_window_uu = v_win OR name = 'Skip Dates') THEN
    RAISE EXCEPTION 'SAW015 preflight: Skip Dates window not found (UU % or name Skip Dates)', v_win;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ad_table WHERE ad_table_uu = v_skip OR tablename = 'AbERP_Skip_Dates') THEN
    RAISE EXCEPTION 'SAW015 preflight: table AbERP_Skip_Dates not found (UU %)', v_skip;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ad_table WHERE ad_table_uu = v_dates OR tablename = 'AbERP_Dates') THEN
    RAISE EXCEPTION 'SAW015 preflight: table AbERP_Dates not found (UU %)', v_dates;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM ad_tab t
    JOIN ad_window w ON w.ad_window_id = t.ad_window_id
    WHERE (t.ad_tab_uu = v_tab OR (w.name = 'Skip Dates' AND t.name = 'Skip Dates'))
      AND t.isactive = 'Y'
  ) THEN
    RAISE EXCEPTION 'SAW015 preflight: Skip Dates header tab not found (UU %)', v_tab;
  END IF;
  RAISE NOTICE 'SAW015 preflight OK';
END $$;
