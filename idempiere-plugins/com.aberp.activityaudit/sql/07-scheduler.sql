-- =============================================================================
-- SAW027 — Nightly scheduler
-- Scheduler UU: 27a02790-c0d4-4f01-8e15-000000000001
-- Schedule: core "1 Day" UU 5a06dc76-704e-40f5-bfcf-724829332c50
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_scheduler_id),0)+1 FROM ad_scheduler))
WHERE name='AD_Scheduler' AND istableid='Y';

DO $$
DECLARE
  v_sched_uu CONSTANT TEXT := '27a02790-c0d4-4f01-8e15-000000000001';
  v_process_id INTEGER;
  v_schedule_id INTEGER;
  v_sched_id INTEGER;
  v_client_id INTEGER;
BEGIN
  SELECT ad_process_id INTO v_process_id
  FROM ad_process
  WHERE ad_process_uu = '27a02770-c0d4-4f01-8e15-000000000001'
     OR value = 'AbERP_ActivityAudit_Nightly'
  LIMIT 1;
  IF v_process_id IS NULL THEN
    RAISE EXCEPTION 'SAW027: nightly process missing — run 05 first';
  END IF;

  SELECT ad_schedule_id INTO v_schedule_id
  FROM ad_schedule
  WHERE ad_schedule_uu = '5a06dc76-704e-40f5-bfcf-724829332c50'
     OR name = '1 Day'
  LIMIT 1;
  IF v_schedule_id IS NULL THEN
    RAISE EXCEPTION 'SAW027: AD_Schedule "1 Day" missing';
  END IF;

  SELECT ad_client_id INTO v_client_id FROM ad_client WHERE name ILIKE 'HCO%' LIMIT 1;
  IF v_client_id IS NULL THEN
    SELECT ad_client_id INTO v_client_id FROM ad_client WHERE name = 'AbilityERP' LIMIT 1;
  END IF;
  IF v_client_id IS NULL THEN
    SELECT ad_client_id INTO v_client_id FROM ad_client WHERE ad_client_id > 0 ORDER BY ad_client_id LIMIT 1;
  END IF;

  SELECT ad_scheduler_id INTO v_sched_id FROM ad_scheduler WHERE ad_scheduler_uu = v_sched_uu;
  IF v_sched_id IS NULL THEN
    SELECT ad_scheduler_id INTO v_sched_id FROM ad_scheduler WHERE name = 'Activity Audit Nightly' LIMIT 1;
  END IF;

  IF v_sched_id IS NULL THEN
    INSERT INTO ad_scheduler (
      ad_scheduler_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_process_id, ad_schedule_id,
      supervisor_id, keeplogdays, processing, isignoreprocessingtime,
      scheduletype, frequencytype, datenextrun, ad_scheduler_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Scheduler' AND istableid = 'Y')::integer, 'N'),
      COALESCE(v_client_id, 0), 0, 'Y',
      NOW(), 100, NOW(), 100,
      'Activity Audit Nightly',
      'Scan Contact Activities updated in the last 24 hours for configured audit terms',
      v_process_id, v_schedule_id,
      100, 30, 'N', 'N',
      'F', 'D', NOW() + INTERVAL '1 day', v_sched_uu
    );
  ELSE
    UPDATE ad_scheduler SET
      name = 'Activity Audit Nightly',
      ad_process_id = v_process_id,
      ad_schedule_id = v_schedule_id,
      isactive = 'Y',
      ad_scheduler_uu = COALESCE(ad_scheduler_uu, v_sched_uu),
      updated = NOW()
    WHERE ad_scheduler_id = v_sched_id;
  END IF;

  RAISE NOTICE 'SAW027 scheduler ready (process=%)', v_process_id;
END $$;
