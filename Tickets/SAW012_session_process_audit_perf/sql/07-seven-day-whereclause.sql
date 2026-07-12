-- SAW012: force recent-only parent tabs so COUNT/Find cannot scan full history
-- 7-day window keeps windows usable; older rows still reachable by widening Find
-- only if you also clear/override WhereClause in Advanced (tab WhereClause always applies).
-- For older history within retention: temporarily clear via this SQL or use SQL/reports.
--
-- Combined Process Audit filter: last 7 days AND not Document Validation flood.

UPDATE ad_tab
SET whereclause = 'Created>=SYSDATE-7 AND AD_Process_ID NOT IN (SELECT AD_Process_ID FROM AD_Process WHERE Value IN (''ChuBoe_Validate_Document'',''AbERP_Validate_Document''))',
    updated = now(),
    updatedby = 100
WHERE ad_tab_uu = '58bba03d-cb5c-4230-aeb2-1a435ae41b93';

UPDATE ad_tab
SET whereclause = 'Created>=SYSDATE-7',
    updated = now(),
    updatedby = 100
WHERE ad_tab_uu = '939cc571-7724-4631-977a-ec54f21ea0b3';

-- Change Audit: only last 7 days of changes for the session (extra safety)
UPDATE ad_tab
SET whereclause = 'Created>=SYSDATE-7',
    updated = now(),
    updatedby = 100
WHERE ad_tab_uu = '3a8be5bf-fd95-460a-8c4d-2996f46b767e';

SELECT w.name, t.name AS tab, t.maxqueryrecords, t.whereclause
FROM ad_tab t JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE t.ad_tab_uu IN (
  '58bba03d-cb5c-4230-aeb2-1a435ae41b93',
  '939cc571-7724-4631-977a-ec54f21ea0b3',
  '3a8be5bf-fd95-460a-8c4d-2996f46b767e'
)
ORDER BY 1,2;
