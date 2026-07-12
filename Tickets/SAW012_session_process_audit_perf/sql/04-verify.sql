-- SAW012 verify
SELECT tablename, ishighvolume FROM ad_table
WHERE tablename IN ('AD_PInstance','AD_Session','AD_Issue','AD_ChangeLog')
ORDER BY 1;

SELECT w.name, t.name AS tab, t.maxqueryrecords, t.orderbyclause
FROM ad_tab t JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE t.ad_tab_uu IN (
  '58bba03d-cb5c-4230-aeb2-1a435ae41b93',
  '939cc571-7724-4631-977a-ec54f21ea0b3'
);

SELECT c.columnname, f.isselectioncolumn
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE f.isselectioncolumn = 'Y'
  AND f.ad_tab_id IN (
    SELECT ad_tab_id FROM ad_tab WHERE ad_tab_uu IN (
      '58bba03d-cb5c-4230-aeb2-1a435ae41b93',
      '939cc571-7724-4631-977a-ec54f21ea0b3'
    )
  )
ORDER BY 1;

SELECT indexname FROM pg_indexes
WHERE indexname IN (
  'ad_pinstance_created_ix','ad_session_created_ix',
  'ad_changelog_session_created_ix','ad_issue_created_ix',
  'ad_pinstance_process_created_ix'
)
ORDER BY 1;

SELECT value, isactive FROM ad_housekeeping WHERE value LIKE '%_90d' ORDER BY 1;
SELECT name, isactive FROM ad_scheduler WHERE name LIKE 'Housekeeping AD_%90d' ORDER BY 1;
