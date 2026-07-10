SET search_path TO adempiere;

-- How does standard Request Updates tab link?
SELECT w.name AS window, t.name AS tab, t.ad_column_id, t.parent_column_id,
       t.whereclause, t.tablevel, t.issinglerow, t.isreadonly,
       c.columnname AS link_col, c.isparent
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
LEFT JOIN ad_column c ON c.ad_column_id = t.ad_column_id
WHERE tb.tablename = 'R_RequestUpdate' AND t.isactive = 'Y'
ORDER BY w.name, t.ad_tab_id;

-- IsParent on R_RequestUpdate.R_Request_ID?
SELECT c.columnname, c.isparent, c.iskey, c.ad_reference_id
FROM ad_column c
JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
WHERE tb.tablename = 'R_RequestUpdate' AND c.columnname = 'R_Request_ID';

-- Fields on standard Request Updates vs ours
SELECT w.name, f.name, c.columnname, f.isdisplayed, f.isdisplayedgrid, f.seqno
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE t.name = 'Updates' AND w.name IN ('Request', 'Rostering Chat')
ORDER BY w.name, f.seqno;
