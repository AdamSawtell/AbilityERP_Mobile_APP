-- SAW012: supporting indexes for Find / Created filters
-- Run OUTSIDE an explicit transaction. Prefer CONCURRENTLY on live hosts
-- (idempiere may need: SET statement_timeout = 0).
--
-- If CONCURRENTLY is not available in your apply path, use the non-concurrent
-- block at the bottom (takes an ACCESS EXCLUSIVE-ish lock during build — off-peak).

SET statement_timeout = 0;

CREATE INDEX CONCURRENTLY IF NOT EXISTS ad_pinstance_created_ix
  ON adempiere.ad_pinstance (created DESC);

-- Faster alternative on huge sites (immutable date literal — refresh cutoff yearly):
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS ad_pinstance_created_90d_ix
--   ON adempiere.ad_pinstance (created DESC) WHERE created >= DATE '2026-04-13';


CREATE INDEX CONCURRENTLY IF NOT EXISTS ad_session_created_ix
  ON adempiere.ad_session (created DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS ad_changelog_session_created_ix
  ON adempiere.ad_changelog (ad_session_id, created DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS ad_issue_created_ix
  ON adempiere.ad_issue (created DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS ad_pinstance_process_created_ix
  ON adempiere.ad_pinstance (ad_process_id, created DESC);

ANALYZE adempiere.ad_pinstance;
ANALYZE adempiere.ad_session;
ANALYZE adempiere.ad_changelog;
ANALYZE adempiere.ad_issue;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename IN ('ad_pinstance','ad_session','ad_changelog','ad_issue')
  AND indexname LIKE '%created%'
ORDER BY tablename, indexname;

-- ---------------------------------------------------------------------------
-- Fallback (non-concurrent) — only if CONCURRENTLY fails in your client:
-- CREATE INDEX IF NOT EXISTS ad_pinstance_created_ix ON adempiere.ad_pinstance (created DESC);
-- CREATE INDEX IF NOT EXISTS ad_session_created_ix ON adempiere.ad_session (created DESC);
-- CREATE INDEX IF NOT EXISTS ad_changelog_session_created_ix ON adempiere.ad_changelog (ad_session_id, created DESC);
-- CREATE INDEX IF NOT EXISTS ad_issue_created_ix ON adempiere.ad_issue (created DESC);
-- CREATE INDEX IF NOT EXISTS ad_pinstance_process_created_ix ON adempiere.ad_pinstance (ad_process_id, created DESC);
-- ---------------------------------------------------------------------------
