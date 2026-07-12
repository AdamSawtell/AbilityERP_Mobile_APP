-- Rename criteria/grid label User Name → Staff Name
SET search_path TO adempiere;

UPDATE ad_infocolumn SET
  name = 'Staff Name',
  updated = NOW(),
  updatedby = 100
WHERE ad_infowindow_id = (
    SELECT ad_infowindow_id FROM ad_infowindow
    WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  )
  AND columnname = 'Name'
  AND isactive = 'Y';

UPDATE ad_infocolumn_trl t SET
  name = 'Staff Name',
  istranslated = 'Y',
  updated = NOW(),
  updatedby = 100
FROM ad_infocolumn c
WHERE t.ad_infocolumn_id = c.ad_infocolumn_id
  AND c.ad_infowindow_id = (
    SELECT ad_infowindow_id FROM ad_infowindow
    WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  )
  AND c.columnname = 'Name';

UPDATE ad_infowindow SET
  help = REPLACE(
           COALESCE(help, ''),
           'Find by User Name',
           'Find by Staff Name'
         ),
  updated = NOW(),
  updatedby = 100
WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  AND help ILIKE '%User Name%';

SELECT columnname, name, isquerycriteria, isdisplayed
FROM ad_infocolumn
WHERE ad_infowindow_id = (
    SELECT ad_infowindow_id FROM ad_infowindow
    WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  )
  AND columnname = 'Name';
