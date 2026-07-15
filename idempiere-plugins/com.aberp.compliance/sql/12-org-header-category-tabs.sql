-- =============================================================================
-- SAW023 — Organisation Audit = only TabLevel 0; category tabs = children (TabLevel 1)
-- Fixes skeleton so org audit is the default page; Employee is a tab under it.
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_window_id INTEGER;
  v_dash_table INTEGER;
  v_link_col INTEGER;
  v_org_tab INTEGER;
  r RECORD;
BEGIN
  SELECT ad_window_id INTO v_window_id
  FROM ad_window
  WHERE ad_window_uu = '23a02305-c0d4-4f01-8e15-000000000001'
     OR name = 'Compliance Summary'
  LIMIT 1;
  IF v_window_id IS NULL THEN
    RAISE EXCEPTION 'SAW023: Compliance Summary window missing';
  END IF;

  SELECT ad_table_id INTO v_dash_table
  FROM ad_table WHERE tablename = 'AbERP_ComplianceDashboard';
  IF v_dash_table IS NULL THEN
    RAISE EXCEPTION 'SAW023: dashboard table missing';
  END IF;

  SELECT ad_column_id INTO v_link_col
  FROM ad_column
  WHERE ad_table_id = v_dash_table
    AND columnname = 'AbERP_ComplianceDashboard_ID';
  IF v_link_col IS NULL THEN
    RAISE EXCEPTION 'SAW023: dashboard PK column missing';
  END IF;

  -- Header: Organisation Audit
  SELECT ad_tab_id INTO v_org_tab
  FROM ad_tab
  WHERE ad_tab_uu = '23a02310-c0d4-4f01-8e15-000000000001'
     OR (ad_window_id = v_window_id AND seqno = 10)
  LIMIT 1;

  UPDATE ad_tab SET
    name = 'Organisation Audit',
    description = 'Organisation-wide NDIS audit readiness KPIs',
    seqno = 10,
    tablevel = 0,
    issinglerow = 'Y',
    isreadonly = 'Y',
    isinsertrecord = 'N',
    ad_column_id = NULL,
    isactive = 'Y',
    updated = NOW(),
    updatedby = 100
  WHERE ad_tab_id = v_org_tab;

  -- Category tabs = TabLevel 1 children linked on dashboard PK (same row, different fields)
  FOR r IN
    SELECT * FROM (VALUES
      ('23a02311-c0d4-4f01-8e15-000000000001', 'Employee', 20, 'Employee (workforce) compliance KPIs'),
      ('23a02312-c0d4-4f01-8e15-000000000001', 'Client', 30, 'Client (participant) compliance KPIs'),
      ('23a02313-c0d4-4f01-8e15-000000000001', 'Incidents', 40, 'Incidents compliance KPIs'),
      ('23a02314-c0d4-4f01-8e15-000000000001', 'Rostering', 50, 'Rostering compliance KPIs'),
      ('23a02315-c0d4-4f01-8e15-000000000001', 'Documentation', 60, 'Documentation compliance KPIs')
    ) AS t(uu, name, seq, descr)
  LOOP
    UPDATE ad_tab SET
      name = r.name,
      description = r.descr,
      seqno = r.seq,
      tablevel = 1,
      ad_column_id = v_link_col,
      issinglerow = 'Y',
      isreadonly = 'Y',
      isinsertrecord = 'N',
      isactive = 'Y',
      updated = NOW(),
      updatedby = 100
    WHERE ad_tab_uu = r.uu
       OR (ad_window_id = v_window_id AND name = r.name);
  END LOOP;

  UPDATE ad_window SET
    description = 'Organisation NDIS Audit Readiness (header) plus category tabs Employee / Client / Incidents / Rostering / Documentation',
    help = 'Default tab Organisation Audit = organisation-wide score and totals. Child tabs are function areas. Values come from the latest snapshot.',
    updated = NOW()
  WHERE ad_window_id = v_window_id;

  RAISE NOTICE 'SAW023 Organisation Audit header + category child tabs ready';
END $$;

SELECT t.seqno, t.name, t.tablevel,
       (SELECT columnname FROM ad_column c WHERE c.ad_column_id = t.ad_column_id) AS link_col
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.ad_window_uu = '23a02305-c0d4-4f01-8e15-000000000001'
ORDER BY t.seqno;
