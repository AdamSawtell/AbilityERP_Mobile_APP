-- Fix: On Approved Leave must not be a Query Criteria with an SQL-expression SelectClause.
-- That pattern throws ZK "non-negative only" on ReQuery. Shift-window leave/overlap
-- is already applied in StaffRosteringInfoWindow.buildShiftDateEligibilitySql().
-- Keep the column displayed as read-only info if desired; do not use as criteria.
SET search_path TO adempiere;

UPDATE ad_infocolumn SET
  isquerycriteria = 'N',
  isdisplayed = 'Y',
  isreadonly = 'Y',
  defaultvalue = NULL,
  description = 'Informational only. Shift-open Staff Info hides approved leave / overlap via Java for the shift window.',
  help = 'Not a query criterion (expression SelectClause breaks Info ReQuery with non-negative only). Leave/overlap for the parent shift is filtered in Java.',
  updated = NOW(),
  updatedby = 100
WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde001';

-- Show Unmatched: constant 'N' (safe default); never au.IsActive (leaks 0 rows)
UPDATE ad_infocolumn SET
  selectclause = '''N''',
  isquerycriteria = 'Y',
  isdisplayed = 'N',
  ishideinfocolumn = 'Y',
  defaultvalue = 'N',
  updated = NOW(),
  updatedby = 100
WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde003';

SELECT columnname, selectclause, isquerycriteria, isdisplayed, defaultvalue
FROM ad_infocolumn
WHERE ad_infocolumn_uu IN (
  'a1b2c3d4-e5f6-7788-9900-aabbccdde001',
  'a1b2c3d4-e5f6-7788-9900-aabbccdde003'
)
ORDER BY columnname;
