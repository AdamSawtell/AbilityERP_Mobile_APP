SELECT f.name, c.columnname, f.isreadonly, f.readonlylogic, c.isupdateable, c.readonlylogic AS col_ro_logic
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'HCO Forms and Approvals' AND t.tablevel = 0
  AND c.columnname IN ('Summary','Priority','Comments','Description','R_RequestType_ID','IsActive')
ORDER BY f.seqno;

SELECT t.name, t.isreadonly, t.readonlylogic, t.isinsertrecord, t.issinglerow
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'HCO Forms and Approvals' AND t.tablevel = 0;

-- window access for Admin / SuperUser roles
SELECT r.name, wa.isreadwrite, wa.isactive
FROM ad_window_access wa
JOIN ad_role r ON r.ad_role_id = wa.ad_role_id
JOIN ad_window w ON w.ad_window_id = wa.ad_window_id
WHERE w.name = 'HCO Forms and Approvals'
  AND r.name IN ('Admin','AbilityERP Admin','GardenWorld Admin','HCO Admin')
ORDER BY r.name;
