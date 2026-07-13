-- Temporarily allow Summary edit for SAW013 browser save E2E (restore after)
UPDATE ad_field f
SET isupdateable = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'HCO Forms and Approvals'
  AND t.tablevel = 0
  AND c.columnname = 'Summary'
  AND COALESCE(f.isupdateable,'Y') = 'N';

SELECT f.name, f.isupdateable
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'HCO Forms and Approvals' AND t.tablevel = 0 AND c.columnname = 'Summary';
