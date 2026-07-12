-- Ensure Activity Type list entries Email / Meeting / Phone call / Case Note / Task
-- are available on Booking Generator, Service Booking, Service Agreement (Project).
--
-- Filter mechanism: AD_Ref_List.description holds comma-separated AD_Window_IDs
-- (AbilityERP AbERP_Ref_List validation). Resolve windows by name — never hardcode IDs.
-- Idempotent: appends each window ID only if missing.
--
-- Run after register-contactactivity-tabs.sql (or alone as a delta on an already-installed build).
-- Log out/in after applying.
SET search_path TO adempiere;

DO $$
DECLARE
  v_ref_id INTEGER;
  v_win RECORD;
  v_type TEXT;
  v_types TEXT[] := ARRAY['EM', 'ME', 'PC', 'CN', 'TA'];
  v_win_names TEXT[] := ARRAY[
    'Booking Generator',
    'Service Booking',
    'Service Agreement (Project)'
  ];
  v_desc TEXT;
  v_updated INTEGER := 0;
BEGIN
  SELECT c.ad_reference_value_id INTO v_ref_id
  FROM ad_column c
  JOIN ad_table t ON t.ad_table_id = c.ad_table_id
  WHERE t.tablename = 'C_ContactActivity'
    AND c.columnname = 'ContactActivityType'
  LIMIT 1;

  IF v_ref_id IS NULL THEN
    RAISE EXCEPTION 'ContactActivityType list reference not found on C_ContactActivity';
  END IF;

  FOREACH v_type IN ARRAY v_types LOOP
    IF NOT EXISTS (
      SELECT 1 FROM ad_ref_list
      WHERE ad_reference_id = v_ref_id AND value = v_type AND isactive = 'Y'
    ) THEN
      RAISE EXCEPTION 'Active Activity Type list value % not found — cannot enable for windows', v_type;
    END IF;
  END LOOP;

  FOR v_win IN
    SELECT w.ad_window_id, w.name
    FROM ad_window w
    WHERE w.name = ANY (v_win_names) AND w.isactive = 'Y'
  LOOP
    FOREACH v_type IN ARRAY v_types LOOP
      SELECT description INTO v_desc
      FROM ad_ref_list
      WHERE ad_reference_id = v_ref_id AND value = v_type AND isactive = 'Y';

      IF v_desc IS NULL OR (
        ',' || v_desc || ',' NOT LIKE '%,' || v_win.ad_window_id::text || ',%'
      ) THEN
        UPDATE ad_ref_list
        SET description = TRIM(BOTH ',' FROM
              COALESCE(NULLIF(description, ''), '')
              || CASE WHEN description IS NULL OR description = '' THEN '' ELSE ',' END
              || v_win.ad_window_id::text
            ),
            updated = NOW(),
            updatedby = 100
        WHERE ad_reference_id = v_ref_id
          AND value = v_type
          AND isactive = 'Y';
        v_updated := v_updated + 1;
        RAISE NOTICE 'Enabled type % on window % (%)', v_type, v_win.name, v_win.ad_window_id;
      END IF;
    END LOOP;
  END LOOP;

  IF NOT EXISTS (
    SELECT 1 FROM ad_window
    WHERE name = ANY (v_win_names) AND isactive = 'Y'
  ) THEN
    RAISE EXCEPTION 'None of the target windows found by name';
  END IF;

  RAISE NOTICE 'Activity type window grants updated (% cell appends)', v_updated;
END $$;

-- Verify: Email / Meeting / Phone call / Case Note / Task vs target windows
SELECT rl.value, rl.name AS type_name, w.name AS window_name, w.ad_window_id,
       CASE
         WHEN ',' || COALESCE(rl.description, '') || ','
              LIKE '%,' || w.ad_window_id::text || ',%' THEN 'Y'
         ELSE 'N'
       END AS enabled
FROM ad_ref_list rl
JOIN ad_column c ON c.ad_reference_value_id = rl.ad_reference_id
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
CROSS JOIN ad_window w
WHERE t.tablename = 'C_ContactActivity'
  AND c.columnname = 'ContactActivityType'
  AND rl.value IN ('EM', 'ME', 'PC', 'CN', 'TA')
  AND rl.isactive = 'Y'
  AND w.name IN ('Booking Generator', 'Service Booking', 'Service Agreement (Project)')
  AND w.isactive = 'Y'
ORDER BY rl.value, w.name;
