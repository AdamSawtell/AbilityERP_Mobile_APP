SET search_path TO adempiere;
SELECT m.name, m.action, m.ad_window_id, m.isactive
FROM ad_menu m
WHERE m.name ILIKE '%Skip%Date%'
ORDER BY m.name;
