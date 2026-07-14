-- =============================================================================
-- SAW019 — verify
-- =============================================================================
SET search_path TO adempiere;

SELECT 'table' AS kind, tablename, ad_table_uu
FROM ad_table
WHERE tablename IN ('AbERP_InvoiceCapture', 'AbERP_InvoiceCaptureLog');

SELECT 'window' AS kind, name, ad_window_uu FROM ad_window WHERE name = 'Invoice Capture';

SELECT 'process' AS kind, value, name, classname, ad_process_uu
FROM ad_process
WHERE value LIKE 'AbERP_InvoiceCapture%'
ORDER BY value;

SELECT 'button' AS kind, c.columnname, c.istoolbarbutton, p.name AS process
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
LEFT JOIN ad_process p ON p.ad_process_id = c.ad_process_id
WHERE t.tablename = 'AbERP_InvoiceCapture' AND c.columnname = 'AbERP_ProcessSelected';

SELECT 'scheduler' AS kind, s.name, s.isactive, p.value
FROM ad_scheduler s
JOIN ad_process p ON p.ad_process_id = s.ad_process_id
WHERE s.ad_scheduler_uu = '19a0190a-c0d4-4f01-8e15-000000000001'
   OR s.name = 'Invoice Capture Nightly Batch';

SELECT 'access' AS kind, r.name AS role, 'window' AS obj
FROM ad_window_access wa
JOIN ad_window w ON w.ad_window_id = wa.ad_window_id
JOIN ad_role r ON r.ad_role_id = wa.ad_role_id AND r.ad_client_id = wa.ad_client_id
WHERE w.name = 'Invoice Capture'
ORDER BY 2, 1;
