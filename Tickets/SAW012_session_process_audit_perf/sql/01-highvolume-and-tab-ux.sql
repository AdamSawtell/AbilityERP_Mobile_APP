-- SAW012: High Volume + tab UX (Find-first, search cols, max rows, Created DESC)
-- Resolves by *_UU / TableName. Does not change existing UUs.

-- 1) High Volume on large audit parents (ChangeLog already Y on core)
UPDATE ad_table
SET ishighvolume = 'Y', updated = now(), updatedby = 100
WHERE tablename IN ('AD_PInstance', 'AD_Session', 'AD_Issue')
  AND COALESCE(ishighvolume, 'N') <> 'Y';

-- 2) Process Audit main tab
UPDATE ad_tab t
SET maxqueryrecords = 200,
    orderbyclause = 'Created DESC',
    updated = now(),
    updatedby = 100
WHERE t.ad_tab_uu = '58bba03d-cb5c-4230-aeb2-1a435ae41b93';

-- 3) Session Audit main tab
UPDATE ad_tab t
SET maxqueryrecords = 200,
    orderbyclause = 'Created DESC',
    updated = now(),
    updatedby = 100
WHERE t.ad_tab_uu = '939cc571-7724-4631-977a-ec54f21ea0b3';

-- 4) Process Audit Find / selection columns
UPDATE ad_field f
SET isselectioncolumn = 'Y', updated = now(), updatedby = 100
WHERE f.ad_field_uu IN (
  'ffbb9687-2753-4427-912b-9ee50ea0985a', -- Created
  '1bf1c01e-f08a-4422-98f7-fc002ad81203', -- AD_Process_ID
  'b73ab274-9b6a-4ab6-b111-bc8f500d6c05', -- AD_User_ID
  'c9d37019-9fc6-450b-9034-8dcff1709a1e', -- Result
  '5dbef232-598d-45fb-ae1a-b489e184a34b'  -- IsProcessing
);

-- 5) Session Audit Find / selection columns
UPDATE ad_field f
SET isselectioncolumn = 'Y', updated = now(), updatedby = 100
WHERE f.ad_field_uu IN (
  'b34dc687-f9d8-44a7-ae3e-a87d0417bb5f', -- Created
  'e313b0a9-f4aa-40e7-a583-64392fdd6c3d', -- Remote_Addr
  '5a582321-b3f2-4154-a607-8ac26a6dca59', -- Processed
  '423f8347-ae57-424b-b6cf-120cfaf85482'  -- LoginDate
);

SELECT 'tables' AS kind, tablename, ishighvolume
FROM ad_table
WHERE tablename IN ('AD_PInstance','AD_Session','AD_Issue','AD_ChangeLog')
ORDER BY 2;

SELECT w.name AS window, t.name AS tab, t.maxqueryrecords, t.orderbyclause
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE t.ad_tab_uu IN (
  '58bba03d-cb5c-4230-aeb2-1a435ae41b93',
  '939cc571-7724-4631-977a-ec54f21ea0b3'
);
