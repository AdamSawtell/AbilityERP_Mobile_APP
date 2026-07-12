-- SAW012 discovery (HCO) — read-only
SELECT relname, n_live_tup, pg_size_pretty(pg_total_relation_size((schemaname||'.'||relname)::regclass)) AS size
FROM pg_stat_user_tables
WHERE relname IN ('ad_session','ad_changelog','ad_pinstance','ad_pinstance_log','ad_pinstance_para','ad_issue')
ORDER BY n_live_tup DESC NULLS LAST;

SELECT w.name, w.ad_window_uu, t.name AS tab, tbl.tablename, t.whereclause, t.orderbyclause, t.maxqueryrecords, tbl.ishighvolume
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
JOIN ad_table tbl ON tbl.ad_table_id = t.ad_table_id
WHERE w.ad_window_uu IN (
  'e91594d7-0b31-406b-9c35-8cb9ea2abc04',
  'b5043d5c-1741-4da0-b261-81936e28d9c5'
)
ORDER BY w.name, t.seqno;
