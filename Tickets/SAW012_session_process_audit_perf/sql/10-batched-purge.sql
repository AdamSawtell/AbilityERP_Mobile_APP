-- SAW012: one-time batched purge (90-day retention) — OFF-PEAK
-- SAFE: never deletes AD_PInstance rows still referenced by:
--   C_Order, C_OrderLine, aberp_rostered_shift, chuboe_trialbalance_hdr, T_CombinedAging
-- (those FKs can CASCADE-delete business rows or block delete).
--
-- Run AFTER 02-indexes.sql. Set statement_timeout = 0.
-- Re-run until notices show 0 deleted. Then VACUUM (optional, off-peak).
--
-- Order: ChangeLog → Issue → PInstance (Doc Validation first, then other safe) → Session orphans

SET statement_timeout = 0;

DO $$
DECLARE
  v_batch int := 25000;
  v_deleted int;
  v_total int := 0;
  v_cutoff timestamptz := now() - interval '90 days';
  v_proc_ids int[];
  v_loops int;
  v_max_loops int := 40; -- ~1M rows per invoke; re-run script for more
BEGIN
  SELECT coalesce(array_agg(ad_process_id), ARRAY[]::int[])
  INTO v_proc_ids
  FROM ad_process
  WHERE value IN ('ChuBoe_Validate_Document', 'AbERP_Validate_Document');

  -- 1) ChangeLog
  v_loops := 0;
  LOOP
    DELETE FROM ad_changelog
    WHERE ad_changelog_id IN (
      SELECT ad_changelog_id FROM ad_changelog
      WHERE created < v_cutoff
      ORDER BY ad_changelog_id
      LIMIT v_batch
    );
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    v_total := v_total + v_deleted;
    v_loops := v_loops + 1;
    EXIT WHEN v_deleted = 0 OR v_loops >= v_max_loops;
  END LOOP;
  RAISE NOTICE 'SAW012 ChangeLog deleted this run: %', v_total;

  -- 2) Issue
  v_total := 0; v_loops := 0;
  LOOP
    DELETE FROM ad_issue
    WHERE ad_issue_id IN (
      SELECT ad_issue_id FROM ad_issue
      WHERE created < v_cutoff
      ORDER BY ad_issue_id
      LIMIT v_batch
    );
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    v_total := v_total + v_deleted;
    v_loops := v_loops + 1;
    EXIT WHEN v_deleted = 0 OR v_loops >= v_max_loops;
  END LOOP;
  RAISE NOTICE 'SAW012 Issue deleted this run: %', v_total;

  -- 3a) Document Validation PInstances (bulk of the 28GB)
  v_total := 0; v_loops := 0;
  IF array_length(v_proc_ids, 1) IS NOT NULL THEN
    LOOP
      DELETE FROM ad_pinstance
      WHERE ad_pinstance_id IN (
        SELECT i.ad_pinstance_id
        FROM ad_pinstance i
        WHERE i.created < v_cutoff
          AND i.ad_process_id = ANY (v_proc_ids)
          AND NOT EXISTS (SELECT 1 FROM c_order o WHERE o.ad_pinstance_id = i.ad_pinstance_id)
          AND NOT EXISTS (SELECT 1 FROM c_orderline ol WHERE ol.ad_pinstance_id = i.ad_pinstance_id)
          AND NOT EXISTS (SELECT 1 FROM aberp_rostered_shift r WHERE r.ad_pinstance_id = i.ad_pinstance_id)
          AND NOT EXISTS (SELECT 1 FROM chuboe_trialbalance_hdr h WHERE h.ad_pinstance_id = i.ad_pinstance_id)
          AND NOT EXISTS (SELECT 1 FROM t_combinedaging a WHERE a.ad_pinstance_id = i.ad_pinstance_id)
        ORDER BY i.ad_pinstance_id
        LIMIT v_batch
      );
      GET DIAGNOSTICS v_deleted = ROW_COUNT;
      v_total := v_total + v_deleted;
      v_loops := v_loops + 1;
      EXIT WHEN v_deleted = 0 OR v_loops >= v_max_loops;
    END LOOP;
  END IF;
  RAISE NOTICE 'SAW012 DocValidation PInstance deleted this run: %', v_total;

  -- 3b) Other safe old PInstances
  v_total := 0; v_loops := 0;
  LOOP
    DELETE FROM ad_pinstance
    WHERE ad_pinstance_id IN (
      SELECT i.ad_pinstance_id
      FROM ad_pinstance i
      WHERE i.created < v_cutoff
        AND (v_proc_ids IS NULL OR NOT (i.ad_process_id = ANY (v_proc_ids)))
        AND NOT EXISTS (SELECT 1 FROM c_order o WHERE o.ad_pinstance_id = i.ad_pinstance_id)
        AND NOT EXISTS (SELECT 1 FROM c_orderline ol WHERE ol.ad_pinstance_id = i.ad_pinstance_id)
        AND NOT EXISTS (SELECT 1 FROM aberp_rostered_shift r WHERE r.ad_pinstance_id = i.ad_pinstance_id)
        AND NOT EXISTS (SELECT 1 FROM chuboe_trialbalance_hdr h WHERE h.ad_pinstance_id = i.ad_pinstance_id)
        AND NOT EXISTS (SELECT 1 FROM t_combinedaging a WHERE a.ad_pinstance_id = i.ad_pinstance_id)
      ORDER BY i.ad_pinstance_id
      LIMIT v_batch
    );
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    v_total := v_total + v_deleted;
    v_loops := v_loops + 1;
    EXIT WHEN v_deleted = 0 OR v_loops >= v_max_loops;
  END LOOP;
  RAISE NOTICE 'SAW012 other PInstance deleted this run: %', v_total;

  -- 4) Orphan sessions
  v_total := 0; v_loops := 0;
  LOOP
    DELETE FROM ad_session
    WHERE ad_session_id IN (
      SELECT s.ad_session_id
      FROM ad_session s
      WHERE s.created < v_cutoff
        AND NOT EXISTS (SELECT 1 FROM ad_changelog cl WHERE cl.ad_session_id = s.ad_session_id)
        AND NOT EXISTS (SELECT 1 FROM ad_pinstance pi WHERE pi.ad_session_id = s.ad_session_id)
        AND NOT EXISTS (SELECT 1 FROM ad_scheduler sch WHERE sch.ad_session_id = s.ad_session_id)
      ORDER BY s.ad_session_id
      LIMIT v_batch
    );
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    v_total := v_total + v_deleted;
    v_loops := v_loops + 1;
    EXIT WHEN v_deleted = 0 OR v_loops >= v_max_loops;
  END LOOP;
  RAISE NOTICE 'SAW012 Session deleted this run: %', v_total;
END $$;

SELECT relname, n_live_tup,
       pg_size_pretty(pg_total_relation_size((schemaname||'.'||relname)::regclass)) AS size
FROM pg_stat_user_tables
WHERE relname IN ('ad_pinstance','ad_changelog','ad_issue','ad_session')
ORDER BY n_live_tup DESC;
