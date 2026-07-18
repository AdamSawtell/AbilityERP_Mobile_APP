-- SAW029 preflight — fail closed if SAW027 Review window / Audit FG missing
SET search_path TO adempiere;

DO $$
DECLARE
  v_win INTEGER;
  v_tab INTEGER;
  v_audit INTEGER;
  v_cols INTEGER;
BEGIN
  SELECT ad_window_id INTO v_win FROM ad_window
  WHERE ad_window_uu = '27a02750-c0d4-4f01-8e15-000000000001'
     OR name = 'Activity Audit Review'
  ORDER BY CASE WHEN ad_window_uu = '27a02750-c0d4-4f01-8e15-000000000001' THEN 0 ELSE 1 END
  LIMIT 1;
  IF v_win IS NULL THEN
    RAISE EXCEPTION 'SAW029 preflight FAIL: window Activity Audit Review missing (install SAW027 first)';
  END IF;

  SELECT ad_tab_id INTO v_tab FROM ad_tab
  WHERE ad_tab_uu = '27a02751-c0d4-4f01-8e15-000000000001'
     OR (ad_window_id = v_win AND name = 'Reviews')
  ORDER BY CASE WHEN ad_tab_uu = '27a02751-c0d4-4f01-8e15-000000000001' THEN 0 ELSE 1 END
  LIMIT 1;
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'SAW029 preflight FAIL: Reviews tab missing';
  END IF;

  SELECT ad_fieldgroup_id INTO v_audit FROM ad_fieldgroup
  WHERE ad_fieldgroup_uu = '3551f0df-bb72-40ab-8b1c-c28a7fec9a46'
     OR (name = 'Audit' AND entitytype = 'Ab_ERP')
  ORDER BY CASE WHEN ad_fieldgroup_uu = '3551f0df-bb72-40ab-8b1c-c28a7fec9a46' THEN 0 ELSE 1 END
  LIMIT 1;
  IF v_audit IS NULL THEN
    RAISE EXCEPTION 'SAW029 preflight FAIL: AbERP Audit field group missing (SAW027 sql/14-format-audit-fieldgroup.sql)';
  END IF;

  SELECT COUNT(*) INTO v_cols
  FROM ad_column c
  JOIN ad_tab t ON t.ad_table_id = c.ad_table_id
  WHERE t.ad_tab_id = v_tab
    AND c.columnname IN ('ReviewStatus','IsReviewed','IsActive','ActivityUpdatedAudited');
  IF v_cols < 4 THEN
    RAISE EXCEPTION 'SAW029 preflight FAIL: Review table missing required columns (found % of 4)', v_cols;
  END IF;

  RAISE NOTICE 'SAW029 preflight OK: window=% tab=% audit_fg=% cols=%', v_win, v_tab, v_audit, v_cols;
END $$;
