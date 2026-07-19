SET search_path TO adempiere;
SELECT ad_window_id, name, ad_window_uu FROM ad_window
WHERE name ILIKE '%Activity Viewer%' OR name ILIKE '%Support Location%' OR name ILIKE '%Employee%' OR name ILIKE '%Client%' OR name ILIKE '%Business Partner%'
ORDER BY name;
SELECT t.name, tb.tablename, t.seqno
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id=t.ad_window_id
JOIN ad_table tb ON tb.ad_table_id=t.ad_table_id
WHERE w.name='Activity Viewer' ORDER BY t.seqno;
SELECT c.columnname, f.name, f.isdisplayed, f.seqno, fg.name AS fieldgroup
FROM ad_field f
JOIN ad_column c ON c.ad_column_id=f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id=f.ad_tab_id
JOIN ad_window w ON w.ad_window_id=t.ad_window_id
LEFT JOIN ad_fieldgroup fg ON fg.ad_fieldgroup_id=f.ad_fieldgroup_id
WHERE w.name='Activity Viewer' AND t.seqno=10
  AND c.columnname IN ('C_BPartner_ID','AD_User_ID','AbERP_Support_Location_ID','AbERP_MasterLocation_ID','C_BPartner_Staff_ID','SalesRep_ID')
ORDER BY f.seqno;
SELECT columnname FROM ad_column
WHERE ad_table_id=(SELECT ad_table_id FROM ad_table WHERE tablename='C_BPartner')
  AND columnname ILIKE '%employee%' OR columnname ILIKE '%customer%' OR columnname ILIKE '%vendor%'
ORDER BY 1 LIMIT 30;
