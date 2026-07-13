SELECT f.name, c.columnname, f.isreadonly, c.isupdateable, f.displaylogic
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'HCO Forms and Approvals' AND t.tablevel = 0
  AND c.columnname IN ('Summary','R_Status_ID','AbERP_RequestSubmitted','R_RequestType_ID','DocumentNo','AbERP_CreateShiftChangeRequest')
ORDER BY f.seqno;

SELECT ad_tab_id, name, isreadonly, readonlylogic, isinsertrecord
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'HCO Forms and Approvals' AND t.tablevel = 0;

SELECT documentno, aberp_requestsubmitted, r_status_id, isactive
FROM aberp_shiftchange WHERE documentno IN ('1000000','1003729','1003753');
