-- SAW015 verify
SET search_path TO adempiere;

SELECT CASE WHEN COUNT(*) = 1 THEN 'OK process' ELSE 'FAIL process' END AS check
FROM ad_process
WHERE value = 'AbERP_SkipDates_CopyDatesFrom'
  AND classname = 'com.aberp.skipdates.copyfrom.CopyDatesFrom'
  AND ad_process_uu = '15a01501-c0d4-4f01-8e15-000000000001';

SELECT CASE WHEN COUNT(*) = 1 THEN 'OK para' ELSE 'FAIL para' END
FROM ad_process_para pp
JOIN ad_process p ON p.ad_process_id = pp.ad_process_id
WHERE p.value = 'AbERP_SkipDates_CopyDatesFrom'
  AND pp.columnname = 'AbERP_Skip_Dates_ID'
  AND pp.ismandatory = 'Y';

SELECT CASE WHEN COUNT(*) = 1 THEN 'OK column' ELSE 'FAIL column' END
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'AbERP_Skip_Dates'
  AND c.columnname = 'AbERP_CopyDatesFrom'
  AND c.ad_process_id IS NOT NULL
  AND c.istoolbarbutton = 'B';

SELECT CASE WHEN COUNT(*) >= 1 THEN 'OK field' ELSE 'FAIL field' END
FROM ad_field f
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE w.name = 'Skip Dates' AND t.name = 'Skip Dates'
  AND c.columnname = 'AbERP_CopyDatesFrom'
  AND f.isdisplayed = 'Y';

SELECT CASE WHEN COUNT(*) >= 2 THEN 'OK access Admin roles' ELSE 'WARN access count=' || COUNT(*)::text END
FROM ad_process_access pa
JOIN ad_process p ON p.ad_process_id = pa.ad_process_id
JOIN ad_role r ON r.ad_role_id = pa.ad_role_id
WHERE p.value = 'AbERP_SkipDates_CopyDatesFrom'
  AND r.name IN ('AbilityERP Admin', 'Admin');

SELECT CASE WHEN EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema = 'adempiere' AND table_name = 'aberp_skip_dates'
    AND column_name = 'aberp_copydatesfrom'
) THEN 'OK physical column' ELSE 'FAIL physical column' END;
