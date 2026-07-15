-- SAW022 preflight — Roster Period Find field must exist on Shift (Rostered)
SET search_path TO adempiere;

DO $$
DECLARE
  v_field_uu CONSTANT varchar := '9099644b-d5cf-4b32-9921-1776cac6bd66';
  v_win_uu   CONSTANT varchar := '7c269a7e-65dd-4287-8d53-f7f3ca09ee00';
  v_n integer;
BEGIN
  SELECT COUNT(*) INTO v_n
  FROM ad_field f
  JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE f.ad_field_uu = v_field_uu
    AND w.ad_window_uu = v_win_uu
    AND f.isactive = 'Y';

  IF v_n = 0 THEN
    RAISE EXCEPTION 'SAW022 preflight: Roster Period field UU % not on Shift (Rostered) window UU %',
      v_field_uu, v_win_uu;
  END IF;

  RAISE NOTICE 'SAW022 preflight OK — Roster Period field present';
END $$;
