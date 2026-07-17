\pset pager off
SET search_path TO adempiere;

SELECT w.name AS window_name, t.ad_tab_id, t.ad_column_id AS tab_link_column_id,
       c.columnname, c.isparent AS column_isparent,
       f.ad_field_id, f.defaultvalue, f.isdisplayed, f.isreadonly, f.ismandatory
FROM ad_window w
JOIN ad_tab t ON t.ad_window_id = w.ad_window_id
JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
JOIN ad_column c ON c.ad_column_id = t.ad_column_id
LEFT JOIN ad_field f
  ON f.ad_tab_id = t.ad_tab_id
 AND f.ad_column_id = t.ad_column_id
WHERE w.name IN ('Enquiry', 'Booking Generator', 'Vehicle')
  AND t.name = 'Activity'
  AND tb.tablename = 'C_ContactActivity'
ORDER BY w.name;
