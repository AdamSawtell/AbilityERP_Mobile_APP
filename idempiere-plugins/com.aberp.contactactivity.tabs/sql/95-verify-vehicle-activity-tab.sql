-- SAW026 read-only verification.
\pset pager off
SET search_path TO adempiere;

SELECT w.ad_window_id, w.ad_window_uu, w.name AS window_name,
       t.ad_tab_id, t.ad_tab_uu, t.seqno, t.isactive,
       c.columnname AS link_column,
       ref.name AS link_reference,
       value_ref.name AS vehicle_reference,
       value_ref.ad_reference_uu AS vehicle_reference_uu,
       COUNT(f.ad_field_id) AS active_field_count
FROM ad_window w
JOIN ad_tab t ON t.ad_window_id = w.ad_window_id
JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
LEFT JOIN ad_column c ON c.ad_column_id = t.ad_column_id
LEFT JOIN ad_reference ref ON ref.ad_reference_id = c.ad_reference_id
LEFT JOIN ad_reference value_ref
  ON value_ref.ad_reference_id = c.ad_reference_value_id
LEFT JOIN ad_field f ON f.ad_tab_id = t.ad_tab_id AND f.isactive = 'Y'
WHERE w.name = 'Vehicle'
  AND t.name = 'Activity'
  AND tb.tablename = 'C_ContactActivity'
GROUP BY w.ad_window_id, w.ad_window_uu, w.name,
         t.ad_tab_id, t.ad_tab_uu, t.seqno, t.isactive, c.columnname,
         ref.name, value_ref.name, value_ref.ad_reference_uu;

SELECT rl.value, rl.name,
       CASE
         WHEN ',' || COALESCE(rl.description, '') || ','
              LIKE '%,' || w.ad_window_id::text || ',%' THEN 'Y'
         ELSE 'N'
       END AS enabled
FROM ad_ref_list rl
JOIN ad_column c ON c.ad_reference_value_id = rl.ad_reference_id
JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
CROSS JOIN ad_window w
WHERE tb.tablename = 'C_ContactActivity'
  AND c.columnname = 'ContactActivityType'
  AND rl.value IN ('EM', 'ME', 'PC', 'CN', 'TA')
  AND rl.isactive = 'Y'
  AND w.name = 'Vehicle'
  AND w.isactive = 'Y'
ORDER BY rl.value;

SELECT r.name AS role_name, wa.isactive, wa.isreadwrite
FROM ad_window_access wa
JOIN ad_role r ON r.ad_role_id = wa.ad_role_id
JOIN ad_window w ON w.ad_window_id = wa.ad_window_id
WHERE w.name = 'Vehicle'
  AND r.name IN ('AbilityERP Admin', 'Admin')
ORDER BY r.name;

SELECT c.columnname, f.name, f.seqno, f.isdisplayed,
       f.seqnogrid, f.isdisplayedgrid, f.numlines
FROM ad_field f
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE w.name = 'Vehicle'
  AND t.name = 'Activity'
  AND tb.tablename = 'C_ContactActivity'
ORDER BY f.seqnogrid, f.seqno, c.columnname;

SELECT tc.ad_user_id, tc.isactive, tc.custom
FROM ad_tab_customization tc
JOIN ad_tab t ON t.ad_tab_id = tc.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Vehicle'
  AND t.name = 'Activity'
ORDER BY tc.ad_user_id;

SELECT COUNT(*) AS activities_linked_to_vehicle
FROM c_contactactivity
WHERE aberp_vehicle_id IS NOT NULL;

SELECT ca.c_contactactivity_id, ca.contactactivitytype, ca.description,
       ca.aberp_vehicle_id, v.value AS vehicle_search_key
FROM c_contactactivity ca
JOIN aberp_vehicle v
  ON v.aberp_vehicle_id = ca.aberp_vehicle_id
WHERE ca.aberp_vehicle_id IS NOT NULL
ORDER BY ca.c_contactactivity_id DESC
LIMIT 20;
