-- request types we can safely switch between for E2E
SELECT r_requesttype_id, name FROM r_requesttype
WHERE name IN ('HCO Cancellation','Additional Shift','Roster Template- New Shift')
ORDER BY name;

-- Priority field on window
SELECT f.name, c.columnname, f.isdisplayed, f.isreadonly, f.isupdateable, c.isupdateable
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'HCO Forms and Approvals' AND t.tablevel = 0
  AND c.columnname = 'Priority';
