SELECT f.name, c.columnname, f.isreadonly, COALESCE(f.readonlylogic,'') AS fld_ro,
       f.isdisplayed, f.displaylogic
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'HCO Forms and Approvals' AND t.tablevel = 0
  AND (f.isreadonly='Y' OR COALESCE(f.readonlylogic,'') <> '' OR c.isupdateable='N')
ORDER BY f.seqno;

-- Summary field full detail
SELECT f.ad_field_id, f.ad_field_uu, f.name, f.isreadonly, f.readonlylogic, f.displaylogic,
       f.isdisplayed, f.isdisplayedgrid, f.seqno
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'HCO Forms and Approvals' AND t.tablevel = 0 AND c.columnname='Summary';
