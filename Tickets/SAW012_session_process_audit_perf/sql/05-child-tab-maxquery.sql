-- SAW012 follow-up: cap child tabs so next/prev record navigation stays fast
-- Change Audit / Parameter / Log were MaxQueryRecords=0 → every parent move loads all children.

UPDATE ad_tab t
SET maxqueryrecords = 200,
    updated = now(),
    updatedby = 100
WHERE t.ad_tab_uu IN (
  '3a8be5bf-fd95-460a-8c4d-2996f46b767e', -- Session Audit → Change Audit
  '3e2298f0-8cfe-4520-8518-5bd176c8ec7f', -- Process Audit → Parameter Audit
  '0fa84b5c-6d82-4915-8907-81b52d93bf0e'  -- Process Audit → Log
);

UPDATE ad_tab SET orderbyclause = 'Created DESC', updated = now(), updatedby = 100
WHERE ad_tab_uu = '3a8be5bf-fd95-460a-8c4d-2996f46b767e';

UPDATE ad_tab SET orderbyclause = 'SeqNo', updated = now(), updatedby = 100
WHERE ad_tab_uu = '3e2298f0-8cfe-4520-8518-5bd176c8ec7f';

UPDATE ad_tab SET orderbyclause = 'Log_ID', updated = now(), updatedby = 100
WHERE ad_tab_uu = '0fa84b5c-6d82-4915-8907-81b52d93bf0e';

SELECT w.name AS win, t.name AS tab, t.maxqueryrecords, t.orderbyclause
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE t.ad_tab_uu IN (
  '58bba03d-cb5c-4230-aeb2-1a435ae41b93',
  '3e2298f0-8cfe-4520-8518-5bd176c8ec7f',
  '0fa84b5c-6d82-4915-8907-81b52d93bf0e',
  '939cc571-7724-4631-977a-ec54f21ea0b3',
  '3a8be5bf-fd95-460a-8c4d-2996f46b767e'
)
ORDER BY w.name, t.seqno;
