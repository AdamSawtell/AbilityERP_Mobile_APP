SELECT f.name, c.columnname, f.isreadonly, f.isupdateable AS field_updateable,
       c.isupdateable AS col_updateable, f.isalwaysupdateable
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'HCO Forms and Approvals' AND t.tablevel = 0
  AND c.columnname IN ('Summary','R_RequestType_ID','DocumentNo','R_Status_ID','AbERP_RequestSubmitted','IsActive','Priority')
ORDER BY f.seqno;
