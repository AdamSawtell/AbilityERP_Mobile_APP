SET search_path TO adempiere;

SELECT 'tab' AS check_type, t.name, t.issinglerow, t.isreadonly, t.isinsertrecord
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat';

SELECT 'field' AS check_type, f.name, f.isreadonly, f.isupdateable, f.isdisplayed, f.seqno
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname = 'AbERP_RosteringReply';

SELECT 'column' AS check_type, c.columnname, c.isupdateable, c.isalwaysupdateable, c.isreadonly, c.fieldlength
FROM ad_column c
JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
WHERE tb.tablename = 'R_Request' AND c.columnname = 'AbERP_RosteringReply';
