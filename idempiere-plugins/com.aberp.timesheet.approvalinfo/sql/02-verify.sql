-- SAW010 verify: Timesheet Approval Info Window columns after cleanup

SET search_path TO adempiere;
\pset pager off

\echo '=== DISPLAYED RESULT COLUMNS (expected order) ==='
SELECT seqno, columnname, name, selectclause, isdisplayed, isquerycriteria, ad_reference_id,
       ad_infocolumn_uu
FROM ad_infocolumn
WHERE ad_infowindow_id = (
  SELECT ad_infowindow_id FROM ad_infowindow
  WHERE ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4'
)
  AND isdisplayed = 'Y'
  AND isactive = 'Y'
ORDER BY seqno;

\echo '=== HIDDEN BUT STILL CRITERIA ==='
SELECT seqno, columnname, name, isdisplayed, isquerycriteria
FROM ad_infocolumn
WHERE ad_infowindow_id = (
  SELECT ad_infowindow_id FROM ad_infowindow
  WHERE ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4'
)
  AND isdisplayed = 'N'
  AND isquerycriteria = 'Y'
  AND isactive = 'Y'
ORDER BY seqnoselection, seqno;

\echo '=== REMOVED FROM GRID MUST BE isdisplayed=N ==='
SELECT columnname, name, isdisplayed, isquerycriteria
FROM ad_infocolumn
WHERE ad_infocolumn_uu IN (
  '39fb0ffb-58e5-46e7-8966-48b2fb223b86', -- Shift Cost
  '6f1c18f1-43b5-4cab-8f13-8d5960c602cd', -- Name
  '750b7e9f-1299-49c6-8477-616de3c4b0de', -- Employee IsEmployee
  '890d8791-326b-4092-beb5-9046587d7556', -- Activity
  '61e09e5f-222b-4bb6-bb29-ae8fb785f4e9'  -- Business Partner
)
ORDER BY columnname;

\echo '=== BREAK COLUMNS ==='
SELECT seqno, columnname, name, selectclause, ad_reference_id, isdisplayed, ad_infocolumn_uu
FROM ad_infocolumn
WHERE ad_infocolumn_uu IN (
  'c4e8a1b2-5d6f-4a7c-9e01-2b3d4f5a6c70',
  'd5f9b2c3-6e70-4b8d-a012-3c4e5f6a7b81'
)
ORDER BY seqno;

\echo '=== PROCESS BIND STILL ON TIMESHEET ID ==='
SELECT p.name, ic.columnname, ic.isdisplayed, ic.ad_infocolumn_uu
FROM ad_infoprocess ip
JOIN ad_process p ON p.ad_process_id = ip.ad_process_id
JOIN ad_infocolumn ic ON ic.ad_infocolumn_id = ip.ad_infocolumn_id
WHERE ip.ad_infowindow_id = (
  SELECT ad_infowindow_id FROM ad_infowindow
  WHERE ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4'
)
  AND p.ad_process_uu = '3a3c2c41-995c-41ba-9fde-caeaacee1d75';

DO $$
DECLARE
  v_bad INT := 0;
BEGIN
  SELECT COUNT(*) INTO v_bad
  FROM ad_infocolumn
  WHERE ad_infocolumn_uu IN (
    '39fb0ffb-58e5-46e7-8966-48b2fb223b86',
    '6f1c18f1-43b5-4cab-8f13-8d5960c602cd',
    '750b7e9f-1299-49c6-8477-616de3c4b0de',
    '890d8791-326b-4092-beb5-9046587d7556',
    '61e09e5f-222b-4bb6-bb29-ae8fb785f4e9'
  )
    AND isdisplayed = 'Y';

  IF v_bad > 0 THEN
    RAISE EXCEPTION 'VERIFY FAIL: % columns still displayed that should be hidden', v_bad;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM ad_infocolumn
    WHERE ad_infocolumn_uu = 'c4e8a1b2-5d6f-4a7c-9e01-2b3d4f5a6c70'
      AND isdisplayed = 'Y' AND seqno = 72 AND selectclause = 't.AbERP_Break_Start'
  ) THEN
    RAISE EXCEPTION 'VERIFY FAIL: Break Start missing or wrong';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM ad_infocolumn
    WHERE ad_infocolumn_uu = 'd5f9b2c3-6e70-4b8d-a012-3c4e5f6a7b81'
      AND isdisplayed = 'Y' AND seqno = 74 AND selectclause = 't.AbERP_Break_End'
  ) THEN
    RAISE EXCEPTION 'VERIFY FAIL: Break End missing or wrong';
  END IF;

  -- Shift Type must still be immediately before Break Start in display seq
  IF NOT EXISTS (
    SELECT 1 FROM ad_infocolumn
    WHERE ad_infocolumn_uu = 'ceb58d4d-63a8-4325-87f6-3e104d62f213'
      AND isdisplayed = 'Y' AND seqno = 70
  ) THEN
    RAISE EXCEPTION 'VERIFY FAIL: Shift Type not at seqno 70 displayed';
  END IF;

  RAISE NOTICE 'VERIFY OK: SAW010 Timesheet Approval Info columns';
END $$;
