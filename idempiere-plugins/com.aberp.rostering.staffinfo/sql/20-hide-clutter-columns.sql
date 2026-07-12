-- Hide clutter columns from Staff Info result grid (keep pick list lean).
-- Agency Staff stays as query criteria (filter pane) but not a grid column.
-- C_BPartner_ID stays active for Related Info links; just not displayed.
SET search_path TO adempiere;

UPDATE ad_infocolumn SET
  isdisplayed = 'N',
  updated = NOW(),
  updatedby = 100
WHERE ad_infowindow_id = (
    SELECT ad_infowindow_id FROM ad_infowindow
    WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  )
  AND isactive = 'Y'
  AND columnname IN (
    'BP_Name',
    'R_Status_ID',
    'C_BPartner_ID',
    'AbERP_isagencystaff'
  );

-- Agency Staff remains a north criteria filter
UPDATE ad_infocolumn SET
  isquerycriteria = 'Y',
  updated = NOW(),
  updatedby = 100
WHERE ad_infowindow_id = (
    SELECT ad_infowindow_id FROM ad_infowindow
    WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  )
  AND columnname = 'AbERP_isagencystaff'
  AND isactive = 'Y';

SELECT columnname, name, isdisplayed, isquerycriteria, isactive
FROM ad_infocolumn
WHERE ad_infowindow_id = (
    SELECT ad_infowindow_id FROM ad_infowindow
    WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  )
  AND columnname IN ('BP_Name','R_Status_ID','C_BPartner_ID','AbERP_isagencystaff','Name','IsEmployee')
ORDER BY seqno;
