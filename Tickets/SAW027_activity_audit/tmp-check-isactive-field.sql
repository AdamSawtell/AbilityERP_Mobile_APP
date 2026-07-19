SET search_path TO adempiere;

-- Is IsActive present on Reviews / Terms tabs?
SELECT w.name AS window, t.name AS tab, c.columnname, f.isdisplayed, f.isdisplayedgrid, f.isreadonly, f.seqno
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name IN ('Activity Audit Review','Activity Audit Terms','Activity Audit Runs')
  AND c.columnname = 'IsActive'
ORDER BY w.name, t.name;
