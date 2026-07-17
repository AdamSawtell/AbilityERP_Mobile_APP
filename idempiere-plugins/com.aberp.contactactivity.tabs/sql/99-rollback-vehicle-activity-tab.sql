-- SAW026 conservative rollback.
-- Hides the Vehicle Activity tab and removes its type/window-picker grants.
-- The physical/AD link column is retained to preserve any activity data.
\set ON_ERROR_STOP on
SET search_path TO adempiere;

BEGIN;

UPDATE ad_field f
SET isactive = 'N', updated = NOW(), updatedby = 100
FROM ad_tab t
WHERE f.ad_tab_id = t.ad_tab_id
  AND t.ad_tab_uu = '7d14ac4f-5fef-4f1f-b917-026000000002';

UPDATE ad_tab
SET isactive = 'N', updated = NOW(), updatedby = 100
WHERE ad_tab_uu = '7d14ac4f-5fef-4f1f-b917-026000000002';

DO $$
DECLARE
  v_window_id INTEGER;
  v_type TEXT;
BEGIN
  SELECT ad_window_id INTO v_window_id
  FROM ad_window
  WHERE name = 'Vehicle' AND isactive = 'Y'
  LIMIT 1;

  IF v_window_id IS NOT NULL THEN
    FOREACH v_type IN ARRAY ARRAY['EM', 'ME', 'PC', 'CN', 'TA'] LOOP
      UPDATE ad_ref_list rl
      SET description = NULLIF(
            TRIM(BOTH ',' FROM regexp_replace(
              ',' || COALESCE(rl.description, '') || ',',
              ',' || v_window_id::text || ',',
              ',',
              'g'
            )),
            ''
          ),
          updated = NOW(),
          updatedby = 100
      FROM ad_column c
      JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
      WHERE rl.ad_reference_id = c.ad_reference_value_id
        AND tb.tablename = 'C_ContactActivity'
        AND c.columnname = 'ContactActivityType'
        AND rl.value = v_type
        AND rl.isactive = 'Y';
    END LOOP;
  END IF;
END $$;

UPDATE ad_val_rule vr
SET code = replace(
      vr.code,
      E'\nOR AD_Window_UU=''' || w.ad_window_uu || '''',
      ''
    ),
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE vr.name = 'AbERP_IncludedActivityWindows'
  AND w.name = 'Vehicle';

COMMIT;

SELECT ad_tab_uu, name, isactive
FROM ad_tab
WHERE ad_tab_uu = '7d14ac4f-5fef-4f1f-b917-026000000002';
