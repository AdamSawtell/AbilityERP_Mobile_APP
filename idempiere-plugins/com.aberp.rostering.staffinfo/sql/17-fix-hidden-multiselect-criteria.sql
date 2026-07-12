-- Fix ZK "non-negative only" from hidden Multi Select query criteria.
-- Employee Status (R_Status_ID, ref 200138 Multi Select Table) was still
-- isquerycriteria=Y with isdisplayed=N. Info still builds editors for hidden
-- criteria; empty ChosenMultipleSelection holds -1 → Intbox "no negative".
SET search_path TO adempiere;

UPDATE ad_infocolumn SET
  isquerycriteria = 'N',
  seqnoselection = 0,
  defaultvalue = NULL,
  updated = NOW(),
  updatedby = 100
WHERE ad_infocolumn_uu = 'ac0d418c-4aac-44fa-bc50-eb57ff978875'; -- Employee Status

-- Belt-and-braces: no hidden query criteria on this Info Window
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

SELECT columnname, name, isquerycriteria, isdisplayed, ad_reference_id
FROM ad_infocolumn
WHERE ad_infowindow_id = (
    SELECT ad_infowindow_id FROM ad_infowindow
    WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  )
  AND isquerycriteria = 'Y'
ORDER BY seqnoselection, seqno;
