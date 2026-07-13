SELECT f.name, c.columnname, f.isupdateable AS fld_upd, c.isupdateable AS col_upd,
       f.isreadonly, f.isdisplayed
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'HCO Forms and Approvals' AND t.tablevel = 0
  AND c.columnname IN (
    'Summary','AbERP_Transport_Required','HCO_NomineeReq','HCO_NewRatio',
    'Priority','R_RequestType_ID','DocumentNo','IsActive','StartDate','EndDate'
  )
ORDER BY f.seqno;

SELECT documentno, aberp_transport_required, hco_nomineereq, priority
FROM aberp_shiftchange WHERE documentno IN ('1003753','1003729');
