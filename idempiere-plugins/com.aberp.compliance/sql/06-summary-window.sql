-- =============================================================================
-- SAW023 — Compliance Summary window + functional tabs
-- Window UU: 23a02305-c0d4-4f01-8e15-000000000001
-- Tabs: Summary 10 / Employee 20 / Client 30 / Incidents 40 / Rostering 50 / Documentation 60
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_window_id),0)+1 FROM ad_window))
WHERE name='AD_Window' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_tab_id),0)+1 FROM ad_tab))
WHERE name='AD_Tab' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw023_field(
  p_tab_id INTEGER, p_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_seqno INTEGER, p_displayed CHAR, p_readonly CHAR DEFAULT 'Y',
  p_sameline CHAR DEFAULT 'N', p_gridseq INTEGER DEFAULT NULL,
  p_displayedgrid CHAR DEFAULT NULL
) RETURNS void AS $$
DECLARE
  v_col_id INTEGER;
  v_field_id INTEGER;
  v_table_id INTEGER;
BEGIN
  SELECT ad_table_id INTO v_table_id FROM ad_tab WHERE ad_tab_id = p_tab_id;
  SELECT ad_column_id INTO v_col_id FROM ad_column
  WHERE ad_table_id = v_table_id AND columnname = p_columnname;
  IF v_col_id IS NULL THEN
    RAISE NOTICE 'SAW023 skip field % — column missing', p_columnname;
    RETURN;
  END IF;

  SELECT ad_field_id INTO v_field_id FROM ad_field WHERE ad_field_uu = p_uu;
  IF v_field_id IS NULL THEN
    SELECT ad_field_id INTO v_field_id FROM ad_field
    WHERE ad_tab_id = p_tab_id AND ad_column_id = v_col_id;
  END IF;

  IF v_field_id IS NULL THEN
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, iscentrallymaintained, ad_tab_id, ad_column_id,
      isdisplayed, displaylength, isreadonly, seqno, issameline,
      isheading, isfieldonly, isencrypted, entitytype,
      isdisplayedgrid, seqnogrid, xposition, columnspan, numlines, ad_field_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, 'N', p_tab_id, v_col_id,
      p_displayed, 0, p_readonly, p_seqno, p_sameline,
      'N', 'N', 'N', 'Ab_ERP',
      COALESCE(p_displayedgrid, p_displayed), COALESCE(p_gridseq, p_seqno), 1, 2, 1, p_uu
    );
  ELSE
    UPDATE ad_field SET
      name = p_name,
      isdisplayed = p_displayed,
      isreadonly = p_readonly,
      seqno = p_seqno,
      issameline = p_sameline,
      isdisplayedgrid = COALESCE(p_displayedgrid, p_displayed),
      seqnogrid = COALESCE(p_gridseq, p_seqno),
      ad_field_uu = COALESCE(ad_field_uu, p_uu),
      updated = NOW()
    WHERE ad_field_id = v_field_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw023_tab(
  p_uu TEXT, p_window_id INTEGER, p_table_id INTEGER,
  p_name TEXT, p_seq INTEGER,
  p_tablevel INTEGER DEFAULT 0,
  p_link_col INTEGER DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
  v_tab_id INTEGER;
BEGIN
  SELECT ad_tab_id INTO v_tab_id FROM ad_tab WHERE ad_tab_uu = p_uu;
  IF v_tab_id IS NULL THEN
    SELECT ad_tab_id INTO v_tab_id FROM ad_tab
    WHERE ad_window_id = p_window_id AND name = p_name AND seqno = p_seq;
  END IF;

  IF v_tab_id IS NULL THEN
    INSERT INTO ad_tab (
      ad_tab_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_table_id, ad_window_id, seqno,
      tablevel, issinglerow, isinfotab, istranslationtab, isreadonly,
      hastree, processing, issorttab, entitytype, isinsertrecord, isadvancedtab,
      ad_column_id, ad_tab_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Tab' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, p_name || ' compliance KPIs',
      p_table_id, p_window_id, p_seq,
      p_tablevel, 'Y', 'N', 'N', 'Y',
      'N', 'N', 'N', 'Ab_ERP', 'N', 'N',
      p_link_col, p_uu
    ) RETURNING ad_tab_id INTO v_tab_id;
  ELSE
    UPDATE ad_tab SET
      name = p_name,
      ad_table_id = p_table_id,
      seqno = p_seq,
      tablevel = p_tablevel,
      ad_column_id = p_link_col,
      isreadonly = 'Y',
      isinsertrecord = 'N',
      issinglerow = 'Y',
      entitytype = 'Ab_ERP',
      ad_tab_uu = COALESCE(ad_tab_uu, p_uu),
      updated = NOW()
    WHERE ad_tab_id = v_tab_id;
  END IF;
  RETURN v_tab_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw023_category_fields(
  p_tab_id INTEGER, p_prefix TEXT, p_uu_base TEXT
) RETURNS void AS $$
BEGIN
  -- Hidden keys
  PERFORM pg_temp.saw023_field(p_tab_id, p_uu_base||'-0001-4f01-8e15-000000000001','AbERP_ComplianceDashboard_ID','Compliance Dashboard',0,'N','Y','N',0,'N');
  PERFORM pg_temp.saw023_field(p_tab_id, p_uu_base||'-0002-4f01-8e15-000000000001','AD_Client_ID','Client',5,'N','Y','N',0,'N');

  -- Overall
  PERFORM pg_temp.saw023_field(p_tab_id, p_uu_base||'-0010-4f01-8e15-000000000001', p_prefix||'Total', 'Total Items',10,'Y','Y','N',10,'Y');
  PERFORM pg_temp.saw023_field(p_tab_id, p_uu_base||'-0011-4f01-8e15-000000000001', p_prefix||'Compliant', 'Compliant',20,'Y','Y','Y',20,'Y');
  PERFORM pg_temp.saw023_field(p_tab_id, p_uu_base||'-0012-4f01-8e15-000000000001', p_prefix||'Warning', 'Warning',30,'Y','Y','N',30,'Y');
  PERFORM pg_temp.saw023_field(p_tab_id, p_uu_base||'-0013-4f01-8e15-000000000001', p_prefix||'NonCompliant', 'Non-Compliant',40,'Y','Y','Y',40,'Y');
  PERFORM pg_temp.saw023_field(p_tab_id, p_uu_base||'-0014-4f01-8e15-000000000001', p_prefix||'Critical', 'Critical',50,'Y','Y','N',50,'Y');

  -- Overdue / At Risk / On Track / Change
  PERFORM pg_temp.saw023_field(p_tab_id, p_uu_base||'-0020-4f01-8e15-000000000001', p_prefix||'Overdue', 'Overdue / Expired',60,'Y','Y','N',60,'Y');
  PERFORM pg_temp.saw023_field(p_tab_id, p_uu_base||'-0021-4f01-8e15-000000000001', p_prefix||'AtRisk', 'At Risk (30 days)',70,'Y','Y','Y',70,'Y');
  PERFORM pg_temp.saw023_field(p_tab_id, p_uu_base||'-0022-4f01-8e15-000000000001', p_prefix||'OnTrack', 'On Track',80,'Y','Y','N',80,'Y');
  PERFORM pg_temp.saw023_field(p_tab_id, p_uu_base||'-0023-4f01-8e15-000000000001', p_prefix||'Change', 'Change (90d)',90,'Y','Y','Y',90,'Y');
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_window_uu CONSTANT TEXT := '23a02305-c0d4-4f01-8e15-000000000001';
  v_window_id INTEGER;
  v_dash_id INTEGER;
  v_link_col INTEGER;
  v_tab_sum INTEGER;
  v_tab_emp INTEGER;
  v_tab_cli INTEGER;
  v_tab_inc INTEGER;
  v_tab_ros INTEGER;
  v_tab_doc INTEGER;
BEGIN
  SELECT ad_table_id INTO v_dash_id FROM ad_table WHERE tablename = 'AbERP_ComplianceDashboard';
  IF v_dash_id IS NULL THEN
    RAISE EXCEPTION 'SAW023: dashboard table missing — run 04 first';
  END IF;

  SELECT ad_window_id INTO v_window_id FROM ad_window WHERE ad_window_uu = v_window_uu;
  IF v_window_id IS NULL THEN
    SELECT ad_window_id INTO v_window_id FROM ad_window
    WHERE name = 'Compliance Summary' AND entitytype = 'Ab_ERP';
  END IF;

  IF v_window_id IS NULL THEN
    INSERT INTO ad_window (
      ad_window_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, windowtype, issotrx,
      entitytype, processing, isdefault, isbetafunctionality, ad_window_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Window' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Compliance Summary',
      'Organisation NDIS Audit Readiness — overall KPIs plus category tabs (Employee, Client, Incidents, Rostering, Documentation)',
      'Organisation Audit (default tab) shows overall readiness score and totals. Switch tabs via the tab name dropdown (▼) for each function area. Values are from the latest snapshot, not live queries.',
      'M', 'N',
      'Ab_ERP', 'N', 'N', 'N', v_window_uu
    ) RETURNING ad_window_id INTO v_window_id;
  ELSE
    UPDATE ad_window SET
      name = 'Compliance Summary',
      description = 'Organisation NDIS Audit Readiness — overall KPIs plus category tabs (Employee, Client, Incidents, Rostering, Documentation)',
      help = 'Organisation Audit (default tab) shows overall readiness score and totals. Switch tabs via the tab name dropdown (▼) for each function area. Values are from the latest snapshot, not live queries.',
      entitytype = 'Ab_ERP',
      ad_window_uu = COALESCE(ad_window_uu, v_window_uu),
      isactive = 'Y',
      updated = NOW()
    WHERE ad_window_id = v_window_id;
  END IF;

  UPDATE ad_table SET ad_window_id = v_window_id, updated = NOW()
  WHERE ad_table_id = v_dash_id;

  v_tab_sum := pg_temp.saw023_tab('23a02310-c0d4-4f01-8e15-000000000001', v_window_id, v_dash_id, 'Organisation Audit', 10, 0, NULL);

  SELECT ad_column_id INTO v_link_col
  FROM ad_column
  WHERE ad_table_id = v_dash_id AND columnname = 'AbERP_ComplianceDashboard_ID';

  v_tab_emp := pg_temp.saw023_tab('23a02311-c0d4-4f01-8e15-000000000001', v_window_id, v_dash_id, 'Employee', 20, 1, v_link_col);
  v_tab_cli := pg_temp.saw023_tab('23a02312-c0d4-4f01-8e15-000000000001', v_window_id, v_dash_id, 'Client', 30, 1, v_link_col);
  v_tab_inc := pg_temp.saw023_tab('23a02313-c0d4-4f01-8e15-000000000001', v_window_id, v_dash_id, 'Incidents', 40, 1, v_link_col);
  v_tab_ros := pg_temp.saw023_tab('23a02314-c0d4-4f01-8e15-000000000001', v_window_id, v_dash_id, 'Rostering', 50, 1, v_link_col);
  v_tab_doc := pg_temp.saw023_tab('23a02315-c0d4-4f01-8e15-000000000001', v_window_id, v_dash_id, 'Documentation', 60, 1, v_link_col);

  -- Summary tab fields
  PERFORM pg_temp.saw023_field(v_tab_sum,'23a02310-f001-4f01-8e15-000000000001','AbERP_ComplianceDashboard_ID','Compliance Dashboard',0,'N','Y','N',0,'N');
  PERFORM pg_temp.saw023_field(v_tab_sum,'23a02310-f002-4f01-8e15-000000000001','AD_Client_ID','Client',5,'N','Y','N',0,'N');
  PERFORM pg_temp.saw023_field(v_tab_sum,'23a02310-f010-4f01-8e15-000000000001','OverallScore','Audit Readiness Score',10,'Y','Y','N',10,'Y');
  PERFORM pg_temp.saw023_field(v_tab_sum,'23a02310-f011-4f01-8e15-000000000001','OverallTrafficLight','Traffic Light',20,'Y','Y','Y',20,'Y');
  PERFORM pg_temp.saw023_field(v_tab_sum,'23a02310-f012-4f01-8e15-000000000001','TotalItems','Total Items',30,'Y','Y','N',30,'Y');
  PERFORM pg_temp.saw023_field(v_tab_sum,'23a02310-f013-4f01-8e15-000000000001','TotalCompliant','Compliant',40,'Y','Y','Y',40,'Y');
  PERFORM pg_temp.saw023_field(v_tab_sum,'23a02310-f014-4f01-8e15-000000000001','TotalWarning','Warning',50,'Y','Y','N',50,'Y');
  PERFORM pg_temp.saw023_field(v_tab_sum,'23a02310-f015-4f01-8e15-000000000001','TotalNonCompliant','Non-Compliant',60,'Y','Y','Y',60,'Y');
  PERFORM pg_temp.saw023_field(v_tab_sum,'23a02310-f016-4f01-8e15-000000000001','TotalCritical','Critical',70,'Y','Y','N',70,'Y');
  PERFORM pg_temp.saw023_field(v_tab_sum,'23a02310-f017-4f01-8e15-000000000001','LastRefreshed','Last Refreshed',80,'Y','Y','Y',80,'Y');

  -- Category tabs (identical layout)
  PERFORM pg_temp.saw023_category_fields(v_tab_emp, 'Employee', '23a02311');
  PERFORM pg_temp.saw023_category_fields(v_tab_cli, 'Client', '23a02312');
  PERFORM pg_temp.saw023_category_fields(v_tab_inc, 'Incident', '23a02313');
  PERFORM pg_temp.saw023_category_fields(v_tab_ros, 'Roster', '23a02314');
  PERFORM pg_temp.saw023_category_fields(v_tab_doc, 'Doc', '23a02315');

  -- Fine-tune same-line pairs to column 4
  UPDATE ad_field f SET
    xposition = CASE WHEN f.issameline = 'Y' THEN 4 ELSE 1 END,
    columnspan = 2,
    updated = NOW()
  WHERE f.ad_tab_id IN (v_tab_sum, v_tab_emp, v_tab_cli, v_tab_inc, v_tab_ros, v_tab_doc)
    AND f.isdisplayed = 'Y';

  RAISE NOTICE 'SAW023 Summary window=% tabs sum/emp/cli/inc/ros/doc=%/%/%/%/%/%',
    v_window_id, v_tab_sum, v_tab_emp, v_tab_cli, v_tab_inc, v_tab_ros, v_tab_doc;
END $$;
