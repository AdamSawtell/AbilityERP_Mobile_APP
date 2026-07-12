-- Hotfix: Show Unmatched Staff is a UI flag only.
-- SelectClause MUST be the constant 'N' (not au.IsActive, not 0).
--   default N + uncleared editor → 'N'='N' (true, harmless)
--   Y + uncleared editor → 'N'='Y' (false) — Java clears editor + strips this
-- au.IsActive with default N was leaking au.IsActive='N' → 0 active staff.
-- Bare 0 breaks the Yes-No editor ("non-negative only") on some builds.
SET search_path TO adempiere;

UPDATE ad_infocolumn SET
  selectclause = '''N''',
  description = 'When N (default), only staff matching Related Rostering Needs are shown. Credentials must be active and valid for the shift Start/End (not just today). Set Y to include unmatched staff.',
  help = 'UI flag only. Java clears this criterion before SQL and applies needs match when N. SelectClause constant ''N'' is intentional so a failed clear still yields true under default N.',
  defaultvalue = 'N',
  isquerycriteria = 'Y',
  isdisplayed = 'N',
  ishideinfocolumn = 'Y',
  updated = NOW(),
  updatedby = 100
WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde003';

SELECT columnname, selectclause, defaultvalue, isquerycriteria, ad_reference_id
FROM ad_infocolumn
WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde003';
