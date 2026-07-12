-- Result grid must be display-only. When IsReadOnly=N, WInfoWindowListItemRenderer
-- paints WEditors (dropdowns/textboxes) on the selected row — wrong for a staff picker.
-- Criteria pane editors are forced read-write in Java after render.
SET search_path TO adempiere;

UPDATE ad_infocolumn SET
  isreadonly = 'Y',
  updated = NOW(),
  updatedby = 100
WHERE ad_infowindow_id = (
    SELECT ad_infowindow_id FROM ad_infowindow
    WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  )
  AND isactive = 'Y'
  AND isdisplayed = 'Y';

SELECT columnname, isquerycriteria, isdisplayed, isreadonly
FROM ad_infocolumn
WHERE ad_infowindow_id = (
    SELECT ad_infowindow_id FROM ad_infowindow
    WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  )
  AND isactive = 'Y'
  AND isdisplayed = 'Y'
ORDER BY seqno;
