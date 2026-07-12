-- SAW012: 90-day HouseKeeping for audit tables + daily schedulers
-- Owned UUs (AbERP). Never overwrite an existing row's UU when matching by Value.
--
-- AD_HouseKeeping.whereclause is varchar(255) — FK-safe rules live in helper functions.

CREATE OR REPLACE FUNCTION adempiere.aberp_pinstance_ok_to_purge(p_id numeric)
RETURNS char
LANGUAGE sql
STABLE
AS $$
  SELECT CASE
    WHEN EXISTS (SELECT 1 FROM c_order o WHERE o.ad_pinstance_id = p_id) THEN 'N'
    WHEN EXISTS (SELECT 1 FROM c_orderline ol WHERE ol.ad_pinstance_id = p_id) THEN 'N'
    WHEN EXISTS (SELECT 1 FROM aberp_rostered_shift r WHERE r.ad_pinstance_id = p_id) THEN 'N'
    WHEN EXISTS (SELECT 1 FROM chuboe_trialbalance_hdr h WHERE h.ad_pinstance_id = p_id) THEN 'N'
    WHEN EXISTS (SELECT 1 FROM t_combinedaging a WHERE a.ad_pinstance_id = p_id) THEN 'N'
    ELSE 'Y'
  END;
$$;

CREATE OR REPLACE FUNCTION adempiere.aberp_session_ok_to_purge(p_id numeric)
RETURNS char
LANGUAGE sql
STABLE
AS $$
  SELECT CASE
    WHEN EXISTS (SELECT 1 FROM ad_changelog cl WHERE cl.ad_session_id = p_id) THEN 'N'
    WHEN EXISTS (SELECT 1 FROM ad_pinstance pi WHERE pi.ad_session_id = p_id) THEN 'N'
    WHEN EXISTS (SELECT 1 FROM ad_scheduler s WHERE s.ad_session_id = p_id) THEN 'N'
    ELSE 'Y'
  END;
$$;

DO $$
DECLARE
  v_hk_seq int;
  v_sch_seq int;
  v_proc_hkpara int;
  v_para_hk int;
  v_schedule int;
  v_tbl_pinstance int;
  v_tbl_changelog int;
  v_tbl_session int;
  v_tbl_issue int;
  v_hk_id int;
  v_sch_id int;
  v_client int := 0;
  v_org int := 0;
  v_user int := 100;
