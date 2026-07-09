SET search_path TO adempiere;
SELECT w.name, t.ad_tab_id, COUNT(f.ad_field_id) AS field_count
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
LEFT JOIN ad_field f ON f.ad_tab_id = t.ad_tab_id AND f.isactive='Y'
WHERE t.ad_tab_id IN (1000424, 1000425, 1000426)
GROUP BY w.name, t.ad_tab_id;
SELECT MAX(ad_field_id) FROM ad_field;
SELECT ad_field_id, name FROM ad_field WHERE ad_field_id BETWEEN 1010800 AND 1010850 ORDER BY ad_field_id;
