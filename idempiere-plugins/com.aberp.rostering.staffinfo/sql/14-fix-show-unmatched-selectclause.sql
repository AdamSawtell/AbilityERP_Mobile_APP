-- Hotfix: Show Unmatched Staff must use SelectClause 0 (flag-only), never constant 'N'.
-- Symptom: tick Show Unmatched + All/Any → 0 rows because WHERE becomes 'N'='Y'.
SET search_path TO adempiere;

UPDATE ad_infocolumn SET
  selectclause = '0',
  description = 'When N (default), only staff matching Related Rostering Needs are shown. Credentials must be active and valid for the shift Start/End (not just today). Set Y to include unmatched staff.',
  help = 'UI flag only (SelectClause 0). Java applies needs match when N. Do not use SelectClause ''N'' — that becomes ''N''=''Y'' and returns no rows.',
  updated = NOW(),
  updatedby = 100
WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde003';

SELECT columnname, selectclause, defaultvalue, isquerycriteria
FROM ad_infocolumn
WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde003';
