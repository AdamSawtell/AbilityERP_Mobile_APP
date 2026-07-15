-- =============================================================================
-- SAW023 — clarify org Audit Summary as default tab (not Employee)
-- Tab UU remains 23a02310-… ; rename display to Organisation Audit
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_window_id INTEGER;
  v_tab_id INTEGER;
BEGIN
  SELECT ad_window_id INTO v_window_id
  FROM ad_window
  WHERE ad_window_uu = '23a02305-c0d4-4f01-8e15-000000000001'
     OR name = 'Compliance Summary'
  LIMIT 1;
  IF v_window_id IS NULL THEN
    RAISE EXCEPTION 'SAW023: Compliance Summary window missing';
  END IF;

  UPDATE ad_window SET
    name = 'Compliance Summary',
    description = 'Organisation NDIS Audit Readiness — overall KPIs plus category tabs (Employee, Client, Incidents, Rostering, Documentation)',
    help = 'Organisation Audit (default tab) shows overall readiness score and totals. Switch tabs via the tab name dropdown (▼) for each function area. Values are from the latest snapshot, not live queries.',
    updated = NOW(),
    updatedby = 100
  WHERE ad_window_id = v_window_id;

  SELECT ad_tab_id INTO v_tab_id
  FROM ad_tab
  WHERE ad_tab_uu = '23a02310-c0d4-4f01-8e15-000000000001'
     OR (ad_window_id = v_window_id AND seqno = 10)
  LIMIT 1;

  IF v_tab_id IS NULL THEN
    RAISE EXCEPTION 'SAW023: Organisation Audit tab (seq 10) missing';
  END IF;

  UPDATE ad_tab SET
    name = 'Organisation Audit',
    description = 'Organisation-wide NDIS audit readiness KPIs',
    seqno = 10,
    tablevel = 0,
    isactive = 'Y',
    updated = NOW(),
    updatedby = 100
  WHERE ad_tab_id = v_tab_id;

  -- Keep category tabs clearly secondary and ordered after org
  UPDATE ad_tab SET seqno = 20, name = 'Employee', description = 'Employee (workforce) compliance KPIs', updated = NOW()
  WHERE ad_window_id = v_window_id AND ad_tab_uu = '23a02311-c0d4-4f01-8e15-000000000001';
  UPDATE ad_tab SET seqno = 30, name = 'Client', description = 'Client (participant) compliance KPIs', updated = NOW()
  WHERE ad_window_id = v_window_id AND ad_tab_uu = '23a02312-c0d4-4f01-8e15-000000000001';
  UPDATE ad_tab SET seqno = 40, name = 'Incidents', description = 'Incidents compliance KPIs', updated = NOW()
  WHERE ad_window_id = v_window_id AND ad_tab_uu = '23a02313-c0d4-4f01-8e15-000000000001';
  UPDATE ad_tab SET seqno = 50, name = 'Rostering', description = 'Rostering compliance KPIs', updated = NOW()
  WHERE ad_window_id = v_window_id AND ad_tab_uu = '23a02314-c0d4-4f01-8e15-000000000001';
  UPDATE ad_tab SET seqno = 60, name = 'Documentation', description = 'Documentation compliance KPIs', updated = NOW()
  WHERE ad_window_id = v_window_id AND ad_tab_uu = '23a02315-c0d4-4f01-8e15-000000000001';

  -- English trl for window + org tab
  INSERT INTO ad_window_trl (
    ad_window_id, ad_language, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, name, description, help, istranslated
  )
  SELECT v_window_id, 'en_US', 0, 0, 'Y', NOW(), 100, NOW(), 100,
         'Compliance Summary',
         'Organisation NDIS Audit Readiness — overall KPIs plus category tabs',
         'Organisation Audit is the default tab. Use ▼ to open Employee, Client, Incidents, Rostering, Documentation.',
         'Y'
  WHERE NOT EXISTS (
    SELECT 1 FROM ad_window_trl WHERE ad_window_id = v_window_id AND ad_language = 'en_US'
  );

  UPDATE ad_window_trl SET
    name = 'Compliance Summary',
    description = 'Organisation NDIS Audit Readiness — overall KPIs plus category tabs',
    help = 'Organisation Audit is the default tab. Use ▼ to open Employee, Client, Incidents, Rostering, Documentation.',
    istranslated = 'Y',
    updated = NOW()
  WHERE ad_window_id = v_window_id AND ad_language = 'en_US';

  IF NOT EXISTS (SELECT 1 FROM ad_tab_trl WHERE ad_tab_id = v_tab_id AND ad_language = 'en_US') THEN
    INSERT INTO ad_tab_trl (
      ad_tab_id, ad_language, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby, name, description, help, commitwarning, istranslated
    ) VALUES (
      v_tab_id, 'en_US', 0, 0, 'Y',
      NOW(), 100, NOW(), 100,
      'Organisation Audit', 'Organisation-wide NDIS audit readiness KPIs', NULL, NULL, 'Y'
    );
  ELSE
    UPDATE ad_tab_trl SET
      name = 'Organisation Audit',
      description = 'Organisation-wide NDIS audit readiness KPIs',
      istranslated = 'Y',
      updated = NOW()
    WHERE ad_tab_id = v_tab_id AND ad_language = 'en_US';
  END IF;

  RAISE NOTICE 'SAW023 org tab renamed Organisation Audit on window %', v_window_id;
END $$;

SELECT t.seqno, t.name FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.ad_window_uu = '23a02305-c0d4-4f01-8e15-000000000001'
ORDER BY t.seqno;
