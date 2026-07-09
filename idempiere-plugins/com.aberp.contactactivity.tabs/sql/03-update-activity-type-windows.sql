-- Register new windows for activity type filtering and enable common activity types.
-- AbilityERP filters ContactActivityType via AD_Ref_List.description (comma-separated AD_Window_IDs)
-- and optional AbERP_IncludedActivities role+window+type rows.
SET search_path TO adempiere;

-- New window IDs for this plugin
-- Booking Generator: 1000193 (de336034-bd4e-4445-b018-9c762c98d847)
-- Service Booking:    1000077 (5ba3cde5-efad-435f-a606-a1e1ed22e542)
-- Service Agreement: 1000118 (fa69ffc1-68f4-438e-bcff-c3ecad36c94c)

-- Append window IDs to general communication activity types (same set as Enquiry/Shift)
UPDATE ad_ref_list rl
SET description = TRIM(BOTH ',' FROM
      COALESCE(NULLIF(description, ''), '')
      || CASE WHEN description IS NULL OR description = '' THEN '' ELSE ',' END
      || '1000193,1000077,1000118'
    ),
    updated = NOW(),
    updatedby = 100
WHERE rl.ad_reference_id = 53423
  AND rl.isactive = 'Y'
  AND rl.value IN ('10000006', 'APP', 'EM', 'ME', 'PC', 'TA')
  AND (rl.description IS NULL OR rl.description NOT LIKE '%1000193%');

-- Case Note — common on service records
UPDATE ad_ref_list rl
SET description = TRIM(BOTH ',' FROM
      COALESCE(NULLIF(description, ''), '')
      || CASE WHEN description IS NULL OR description = '' THEN '' ELSE ',' END
      || '1000193,1000077,1000118'
    ),
    updated = NOW(),
    updatedby = 100
WHERE rl.ad_reference_id = 53423
  AND rl.isactive = 'Y'
  AND rl.value = 'CN'
  AND (rl.description IS NULL OR rl.description NOT LIKE '%1000193%');

-- Extend AbERP_IncludedActivityWindows validation (Included Activities window picker)
UPDATE ad_val_rule
SET code = code || E'\nOR AD_Window_UU=''de336034-bd4e-4445-b018-9c762c98d847'''
    || E'\nOR AD_Window_UU=''5ba3cde5-efad-435f-a606-a1e1ed22e542'''
    || E'\nOR AD_Window_UU=''fa69ffc1-68f4-438e-bcff-c3ecad36c94c''',
    updated = NOW(),
    updatedby = 100
WHERE ad_val_rule_id = 1000071
  AND name = 'AbERP_IncludedActivityWindows'
  AND code NOT LIKE '%de336034-bd4e-4445-b018-9c762c98d847%';

-- Verify registration
SELECT w.ad_window_id, w.name, t.ad_tab_id, t.name AS tab_name, c.columnname AS link_column
FROM ad_window w
JOIN ad_tab t ON t.ad_window_id = w.ad_window_id
LEFT JOIN ad_column c ON c.ad_column_id = t.ad_column_id
WHERE w.ad_window_id IN (1000193, 1000077, 1000118)
  AND t.name = 'Activity'
  AND t.ad_table_id = 53354
ORDER BY w.name;
