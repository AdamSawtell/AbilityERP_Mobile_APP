SET search_path TO adempiere;

SELECT ad_element_id, columnname, name, ad_element_uu
FROM ad_element
WHERE columnname IN ('CopyFrom', 'AbERP_CopyDatesFrom')
ORDER BY columnname;

SELECT entitytype, name FROM ad_entitytype WHERE entitytype IN ('Ab_ERP','U','D') OR name ILIKE '%Ab%ERP%';

SELECT f.name, f.isdisplayed, f.istoolbarbutton, c.columnname, c.istoolbarbutton AS col_toolbar
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Service Booking' AND t.name = 'Service Booking' AND c.columnname = 'CopyFrom';

SELECT aberp_dates_id, aberp_skip_dates_id, startdate::date, enddate::date, left(coalesce(description,''),40)
FROM aberp_dates WHERE aberp_skip_dates_id = 1000006 ORDER BY startdate LIMIT 5;
