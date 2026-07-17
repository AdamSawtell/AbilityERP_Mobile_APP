-- =============================================================================
-- SAW027 — verify
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_n INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_n FROM ad_table
  WHERE tablename IN (
    'AbERP_ActivityAuditTerm','AbERP_ActivityAuditTermAudit',
    'AbERP_ActivityAuditProc','AbERP_ActivityAuditReview','AbERP_ActivityAuditRunt');
  IF v_n < 5 THEN
    RAISE EXCEPTION 'SAW027 verify: expected 5 AD tables, found %', v_n;
  END IF;

  SELECT COUNT(*) INTO v_n FROM ad_window
  WHERE ad_window_uu IN (
    '27a02740-c0d4-4f01-8e15-000000000001',
    '27a02750-c0d4-4f01-8e15-000000000001',
    '27a02760-c0d4-4f01-8e15-000000000001');
  IF v_n < 3 THEN
    RAISE EXCEPTION 'SAW027 verify: windows missing (% )', v_n;
  END IF;

  SELECT COUNT(*) INTO v_n FROM ad_process
  WHERE value IN (
    'AbERP_ActivityAudit_Nightly',
    'AbERP_ActivityAudit_Historical',
    'AbERP_ActivityAudit_OpenActivity');
  IF v_n < 3 THEN
    RAISE EXCEPTION 'SAW027 verify: processes missing (% )', v_n;
  END IF;

  SELECT COUNT(*) INTO v_n FROM ad_scheduler
  WHERE ad_scheduler_uu = '27a02790-c0d4-4f01-8e15-000000000001'
     OR name = 'Activity Audit Nightly';
  IF v_n < 1 THEN
    RAISE EXCEPTION 'SAW027 verify: scheduler missing';
  END IF;

  SELECT COUNT(*) INTO v_n FROM aberp_activityauditterm WHERE isactive = 'Y';
  RAISE NOTICE 'SAW027 verify OK — active terms=%', v_n;
END $$;