BEGIN
  SELECT ad_sequence_id::int INTO v_hk_seq FROM ad_sequence WHERE name = 'AD_HouseKeeping' AND istableid = 'Y' LIMIT 1;
  SELECT ad_sequence_id::int INTO v_sch_seq FROM ad_sequence WHERE name = 'AD_Scheduler' AND istableid = 'Y' LIMIT 1;
  IF v_hk_seq IS NULL OR v_sch_seq IS NULL THEN
    RAISE EXCEPTION 'SAW012: missing AD_HouseKeeping or AD_Scheduler sequence';
  END IF;

  SELECT ad_process_id INTO v_proc_hkpara FROM ad_process WHERE value = 'HouseKeepingPara' LIMIT 1;
  SELECT ad_process_para_id INTO v_para_hk FROM ad_process_para
  WHERE ad_process_id = v_proc_hkpara AND columnname = 'AD_HouseKeeping_ID' LIMIT 1;
  -- Core "1 Day" schedule (portable by UU)
  SELECT ad_schedule_id INTO v_schedule FROM ad_schedule
  WHERE ad_schedule_uu = '5a06dc76-704e-40f5-bfcf-724829332c50' LIMIT 1;
  IF v_proc_hkpara IS NULL OR v_para_hk IS NULL THEN
    RAISE EXCEPTION 'SAW012: HouseKeepingPara / AD_HouseKeeping_ID para missing';
  END IF;
  IF v_schedule IS NULL THEN
    -- fallback: any active daily-ish schedule named 1 Day
    SELECT ad_schedule_id INTO v_schedule FROM ad_schedule WHERE name = '1 Day' ORDER BY ad_schedule_id LIMIT 1;
  END IF;
  IF v_schedule IS NULL THEN
    RAISE EXCEPTION 'SAW012: AD_Schedule 1 Day missing (UU 5a06dc76-704e-40f5-bfcf-724829332c50)';
  END IF;

  SELECT ad_table_id INTO v_tbl_pinstance FROM ad_table WHERE tablename = 'AD_PInstance';
  SELECT ad_table_id INTO v_tbl_changelog FROM ad_table WHERE tablename = 'AD_ChangeLog';
  SELECT ad_table_id INTO v_tbl_session FROM ad_table WHERE tablename = 'AD_Session';
  SELECT ad_table_id INTO v_tbl_issue FROM ad_table WHERE tablename = 'AD_Issue';

  -- ---- helper: upsert HouseKeeping by Value + fixed UU ----
  -- AD_PInstance (90 days, FK-safe)
  IF EXISTS (SELECT 1 FROM ad_housekeeping WHERE value = 'AD_PInstance_90d') THEN
    UPDATE ad_housekeeping SET
      name = 'Delete AD_PInstance older than 90 days (FK-safe)',
      ad_table_id = v_tbl_pinstance,
      tablename = 'AD_PInstance',
      whereclause = 'Created <= SYSDATE - 90 AND aberp_pinstance_ok_to_purge(AD_PInstance_ID)=''Y''',
      isactive = 'Y',
      issaveinhistoric = 'N',
      isexportxmlbackup = 'N',
      help = 'SAW012: retains 90 days. Uses aberp_pinstance_ok_to_purge() so orders/shifts are never cascade-deleted.',
      updated = now(), updatedby = v_user
    WHERE value = 'AD_PInstance_90d'
    RETURNING ad_housekeeping_id INTO v_hk_id;
  ELSE
    v_hk_id := nextid(v_hk_seq, 'N'::varchar);
    INSERT INTO ad_housekeeping (
      ad_housekeeping_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, value, ad_table_id, tablename, whereclause, help,
      isexportxmlbackup, issaveinhistoric, processing, lastdeleted, ad_housekeeping_uu
    ) VALUES (
      v_hk_id, v_client, v_org, 'Y', now(), v_user, now(), v_user,
      'Delete AD_PInstance older than 90 days (FK-safe)', 'AD_PInstance_90d', v_tbl_pinstance, 'AD_PInstance',
      'Created <= SYSDATE - 90 AND aberp_pinstance_ok_to_purge(AD_PInstance_ID)=''Y''',
      'SAW012: retains 90 days. Uses aberp_pinstance_ok_to_purge() so orders/shifts are never cascade-deleted.',
      'N', 'N', 'N', 0, 'b7e2a012-90d1-4a01-9c01-000000000001'
    );
  END IF;

  -- Scheduler for AD_PInstance
  IF EXISTS (SELECT 1 FROM ad_scheduler WHERE ad_scheduler_uu = 'b7e2a012-90d1-4a01-9c02-000000000001') THEN
    UPDATE ad_scheduler SET
      name = 'Housekeeping AD_PInstance 90d', isactive = 'Y',
      ad_process_id = v_proc_hkpara, ad_schedule_id = v_schedule, frequencytype = 'D', frequency = 1, scheduletype = 'F',
      keeplogdays = 7, updated = now(), updatedby = v_user
    WHERE ad_scheduler_uu = 'b7e2a012-90d1-4a01-9c02-000000000001'
    RETURNING ad_scheduler_id INTO v_sch_id;
  ELSIF EXISTS (SELECT 1 FROM ad_scheduler WHERE name = 'Housekeeping AD_PInstance 90d') THEN
    UPDATE ad_scheduler SET
      isactive = 'Y', ad_process_id = v_proc_hkpara, frequencytype = 'D', frequency = 1, scheduletype = 'F',
      keeplogdays = 7, updated = now(), updatedby = v_user
    WHERE name = 'Housekeeping AD_PInstance 90d'
    RETURNING ad_scheduler_id INTO v_sch_id;
  ELSE
    v_sch_id := nextid(v_sch_seq, 'N'::varchar);
    INSERT INTO ad_scheduler (
      ad_scheduler_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, ad_process_id, ad_schedule_id, frequencytype, frequency, scheduletype, keeplogdays,
      processing, supervisor_id, ad_scheduler_uu
    ) VALUES (
      v_sch_id, v_client, v_org, 'Y', now(), v_user, now(), v_user,
      'Housekeeping AD_PInstance 90d', v_proc_hkpara, v_schedule, 'D', 1, 'F', 7,
      'N', v_user, 'b7e2a012-90d1-4a01-9c02-000000000001'
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM ad_scheduler_para WHERE ad_scheduler_id = v_sch_id AND ad_process_para_id = v_para_hk
  ) THEN
    INSERT INTO ad_scheduler_para (
      ad_scheduler_id, ad_process_para_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby, parameterdefault, description, ad_scheduler_para_uu
    ) VALUES (
      v_sch_id, v_para_hk, v_client, v_org, 'Y',
      now(), v_user, now(), v_user, v_hk_id::text, 'AD_HouseKeeping_ID=AD_PInstance_90d',
      'b7e2a012-90d1-4a01-9c03-000000000001'
    );
  ELSE
    UPDATE ad_scheduler_para SET parameterdefault = v_hk_id::text, updated = now(), updatedby = v_user
    WHERE ad_scheduler_id = v_sch_id AND ad_process_para_id = v_para_hk;
  END IF;

  -- AD_ChangeLog 90d
  IF EXISTS (SELECT 1 FROM ad_housekeeping WHERE value = 'AD_ChangeLog_90d') THEN
    UPDATE ad_housekeeping SET
      name = 'Delete AD_ChangeLog older than 90 days',
      ad_table_id = v_tbl_changelog, tablename = 'AD_ChangeLog',
      whereclause = 'Created <= SYSDATE - 90', isactive = 'Y',
      help = 'SAW012: 90-day Change Audit retention.',
      updated = now(), updatedby = v_user
    WHERE value = 'AD_ChangeLog_90d'
    RETURNING ad_housekeeping_id INTO v_hk_id;
  ELSE
    v_hk_id := nextid(v_hk_seq, 'N'::varchar);
    INSERT INTO ad_housekeeping (
      ad_housekeeping_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, value, ad_table_id, tablename, whereclause, help,
      isexportxmlbackup, issaveinhistoric, processing, lastdeleted, ad_housekeeping_uu
    ) VALUES (
      v_hk_id, v_client, v_org, 'Y', now(), v_user, now(), v_user,
      'Delete AD_ChangeLog older than 90 days', 'AD_ChangeLog_90d', v_tbl_changelog, 'AD_ChangeLog',
      'Created <= SYSDATE - 90', 'SAW012: 90-day Change Audit retention.',
      'N', 'N', 'N', 0, 'b7e2a012-90d1-4a01-9c01-000000000002'
    );
  END IF;

  IF EXISTS (SELECT 1 FROM ad_scheduler WHERE ad_scheduler_uu = 'b7e2a012-90d1-4a01-9c02-000000000002') THEN
    UPDATE ad_scheduler SET name = 'Housekeeping AD_ChangeLog 90d', isactive = 'Y',
      ad_process_id = v_proc_hkpara, ad_schedule_id = v_schedule, frequencytype = 'D', frequency = 1, scheduletype = 'F',
      keeplogdays = 7, updated = now(), updatedby = v_user
    WHERE ad_scheduler_uu = 'b7e2a012-90d1-4a01-9c02-000000000002'
    RETURNING ad_scheduler_id INTO v_sch_id;
  ELSIF EXISTS (SELECT 1 FROM ad_scheduler WHERE name = 'Housekeeping AD_ChangeLog 90d') THEN
    SELECT ad_scheduler_id INTO v_sch_id FROM ad_scheduler WHERE name = 'Housekeeping AD_ChangeLog 90d';
    UPDATE ad_scheduler SET isactive = 'Y', ad_process_id = v_proc_hkpara, frequencytype = 'D', frequency = 1,
      scheduletype = 'F', keeplogdays = 7, updated = now(), updatedby = v_user
    WHERE ad_scheduler_id = v_sch_id;
  ELSE
    v_sch_id := nextid(v_sch_seq, 'N'::varchar);
    INSERT INTO ad_scheduler (
      ad_scheduler_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, ad_process_id, ad_schedule_id, frequencytype, frequency, scheduletype, keeplogdays,
      processing, supervisor_id, ad_scheduler_uu
    ) VALUES (
      v_sch_id, v_client, v_org, 'Y', now(), v_user, now(), v_user,
      'Housekeeping AD_ChangeLog 90d', v_proc_hkpara, v_schedule, 'D', 1, 'F', 7,
      'N', v_user, 'b7e2a012-90d1-4a01-9c02-000000000002'
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ad_scheduler_para WHERE ad_scheduler_id = v_sch_id AND ad_process_para_id = v_para_hk) THEN
    INSERT INTO ad_scheduler_para (
      ad_scheduler_id, ad_process_para_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby, parameterdefault, description, ad_scheduler_para_uu
    ) VALUES (
      v_sch_id, v_para_hk, v_client, v_org, 'Y', now(), v_user, now(), v_user,
      v_hk_id::text, 'AD_HouseKeeping_ID=AD_ChangeLog_90d', 'b7e2a012-90d1-4a01-9c03-000000000002'
    );
  ELSE
    UPDATE ad_scheduler_para SET parameterdefault = v_hk_id::text, updated = now(), updatedby = v_user
    WHERE ad_scheduler_id = v_sch_id AND ad_process_para_id = v_para_hk;
  END IF;

  -- AD_Issue 90d
  IF EXISTS (SELECT 1 FROM ad_housekeeping WHERE value = 'AD_Issue_90d') THEN
    UPDATE ad_housekeeping SET
      name = 'Delete AD_Issue older than 90 days',
      ad_table_id = v_tbl_issue, tablename = 'AD_Issue',
      whereclause = 'Created <= SYSDATE - 90', isactive = 'Y',
      help = 'SAW012: 90-day system issue retention.',
      updated = now(), updatedby = v_user
    WHERE value = 'AD_Issue_90d'
    RETURNING ad_housekeeping_id INTO v_hk_id;
  ELSE
    v_hk_id := nextid(v_hk_seq, 'N'::varchar);
    INSERT INTO ad_housekeeping (
      ad_housekeeping_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, value, ad_table_id, tablename, whereclause, help,
      isexportxmlbackup, issaveinhistoric, processing, lastdeleted, ad_housekeeping_uu
    ) VALUES (
      v_hk_id, v_client, v_org, 'Y', now(), v_user, now(), v_user,
      'Delete AD_Issue older than 90 days', 'AD_Issue_90d', v_tbl_issue, 'AD_Issue',
      'Created <= SYSDATE - 90', 'SAW012: 90-day system issue retention.',
      'N', 'N', 'N', 0, 'b7e2a012-90d1-4a01-9c01-000000000004'
    );
  END IF;

  IF EXISTS (SELECT 1 FROM ad_scheduler WHERE ad_scheduler_uu = 'b7e2a012-90d1-4a01-9c02-000000000004') THEN
    UPDATE ad_scheduler SET name = 'Housekeeping AD_Issue 90d', isactive = 'Y',
      ad_process_id = v_proc_hkpara, ad_schedule_id = v_schedule, frequencytype = 'D', frequency = 1, scheduletype = 'F',
      keeplogdays = 7, updated = now(), updatedby = v_user
    WHERE ad_scheduler_uu = 'b7e2a012-90d1-4a01-9c02-000000000004'
    RETURNING ad_scheduler_id INTO v_sch_id;
  ELSIF EXISTS (SELECT 1 FROM ad_scheduler WHERE name = 'Housekeeping AD_Issue 90d') THEN
    SELECT ad_scheduler_id INTO v_sch_id FROM ad_scheduler WHERE name = 'Housekeeping AD_Issue 90d';
    UPDATE ad_scheduler SET isactive = 'Y', updated = now(), updatedby = v_user WHERE ad_scheduler_id = v_sch_id;
  ELSE
    v_sch_id := nextid(v_sch_seq, 'N'::varchar);
    INSERT INTO ad_scheduler (
      ad_scheduler_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, ad_process_id, ad_schedule_id, frequencytype, frequency, scheduletype, keeplogdays,
      processing, supervisor_id, ad_scheduler_uu
    ) VALUES (
      v_sch_id, v_client, v_org, 'Y', now(), v_user, now(), v_user,
      'Housekeeping AD_Issue 90d', v_proc_hkpara, v_schedule, 'D', 1, 'F', 7,
      'N', v_user, 'b7e2a012-90d1-4a01-9c02-000000000004'
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ad_scheduler_para WHERE ad_scheduler_id = v_sch_id AND ad_process_para_id = v_para_hk) THEN
    INSERT INTO ad_scheduler_para (
      ad_scheduler_id, ad_process_para_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby, parameterdefault, description, ad_scheduler_para_uu
    ) VALUES (
      v_sch_id, v_para_hk, v_client, v_org, 'Y', now(), v_user, now(), v_user,
      v_hk_id::text, 'AD_HouseKeeping_ID=AD_Issue_90d', 'b7e2a012-90d1-4a01-9c03-000000000004'
    );
  ELSE
    UPDATE ad_scheduler_para SET parameterdefault = v_hk_id::text, updated = now(), updatedby = v_user
    WHERE ad_scheduler_id = v_sch_id AND ad_process_para_id = v_para_hk;
  END IF;

  -- AD_Session 90d (after children cleared by other jobs / purge)
  IF EXISTS (SELECT 1 FROM ad_housekeeping WHERE value = 'AD_Session_90d') THEN
    UPDATE ad_housekeeping SET
      name = 'Delete AD_Session older than 90 days (orphan-safe)',
      ad_table_id = v_tbl_session, tablename = 'AD_Session',
      whereclause = 'Created <= SYSDATE - 90 AND aberp_session_ok_to_purge(AD_Session_ID)=''Y''',
      isactive = 'Y',
      help = 'SAW012: uses aberp_session_ok_to_purge() — only orphan sessions.',
      updated = now(), updatedby = v_user
    WHERE value = 'AD_Session_90d'
    RETURNING ad_housekeeping_id INTO v_hk_id;
  ELSE
    v_hk_id := nextid(v_hk_seq, 'N'::varchar);
    INSERT INTO ad_housekeeping (
      ad_housekeeping_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, value, ad_table_id, tablename, whereclause, help,
      isexportxmlbackup, issaveinhistoric, processing, lastdeleted, ad_housekeeping_uu
    ) VALUES (
      v_hk_id, v_client, v_org, 'Y', now(), v_user, now(), v_user,
      'Delete AD_Session older than 90 days (orphan-safe)', 'AD_Session_90d', v_tbl_session, 'AD_Session',
      'Created <= SYSDATE - 90 AND aberp_session_ok_to_purge(AD_Session_ID)=''Y''',
      'SAW012: uses aberp_session_ok_to_purge() — only orphan sessions.',
      'N', 'N', 'N', 0, 'b7e2a012-90d1-4a01-9c01-000000000003'
    );
  END IF;

  IF EXISTS (SELECT 1 FROM ad_scheduler WHERE ad_scheduler_uu = 'b7e2a012-90d1-4a01-9c02-000000000003') THEN
    UPDATE ad_scheduler SET name = 'Housekeeping AD_Session 90d', isactive = 'Y',
      ad_process_id = v_proc_hkpara, ad_schedule_id = v_schedule, frequencytype = 'D', frequency = 1, scheduletype = 'F',
      keeplogdays = 7, updated = now(), updatedby = v_user
    WHERE ad_scheduler_uu = 'b7e2a012-90d1-4a01-9c02-000000000003'
    RETURNING ad_scheduler_id INTO v_sch_id;
  ELSIF EXISTS (SELECT 1 FROM ad_scheduler WHERE name = 'Housekeeping AD_Session 90d') THEN
    SELECT ad_scheduler_id INTO v_sch_id FROM ad_scheduler WHERE name = 'Housekeeping AD_Session 90d';
    UPDATE ad_scheduler SET isactive = 'Y', updated = now(), updatedby = v_user WHERE ad_scheduler_id = v_sch_id;
  ELSE
    v_sch_id := nextid(v_sch_seq, 'N'::varchar);
    INSERT INTO ad_scheduler (
      ad_scheduler_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      name, ad_process_id, ad_schedule_id, frequencytype, frequency, scheduletype, keeplogdays,
      processing, supervisor_id, ad_scheduler_uu
    ) VALUES (
      v_sch_id, v_client, v_org, 'Y', now(), v_user, now(), v_user,
      'Housekeeping AD_Session 90d', v_proc_hkpara, v_schedule, 'D', 1, 'F', 7,
      'N', v_user, 'b7e2a012-90d1-4a01-9c02-000000000003'
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ad_scheduler_para WHERE ad_scheduler_id = v_sch_id AND ad_process_para_id = v_para_hk) THEN
    INSERT INTO ad_scheduler_para (
      ad_scheduler_id, ad_process_para_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby, parameterdefault, description, ad_scheduler_para_uu
    ) VALUES (
      v_sch_id, v_para_hk, v_client, v_org, 'Y', now(), v_user, now(), v_user,
      v_hk_id::text, 'AD_HouseKeeping_ID=AD_Session_90d', 'b7e2a012-90d1-4a01-9c03-000000000003'
    );
  ELSE
    UPDATE ad_scheduler_para SET parameterdefault = v_hk_id::text, updated = now(), updatedby = v_user
    WHERE ad_scheduler_id = v_sch_id AND ad_process_para_id = v_para_hk;
  END IF;

  RAISE NOTICE 'SAW012 HouseKeeping + schedulers upserted (90-day retention)';
END $$;

SELECT value, name, left(whereclause, 80) AS where_preview, isactive
FROM ad_housekeeping
WHERE value LIKE '%_90d'
ORDER BY value;

SELECT s.name, s.isactive, s.frequencytype, s.frequency, sp.parameterdefault
FROM ad_scheduler s
LEFT JOIN ad_scheduler_para sp ON sp.ad_scheduler_id = s.ad_scheduler_id
WHERE s.name LIKE 'Housekeeping AD_%90d'
ORDER BY s.name;
