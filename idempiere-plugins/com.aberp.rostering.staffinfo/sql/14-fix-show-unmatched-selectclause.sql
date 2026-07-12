-- Show Unmatched Staff: Yes-No UI flag.
-- SelectClause au.IsActive (real Yes-No column — avoids ZK "non-negative only").
-- defaultvalue NULL so an uncleared editor cannot emit au.IsActive='N' (0 active staff).
-- Java always clears this editor before super.getSQLWhere() and applies needs match when not Y.
SET search_path TO adempiere;

UPDATE ad_infocolumn SET
  selectclause = 'au.IsActive',
  defaultvalue = NULL,
  description = 'Tick Y to include staff who do not match Related Rostering Needs. Leave blank/N for match-only (credentials must be valid for the shift window).',
  help = 'UI flag only. Java clears this criterion from SQL. SelectClause is au.IsActive for Yes-No type-safety; default is blank so a failed clear cannot hide all active users.',
  isquerycriteria = 'Y',
  isdisplayed = 'N',
  ishideinfocolumn = 'Y',
  updated = NOW(),
  updatedby = 100
WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde003';

SELECT columnname, selectclause, defaultvalue, isquerycriteria
FROM ad_infocolumn
WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde003';
