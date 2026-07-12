-- SAW012: preflight — Session/Process Audit perf (UU/name only)
-- Fail closed if core windows/tables missing.

DO $$
DECLARE
  v_missing text := '';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ad_window WHERE ad_window_uu = 'e91594d7-0b31-406b-9c35-8cb9ea2abc04') THEN
    v_missing := v_missing || 'Process Audit window; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ad_window WHERE ad_window_uu = 'b5043d5c-1741-4da0-b261-81936e28d9c5') THEN
    v_missing := v_missing || 'Session Audit window; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ad_table WHERE tablename = 'AD_PInstance') THEN
    v_missing := v_missing || 'AD_PInstance table; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ad_table WHERE tablename = 'AD_Session') THEN
    v_missing := v_missing || 'AD_Session table; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ad_process WHERE value = 'HouseKeepingPara') THEN
    v_missing := v_missing || 'HouseKeepingPara process; ';
  END IF;
  IF v_missing <> '' THEN
    RAISE EXCEPTION 'SAW012 preflight failed — missing: %', v_missing;
  END IF;
  RAISE NOTICE 'SAW012 preflight OK';
END $$;
