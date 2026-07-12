-- Hotfix: Show Unmatched Staff must be a UI flag only — never filter SQL.
-- Do NOT use SelectClause 'N' (becomes 'N'='Y' → 0 rows) or bare 0 (Yes-No editor
-- throws "non-negative only"). Use au.IsActive; Java clears the editor before
-- super.getSQLWhere() so this criterion is not applied.
SET search_path TO adempiere;

UPDATE ad_infocolumn SET
  selectclause = 'au.IsActive',
  description = 'When N (default), only staff matching Related Rostering Needs are shown. Credentials must be active and valid for the shift Start/End (not just today). Set Y to include unmatched staff.',
  help = 'UI flag only. Java clears this criterion from SQL and applies needs match when N. SelectClause is au.IsActive solely so the Yes-No editor type-checks; it must not remain in the WHERE clause.',
  updated = NOW(),
  updatedby = 100
WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde003';

SELECT columnname, selectclause, defaultvalue, isquerycriteria, ad_reference_id
FROM ad_infocolumn
WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde003';
