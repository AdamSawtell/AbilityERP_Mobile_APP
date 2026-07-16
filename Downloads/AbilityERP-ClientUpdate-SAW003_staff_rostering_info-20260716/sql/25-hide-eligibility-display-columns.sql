-- Hide On Approved Leave / Has Future Shift from Staff Info result grid.
-- Filters now cover leave + overlapping roster (Employees Not On Leave /
-- Employee Not Rostered). Related Info covers history. Keep InfoColumns
-- active so nothing breaks — display only.
-- Must run AFTER 07-eligibility-criteria.sql (that script re-shows them).
SET search_path TO adempiere;

UPDATE ad_infocolumn SET
  isdisplayed = 'N',
  isquerycriteria = 'N',
  description = CASE columnname
    WHEN 'AbERP_OnApprovedLeave' THEN
      'Hidden from lean grid. Leave for the shift window is filtered by Employees Not On Leave (Java).'
    WHEN 'AbERP_HasFutureShift' THEN
      'Hidden from lean grid. Overlapping roster for the shift window is filtered by Employee Not Rostered (Java); use Related Info for history.'
    ELSE description
  END,
  updated = NOW(),
  updatedby = 100
WHERE ad_infowindow_id = (
    SELECT ad_infowindow_id FROM ad_infowindow
    WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  )
  AND isactive = 'Y'
  AND columnname IN ('AbERP_OnApprovedLeave', 'AbERP_HasFutureShift');

SELECT columnname, name, isdisplayed, isquerycriteria, isactive
FROM ad_infocolumn
WHERE ad_infowindow_id = (
    SELECT ad_infowindow_id FROM ad_infowindow
    WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  )
  AND columnname IN ('AbERP_OnApprovedLeave', 'AbERP_HasFutureShift', 'Name', 'IsEmployee')
ORDER BY seqno;
