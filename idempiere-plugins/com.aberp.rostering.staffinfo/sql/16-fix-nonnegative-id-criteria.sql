-- Fix ZK "non-negative only" on Staff Info ReQuery.
-- Gender (Table Direct) and BP Position (Table) use Intbox ID editors; empty
-- value is often -1, which fails ZK constraint "no negative" when All/Any is on.
-- Show Unmatched is handled in Java (checkbox on banner) — not an AD query criterion.
SET search_path TO adempiere;

UPDATE ad_infocolumn SET
  isquerycriteria = 'N',
  seqnoselection = 0,
  defaultvalue = NULL,
  updated = NOW(),
  updatedby = 100
WHERE ad_infocolumn_uu IN (
  '22426da0-28ec-4047-8eff-0cb186e556b6', -- AbERP_Gender_ID
  'b70b7e4e-23f7-45e1-92b2-7b40e4e3c908'  -- BP_C_Job_ID
);

-- Keep visible in result grid if already displayed; criteria pane must not host Intboxes
UPDATE ad_infocolumn SET
  isquerycriteria = 'N',
  isdisplayed = 'N',
  ishideinfocolumn = 'Y',
  defaultvalue = NULL,
  description = 'UI flag moved to Java checkbox on the Staff Info banner (AD criterion caused ZK non-negative / 0-row bugs).',
  updated = NOW(),
  updatedby = 100
WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde003';

-- On Approved Leave stays display-only (expression SelectClause)
UPDATE ad_infocolumn SET
  isquerycriteria = 'N',
  isreadonly = 'Y',
  defaultvalue = NULL,
  updated = NOW(),
  updatedby = 100
WHERE ad_infocolumn_uu = 'a1b2c3d4-e5f6-7788-9900-aabbccdde001';

-- Hidden Multi Select Employee Status still built editors with -1 → non-negative only
UPDATE ad_infocolumn SET
  isquerycriteria = 'N',
  seqnoselection = 0,
  defaultvalue = NULL,
  updated = NOW(),
  updatedby = 100
WHERE ad_infocolumn_uu = 'ac0d418c-4aac-44fa-bc50-eb57ff978875';

UPDATE ad_infocolumn SET
  isquerycriteria = 'N',
  seqnoselection = 0,
  defaultvalue = NULL,
  updated = NOW(),
  updatedby = 100
WHERE ad_infowindow_id = (
    SELECT ad_infowindow_id FROM ad_infowindow
    WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  )
  AND isquerycriteria = 'Y'
  AND COALESCE(isdisplayed, 'N') = 'N';

SELECT columnname, isquerycriteria, isdisplayed, ad_reference_id, defaultvalue
FROM ad_infocolumn
WHERE ad_infocolumn_uu IN (
  '22426da0-28ec-4047-8eff-0cb186e556b6',
  'b70b7e4e-23f7-45e1-92b2-7b40e4e3c908',
  'a1b2c3d4-e5f6-7788-9900-aabbccdde003',
  'a1b2c3d4-e5f6-7788-9900-aabbccdde001',
  'ac0d418c-4aac-44fa-bc50-eb57ff978875'
)
ORDER BY columnname;
