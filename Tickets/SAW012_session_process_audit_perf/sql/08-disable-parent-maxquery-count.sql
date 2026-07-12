-- SAW012: stop expensive COUNT(*) on open/Find
-- Tab MaxQueryRecords>0 makes ZK run SELECT COUNT(*) over the full match set.
-- Without a usable Created index that scans ~71M rows for minutes.
-- Keep High Volume (Find-first) + 7-day WhereClause; parent MaxQueryRecords=0
-- so results load for the 7-day window without a full-table COUNT.
-- Child tabs stay capped at 200.

UPDATE ad_tab
SET maxqueryrecords = 0,
    updated = now(),
    updatedby = 100
WHERE ad_tab_uu IN (
  '58bba03d-cb5c-4230-aeb2-1a435ae41b93', -- Process Audit
  '939cc571-7724-4631-977a-ec54f21ea0b3'  -- Session Audit
);

SELECT w.name, t.name AS tab, t.maxqueryrecords, left(t.whereclause,100) AS whereclause
FROM ad_tab t JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE t.ad_tab_uu IN (
  '58bba03d-cb5c-4230-aeb2-1a435ae41b93',
  '939cc571-7724-4631-977a-ec54f21ea0b3',
  '3a8be5bf-fd95-460a-8c4d-2996f46b767e',
  '3e2298f0-8cfe-4520-8518-5bd176c8ec7f',
  '0fa84b5c-6d82-4915-8907-81b52d93bf0e'
)
ORDER BY w.name, t.seqno;
