-- Hide User/Contact (AD_User_ID) on ALL C_ContactActivity tabs.
-- No hardcoded IDs — matches by table + column name.
-- Log out/in after running.
SET search_path TO adempiere;

UPDATE ad_field
SET isdisplayed = 'N',
    isdisplayedgrid = 'N',
    defaultvalue = NULL,
    updated = NOW(),
    updatedby = 100
WHERE ad_field_id IN (
  SELECT f.ad_field_id
  FROM ad_field f
  JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
  JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
  JOIN ad_column col ON col.ad_column_id = f.ad_column_id
  WHERE tb.tablename = 'C_ContactActivity'
    AND col.columnname = 'AD_User_ID'
    AND f.isactive = 'Y'
);

-- Verify
SELECT w.name AS window_name, t.name AS tab_name, f.name AS field_name,
       f.isdisplayed, f.isdisplayedgrid, f.defaultvalue
FROM ad_field f
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
JOIN ad_column col ON col.ad_column_id = f.ad_column_id
WHERE tb.tablename = 'C_ContactActivity'
  AND col.columnname = 'AD_User_ID'
  AND f.isactive = 'Y'
ORDER BY w.name, t.name;
