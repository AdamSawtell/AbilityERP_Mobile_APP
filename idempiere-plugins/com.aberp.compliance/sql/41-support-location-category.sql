-- SAW025-41 — Support Location category (sixth reporting area)
-- Adds category L, Organisation Audit tab + Findings nest, population/action KPIs,
-- progressive explainers, and parent-only Findings DisplayLogic.
-- Requires SAW024 Findings pattern (33/40) and SAW025 KPI helpers (37/39).
SET search_path TO adempiere;

-- ---------------------------------------------------------------------------
-- 1. Category list value L = Support Location
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_ref INTEGER;
  v_list INTEGER;
  v_uu CONSTANT TEXT := '23a02320-0007-4f01-8e15-000000000001';
BEGIN
  SELECT ad_reference_id INTO v_ref
  FROM ad_reference
  WHERE ad_reference_uu = '23a02320-c0d4-4f01-8e15-000000000001'
     OR name = 'AbERP_ComplianceCategory'
  LIMIT 1;
  IF v_ref IS NULL THEN
    RAISE EXCEPTION 'SAW025-41: AbERP_ComplianceCategory reference missing';
  END IF;

  SELECT ad_ref_list_id INTO v_list
  FROM ad_ref_list WHERE ad_reference_id = v_ref AND value = 'L';
  IF v_list IS NULL THEN
    INSERT INTO ad_ref_list (
      ad_ref_list_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      value, name, description, ad_reference_id, entitytype, ad_ref_list_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Ref_List' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'L', 'Support Location', 'Support Location', v_ref, 'Ab_ERP', v_uu
    );
  ELSE
    UPDATE ad_ref_list SET
      name = 'Support Location',
      description = 'Support Location',
      isactive = 'Y',
      entitytype = 'Ab_ERP',
      ad_ref_list_uu = COALESCE(NULLIF(ad_ref_list_uu, ''), v_uu),
      updated = NOW()
    WHERE ad_ref_list_id = v_list;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. KPI / population helpers (ColumnSQL — avoids recreating dashboard view)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION aberp_compliance_location_kpi(
  p_client_id NUMERIC, p_metric TEXT
) RETURNS NUMERIC AS $$
  SELECT CASE lower(p_metric)
    WHEN 'population' THEN (
      SELECT COUNT(*)::numeric FROM aberp_support_location sl
      WHERE sl.ad_client_id = p_client_id AND sl.isactive = 'Y')
    WHEN 'change90d' THEN (
      SELECT COALESCE((
        SELECT COUNT(*)::numeric FROM aberp_support_location sl
        WHERE sl.ad_client_id = p_client_id AND sl.isactive = 'Y'
      ), 0) - COALESCE((
        SELECT s.populationcount FROM aberp_compliancesnapshot s
        WHERE s.ad_client_id = p_client_id AND s.isactive = 'Y'
          AND s.compliancecategory = 'L'
          AND s.aberp_support_location_id IS NULL
          AND s.populationcount IS NOT NULL
          AND s.snapshotdate::date <= (CURRENT_DATE - 90)
        ORDER BY s.snapshotdate DESC LIMIT 1
      ), (
        SELECT COUNT(*)::numeric FROM aberp_support_location sl
        WHERE sl.ad_client_id = p_client_id AND sl.isactive = 'Y'
          AND sl.created::date <= (CURRENT_DATE - 90)
      ), 0)
    )
    WHEN 'vacant' THEN (
      SELECT COUNT(*)::numeric FROM aberp_support_location sl
      WHERE sl.ad_client_id = p_client_id AND sl.isactive = 'Y'
        AND COALESCE(sl.hco_locationvacancy, 'N') = 'Y')
    WHEN 'sda' THEN (
      SELECT COUNT(*)::numeric FROM aberp_support_location sl
      WHERE sl.ad_client_id = p_client_id AND sl.isactive = 'Y'
        AND COALESCE(sl.aberp_issdaenrolled, 'N') = 'Y')
    WHEN 'wheelchair' THEN (
      SELECT COUNT(*)::numeric FROM aberp_support_location sl
      WHERE sl.ad_client_id = p_client_id AND sl.isactive = 'Y'
        AND COALESCE(sl.aberp_iswheelchairaccessible, 'N') = 'Y')
    WHEN 'bushfire' THEN (
      SELECT COUNT(*)::numeric FROM aberp_support_location sl
      WHERE sl.ad_client_id = p_client_id AND sl.isactive = 'Y'
        AND COALESCE(sl.aberp_isbushfiredangerarea, 'N') = 'Y')
    WHEN 'meets_expects' THEN (
      SELECT COUNT(*)::numeric FROM aberp_support_location sl
      WHERE sl.ad_client_id = p_client_id AND sl.isactive = 'Y'
        AND COALESCE(sl.hco_meetsexpects, 'N') = 'Y')
    ELSE 0::numeric
  END
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION aberp_compliance_location_bucket(
  p_client_id NUMERIC, p_metric TEXT
) RETURNS NUMERIC AS $$
  SELECT COALESCE((
    SELECT CASE lower(p_metric)
      WHEN 'total' THEN s.totalitems
      WHEN 'compliant' THEN s.compliant
      WHEN 'warning' THEN s.warning
      WHEN 'noncompliant' THEN s.noncompliant
      WHEN 'critical' THEN s.critical
      WHEN 'overdue' THEN s.overdue
      WHEN 'atrisk' THEN s.atrisk
      WHEN 'ontrack' THEN s.ontrack
      ELSE 0
    END
    FROM aberp_compliancesnapshot s
    WHERE s.ad_client_id = p_client_id AND s.isactive = 'Y'
      AND s.compliancecategory = 'L'
      AND s.aberp_support_location_id IS NULL
    ORDER BY s.snapshotdate DESC
    LIMIT 1
  ), 0)::numeric
$$ LANGUAGE sql STABLE;

-- Extend explainers (replace full CASE from 39 + location keys)
CREATE OR REPLACE FUNCTION aberp_compliance_explainer(p_key TEXT)
RETURNS TEXT AS $$
  SELECT CASE p_key
    WHEN 'lead_readiness' THEN
      'Audit Readiness Score is the average latest score across the six categories. Traffic Light is the overall red, amber or green result.'
    WHEN 'lead_items' THEN
      'Total Items is the sum of the latest category checks. Compliant is the number currently passing.'
    WHEN 'lead_exceptions' THEN
      'Warning needs attention. Non-Compliant is failing. Critical is the highest-priority subset requiring immediate action.'
    WHEN 'lead_refresh' THEN
      'Last Refreshed shows when compliance was last calculated. Refresh Compliance re-evaluates all rules and updates these figures.'
    WHEN 'employee_population' THEN
      'Active Employees counts active employee contacts. Change (90d) is the current count less the 90-day baseline.'
    WHEN 'client_population' THEN
      'Active Clients counts active Support Receivers. Change (90d) is the current count less the 90-day baseline.'
    WHEN 'incident_population' THEN
      'Active Incidents counts active incidents not in a closed status. Change (90d) is the current count less the 90-day baseline.'
    WHEN 'roster_population' THEN
      'Current Roster counts shifts in the active pay period. Next Roster counts shifts in the immediately following pay period.'
    WHEN 'doc_population' THEN
      'Total Documents counts active credential/document assignments. Change (90d) is the current count less the 90-day baseline.'
    WHEN 'location_population' THEN
      'Active Support Locations counts active Support Location records. Change (90d) is the current count less the 90-day baseline.'
    WHEN 'readiness' THEN
      'Readiness Score is the latest category compliance score. Status is its latest red, amber or green result.'
    WHEN 'findings' THEN
      'Open Findings are unresolved issues. Critical Open is the critical subset. Top Finding is the most frequent open rule.'
    WHEN 'employee_actions' THEN
      'Screening: expired or due within 30 days.' || chr(10) ||
      'Credentials Current %: active assignments not expired.' || chr(10) ||
      'New Starters Missing Docs: employees created in 90 days without onboarding evidence.' || chr(10) ||
      'Unavailable / Rostered: approved unavailable staff today and staff allocated in the current period.'
    WHEN 'client_actions' THEN
      'Risk Reviews: active risks overdue or due in 30 days.' || chr(10) ||
      'No Support (30d): active Support Receivers with no rostered support in the past 30 days.' || chr(10) ||
      'Plan Reviews / Expired / Current: active plans and assessments evaluated from their review and validity dates.'
    WHEN 'incident_actions' THEN
      'Closed (30d): incidents moved to a closed status in 30 days.' || chr(10) ||
      'Investigations Overdue: open incidents past Due Date. Outstanding Actions: active incomplete actions.' || chr(10) ||
      'Reportable Open: open reportable incidents. Median / Oldest: age from the incident record creation date.'
    WHEN 'roster_actions' THEN
      'Fill Rate: shifts meeting required staff. Filled / Unfilled: staffed versus no allocated staff.' || chr(10) ||
      'Cancelled: cancelled shifts in that roster period.' || chr(10) ||
      'Missing Cred: period shifts linked to an open required-credential finding.' || chr(10) ||
      'Every figure compares only the current roster with the immediately next roster.'
    WHEN 'doc_actions' THEN
      'Expired / Due (30d) / Current: active document assignments grouped by expiry date.' || chr(10) ||
      'Current %: active assignments not expired. Onboarding Expired: expired onboarding assignments.' || chr(10) ||
      'Added / Expired in 90d: assignments created or expiring in the last 90 days.' || chr(10) ||
      'Missing Evidence: open Documentation compliance findings.'
    WHEN 'location_actions' THEN
      'Vacant: locations flagged with vacancy.' || chr(10) ||
      'SDA Enrolled / Wheelchair Accessible / Bushfire Danger: active locations with those attributes.' || chr(10) ||
      'Meets Expectations: locations marked as meeting expectations.' || chr(10) ||
      'Open Location Findings appear once Support Location rules are seeded.'
    ELSE 'Calculation details are not configured.'
  END
$$ LANGUAGE sql IMMUTABLE;

-- ---------------------------------------------------------------------------
-- 3. Sequences
-- ---------------------------------------------------------------------------
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_tab_id),0)+1 FROM ad_tab))
WHERE name='AD_Tab' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_toolbarbutton_id),0)+1 FROM ad_toolbarbutton))
WHERE name='AD_ToolBarButton' AND istableid='Y';

-- ---------------------------------------------------------------------------
-- 4. Helpers: column + field (ColumnSQL KPIs)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pg_temp.saw041_kpi_column(
  p_columnname TEXT, p_name TEXT, p_ref INTEGER, p_length INTEGER,
  p_columnsql TEXT, p_description TEXT
) RETURNS void AS $$
DECLARE
  v_table_id INTEGER;
  v_element_id INTEGER;
  v_column_id INTEGER;
  v_euu TEXT := '25a041e1-0000-4000-8000-' || substr(md5(p_columnname), 1, 12);
  v_cuu TEXT := '25a041c1-0000-4000-8000-' || substr(md5(p_columnname), 1, 12);
BEGIN
  SELECT ad_table_id INTO v_table_id FROM ad_table WHERE tablename = 'AbERP_ComplianceDashboard';
  SELECT ad_element_id INTO v_element_id FROM ad_element WHERE columnname = p_columnname LIMIT 1;
  IF v_element_id IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, description, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_columnname, 'Ab_ERP', p_name, p_name, p_description, v_euu
    ) RETURNING ad_element_id INTO v_element_id;
  END IF;

  SELECT ad_column_id INTO v_column_id
  FROM ad_column WHERE ad_table_id = v_table_id AND columnname = p_columnname;
  IF v_column_id IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, version, entitytype,
      columnname, ad_table_id, ad_reference_id, fieldlength,
      iskey, isparent, ismandatory, isupdateable, isidentifier,
      seqno, istranslated, isencrypted, isselectioncolumn,
      columnsql, isautocomplete, isalwaysupdateable,
      isallowcopy, issyncdatabase, ad_element_id, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, p_description, p_description, 1, 'Ab_ERP',
      p_columnname, v_table_id, p_ref, p_length,
      'N', 'N', 'N', 'N', 'N',
      500, 'N', 'N', 'N',
      p_columnsql, 'N', 'N',
      'N', 'N', v_element_id, v_cuu
    );
  ELSE
    UPDATE ad_column SET
      name = p_name, description = p_description, help = p_description,
      ad_reference_id = p_ref, fieldlength = p_length,
      columnsql = p_columnsql, isupdateable = 'N', ismandatory = 'N',
      entitytype = 'Ab_ERP', updated = NOW()
    WHERE ad_column_id = v_column_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw041_kpi_field(
  p_tab_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_seqno INTEGER, p_sameline CHAR, p_description TEXT
) RETURNS void AS $$
DECLARE
  v_tab_id INTEGER;
  v_table_id INTEGER;
  v_column_id INTEGER;
  v_field_id INTEGER;
  v_field_uu TEXT := '25a041f1-0000-4000-8000-' || substr(md5(p_tab_uu || p_columnname), 1, 12);
BEGIN
  SELECT ad_tab_id, ad_table_id INTO v_tab_id, v_table_id
  FROM ad_tab WHERE ad_tab_uu = p_tab_uu;
  IF v_tab_id IS NULL THEN
    RAISE EXCEPTION 'SAW025-41: tab missing %', p_tab_uu;
  END IF;
  SELECT ad_column_id INTO v_column_id
  FROM ad_column WHERE ad_table_id = v_table_id AND columnname = p_columnname;
  IF v_column_id IS NULL THEN
    RAISE EXCEPTION 'SAW025-41: column missing %', p_columnname;
  END IF;

  SELECT ad_field_id INTO v_field_id
  FROM ad_field WHERE ad_tab_id = v_tab_id AND ad_column_id = v_column_id;
  IF v_field_id IS NULL THEN
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, iscentrallymaintained,
      ad_tab_id, ad_column_id, isdisplayed, displaylength,
      isreadonly, seqno, issameline, isheading, isfieldonly,
      isencrypted, entitytype, isdisplayedgrid, seqnogrid,
      xposition, columnspan, numlines, ad_field_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, p_description, p_description, 'N',
      v_tab_id, v_column_id, 'Y',
      CASE WHEN (SELECT ad_reference_id FROM ad_column WHERE ad_column_id = v_column_id) = 10 THEN 40 ELSE 14 END,
      'Y', p_seqno, p_sameline, 'N', 'N',
      'N', 'Ab_ERP', 'Y', p_seqno,
      1, 2, 1, v_field_uu
    );
  ELSE
    UPDATE ad_field SET
      name = p_name, description = p_description, help = p_description,
      isdisplayed = 'Y', isreadonly = 'Y', seqno = p_seqno,
      issameline = p_sameline, isdisplayedgrid = 'Y', seqnogrid = p_seqno,
      updated = NOW()
    WHERE ad_field_id = v_field_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw041_add_kpi(
  p_tab_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_ref INTEGER, p_length INTEGER, p_columnsql TEXT,
  p_seqno INTEGER, p_sameline CHAR, p_description TEXT
) RETURNS void AS $$
BEGIN
  PERFORM pg_temp.saw041_kpi_column(
    p_columnname, p_name, p_ref, p_length, p_columnsql, p_description);
  PERFORM pg_temp.saw041_kpi_field(
    p_tab_uu, p_columnname, p_name, p_seqno, p_sameline, p_description);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw041_shared_kpis(
  p_tab_uu TEXT, p_prefix TEXT, p_category TEXT
) RETURNS void AS $$
DECLARE
  v_client TEXT := 'AbERP_ComplianceDashboard.AD_Client_ID';
BEGIN
  PERFORM pg_temp.saw041_add_kpi(p_tab_uu, p_prefix || 'ReadinessScore', 'Readiness Score',
    22, 10,
    'aberp_compliance_category_readiness(' || v_client || ',''' || p_category || ''')',
    10, 'N', 'Latest category audit-readiness score.');
  PERFORM pg_temp.saw041_add_kpi(p_tab_uu, p_prefix || 'TrafficLight', 'Status',
    10, 2,
    'aberp_compliance_category_traffic(' || v_client || ',''' || p_category || ''')',
    12, 'Y', 'Latest category traffic light (R/A/G).');
  PERFORM pg_temp.saw041_add_kpi(p_tab_uu, p_prefix || 'OpenFindings', 'Open Findings',
    11, 10, 'aberp_compliance_finding_kpi(' || v_client || ',''' || p_category || ''',''open'')',
    20, 'N', 'Current unresolved findings in this category.');
  PERFORM pg_temp.saw041_add_kpi(p_tab_uu, p_prefix || 'CriticalOpen', 'Critical Open',
    11, 10, 'aberp_compliance_finding_kpi(' || v_client || ',''' || p_category || ''',''critical'')',
    22, 'Y', 'Current unresolved critical findings.');
  PERFORM pg_temp.saw041_add_kpi(p_tab_uu, p_prefix || 'OpenOver7d', 'Open > 7 days',
    11, 10, 'aberp_compliance_finding_kpi(' || v_client || ',''' || p_category || ''',''over7'')',
    30, 'N', 'Unresolved findings detected more than 7 days ago.');
  PERFORM pg_temp.saw041_add_kpi(p_tab_uu, p_prefix || 'OpenOver30d', 'Open > 30 days',
    11, 10, 'aberp_compliance_finding_kpi(' || v_client || ',''' || p_category || ''',''over30'')',
    32, 'Y', 'Unresolved findings detected more than 30 days ago.');
  PERFORM pg_temp.saw041_add_kpi(p_tab_uu, p_prefix || 'OpenOver90d', 'Open > 90 days',
    11, 10, 'aberp_compliance_finding_kpi(' || v_client || ',''' || p_category || ''',''over90'')',
    40, 'N', 'Unresolved findings detected more than 90 days ago.');
  PERFORM pg_temp.saw041_add_kpi(p_tab_uu, p_prefix || 'NewFindings30d', 'New Findings (30d)',
    11, 10, 'aberp_compliance_finding_kpi(' || v_client || ',''' || p_category || ''',''new30'')',
    42, 'Y', 'Findings detected during the last 30 days.');
  PERFORM pg_temp.saw041_add_kpi(p_tab_uu, p_prefix || 'Resolved30d', 'Resolved (30d)',
    11, 10, 'aberp_compliance_finding_kpi(' || v_client || ',''' || p_category || ''',''resolved30'')',
    50, 'N', 'Findings resolved during the last 30 days.');
  PERFORM pg_temp.saw041_add_kpi(p_tab_uu, p_prefix || 'TopFinding', 'Top Finding',
    10, 120,
    'COALESCE(aberp_compliance_top_finding(' || v_client || ',''' || p_category || '''),''—'')',
    52, 'Y', 'Most frequent current unresolved finding type.');
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- 5. Support Location category tab + Findings nest
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_window_id INTEGER;
  v_dash_id INTEGER;
  v_link_col INTEGER;
  v_result_table INTEGER;
  v_dash_pk INTEGER;
  v_result_link INTEGER;
  v_process_id INTEGER;
  v_btn_col INTEGER;
  v_template_tab INTEGER;
  v_parent_tab INTEGER;
  v_find_tab INTEGER;
  v_ttb INTEGER;
  v_parent_uu CONSTANT TEXT := '23a02317-c0d4-4f01-8e15-000000000001';
  v_find_uu CONSTANT TEXT := '24a02415-c0d4-4f01-8e15-000000000001';
  v_ttb_uu CONSTANT TEXT := '24a02465-c0d4-4f01-8e15-000000000001';
  v_where TEXT;
  f RECORD;
  v_field_id INTEGER;
  v_field_uu TEXT;
  cl TEXT := 'AbERP_ComplianceDashboard.AD_Client_ID';
BEGIN
  SELECT ad_window_id INTO v_window_id
  FROM ad_window
  WHERE ad_window_uu = '23a02305-c0d4-4f01-8e15-000000000001'
     OR name IN ('NDIS Audit Tool', 'Compliance Summary', 'Organisation Audit')
  LIMIT 1;
  IF v_window_id IS NULL THEN
    RAISE EXCEPTION 'SAW025-41: Organisation Audit window missing';
  END IF;

  SELECT ad_table_id INTO v_dash_id FROM ad_table WHERE tablename = 'AbERP_ComplianceDashboard';
  SELECT ad_column_id INTO v_link_col
  FROM ad_column WHERE ad_table_id = v_dash_id AND columnname = 'AbERP_ComplianceDashboard_ID';
  SELECT ad_column_id INTO v_dash_pk FROM ad_column
  WHERE ad_table_id = v_dash_id AND columnname = 'AbERP_ComplianceDashboard_ID';
  SELECT ad_table_id INTO v_result_table FROM ad_table WHERE tablename = 'AbERP_ComplianceResult';
  SELECT ad_column_id INTO v_result_link
  FROM ad_column WHERE ad_table_id = v_result_table AND columnname = 'AbERP_ComplianceDashboard_ID';
  SELECT ad_process_id INTO v_process_id FROM ad_process WHERE value = 'AbERP_Compliance_OpenSource';
  SELECT ad_column_id INTO v_btn_col
  FROM ad_column WHERE ad_table_id = v_result_table AND columnname = 'AbERP_OpenSource';
  SELECT ad_tab_id INTO v_template_tab
  FROM ad_tab WHERE ad_tab_uu = '24a02410-c0d4-4f01-8e15-000000000001';

  IF v_dash_id IS NULL OR v_link_col IS NULL OR v_result_table IS NULL OR v_template_tab IS NULL THEN
    RAISE EXCEPTION 'SAW025-41: dashboard/Findings prerequisites missing';
  END IF;

  UPDATE ad_window SET
    description = 'Organisation NDIS Audit Readiness — overall KPIs plus category tabs (Employee, Client, Incidents, Rostering, Documentation, Support Location)',
    help = 'Organisation Audit shows overall readiness. Category tabs cover Employee, Client, Incidents, Rostering, Documentation, and Support Location.',
    updated = NOW()
  WHERE ad_window_id = v_window_id;

  -- Parent category tab
  SELECT ad_tab_id INTO v_parent_tab FROM ad_tab WHERE ad_tab_uu = v_parent_uu;
  IF v_parent_tab IS NULL THEN
    INSERT INTO ad_tab (
      ad_tab_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, ad_table_id, ad_window_id,
      seqno, tablevel, issinglerow, isreadonly, isinsertrecord,
      isinfotab, istranslationtab, isadvancedtab,
      ad_column_id, entitytype, ad_tab_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Tab' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Support Location',
      'Support Location compliance KPIs',
      'KPIs for Support Locations. Open Findings underneath lists each open issue when rules exist.',
      v_dash_id, v_window_id,
      70, 1, 'Y', 'N', 'N',
      'N', 'N', 'N',
      v_link_col, 'Ab_ERP', v_parent_uu
    ) RETURNING ad_tab_id INTO v_parent_tab;
  ELSE
    UPDATE ad_tab SET
      name = 'Support Location',
      description = 'Support Location compliance KPIs',
      help = 'KPIs for Support Locations. Open Findings underneath lists each open issue when rules exist.',
      ad_table_id = v_dash_id,
      ad_window_id = v_window_id,
      seqno = 70,
      tablevel = 1,
      issinglerow = 'Y',
      isreadonly = 'N',
      isinsertrecord = 'N',
      ad_column_id = v_link_col,
      isactive = 'Y',
      entitytype = 'Ab_ERP',
      updated = NOW()
    WHERE ad_tab_id = v_parent_tab;
  END IF;

  -- Hidden keys on parent
  PERFORM pg_temp.saw041_kpi_field(v_parent_uu, 'AbERP_ComplianceDashboard_ID', 'Compliance Dashboard', 0, 'N', 'Key');
  UPDATE ad_field SET isdisplayed = 'N', isdisplayedgrid = 'N', updated = NOW()
  WHERE ad_tab_id = v_parent_tab
    AND ad_column_id = (SELECT ad_column_id FROM ad_column WHERE ad_table_id = v_dash_id AND columnname = 'AbERP_ComplianceDashboard_ID');
  PERFORM pg_temp.saw041_kpi_field(v_parent_uu, 'AD_Client_ID', 'Client', 5, 'N', 'Client');
  UPDATE ad_field SET isdisplayed = 'N', isdisplayedgrid = 'N', updated = NOW()
  WHERE ad_tab_id = v_parent_tab
    AND ad_column_id = (SELECT ad_column_id FROM ad_column WHERE ad_table_id = v_dash_id AND columnname = 'AD_Client_ID');

  -- Population
  PERFORM pg_temp.saw041_add_kpi(v_parent_uu, 'ActiveSupportLocations', 'Active Support Locations',
    11, 10, 'aberp_compliance_location_kpi(' || cl || ',''population'')',
    2, 'N', 'Active Support Location records.');
  PERFORM pg_temp.saw041_add_kpi(v_parent_uu, 'ActiveSupportLocationsChange90d', 'Change (90d)',
    11, 10, 'aberp_compliance_location_kpi(' || cl || ',''change90d'')',
    4, 'Y', 'Current population minus 90-day baseline.');

  -- Shared readiness / findings KPIs
  PERFORM pg_temp.saw041_shared_kpis(v_parent_uu, 'Location', 'L');

  -- Action KPIs
  PERFORM pg_temp.saw041_add_kpi(v_parent_uu, 'LocationVacant', 'Vacant Locations',
    11, 10, 'aberp_compliance_location_kpi(' || cl || ',''vacant'')',
    60, 'N', 'Active locations flagged with vacancy.');
  PERFORM pg_temp.saw041_add_kpi(v_parent_uu, 'LocationSDA', 'SDA Enrolled',
    11, 10, 'aberp_compliance_location_kpi(' || cl || ',''sda'')',
    62, 'Y', 'Active locations enrolled in SDA.');
  PERFORM pg_temp.saw041_add_kpi(v_parent_uu, 'LocationWheelchair', 'Wheelchair Accessible',
    11, 10, 'aberp_compliance_location_kpi(' || cl || ',''wheelchair'')',
    70, 'N', 'Active wheelchair-accessible locations.');
  PERFORM pg_temp.saw041_add_kpi(v_parent_uu, 'LocationBushfire', 'Bushfire Danger Area',
    11, 10, 'aberp_compliance_location_kpi(' || cl || ',''bushfire'')',
    72, 'Y', 'Active locations in a bushfire danger area.');
  PERFORM pg_temp.saw041_add_kpi(v_parent_uu, 'LocationMeetsExpects', 'Meets Expectations',
    11, 10, 'aberp_compliance_location_kpi(' || cl || ',''meets_expects'')',
    80, 'N', 'Active locations marked as meeting expectations.');

  -- Legacy snapshot buckets (collapsed later)
  PERFORM pg_temp.saw041_add_kpi(v_parent_uu, 'LocationTotal', 'Total Items',
    11, 10, 'aberp_compliance_location_bucket(' || cl || ',''total'')', 200, 'N', 'Latest snapshot total items.');
  PERFORM pg_temp.saw041_add_kpi(v_parent_uu, 'LocationCompliant', 'Compliant',
    11, 10, 'aberp_compliance_location_bucket(' || cl || ',''compliant'')', 202, 'Y', 'Latest snapshot compliant.');
  PERFORM pg_temp.saw041_add_kpi(v_parent_uu, 'LocationWarning', 'Warning',
    11, 10, 'aberp_compliance_location_bucket(' || cl || ',''warning'')', 210, 'N', 'Latest snapshot warning.');
  PERFORM pg_temp.saw041_add_kpi(v_parent_uu, 'LocationNonCompliant', 'Non-Compliant',
    11, 10, 'aberp_compliance_location_bucket(' || cl || ',''noncompliant'')', 212, 'Y', 'Latest snapshot non-compliant.');
  PERFORM pg_temp.saw041_add_kpi(v_parent_uu, 'LocationCritical', 'Critical',
    11, 10, 'aberp_compliance_location_bucket(' || cl || ',''critical'')', 220, 'N', 'Latest snapshot critical.');
  PERFORM pg_temp.saw041_add_kpi(v_parent_uu, 'LocationOverdue', 'Overdue / Expired',
    11, 10, 'aberp_compliance_location_bucket(' || cl || ',''overdue'')', 222, 'Y', 'Latest snapshot overdue.');
  PERFORM pg_temp.saw041_add_kpi(v_parent_uu, 'LocationAtRisk', 'At Risk (30 days)',
    11, 10, 'aberp_compliance_location_bucket(' || cl || ',''atrisk'')', 230, 'N', 'Latest snapshot at risk.');
  PERFORM pg_temp.saw041_add_kpi(v_parent_uu, 'LocationOnTrack', 'On Track',
    11, 10, 'aberp_compliance_location_bucket(' || cl || ',''ontrack'')', 232, 'Y', 'Latest snapshot on track.');
  PERFORM pg_temp.saw041_add_kpi(v_parent_uu, 'LocationChange', 'Finding Count Change',
    11, 10, '0::numeric', 240, 'N', 'Reserved — finding count change between refreshes.');

  UPDATE ad_field SET isreadonly = 'Y', updated = NOW() WHERE ad_tab_id = v_parent_tab;

  -- Findings tab
  v_where := 'AbERP_ComplianceRule_ID IN (SELECT AbERP_ComplianceRule_ID FROM AbERP_ComplianceRule WHERE ComplianceCategory=''L'') AND IsResolved=''N'' AND IsActive=''Y''';

  SELECT ad_tab_id INTO v_find_tab FROM ad_tab WHERE ad_tab_uu = v_find_uu;
  IF v_find_tab IS NULL THEN
    INSERT INTO ad_tab (
      ad_tab_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, ad_table_id, ad_window_id,
      seqno, tablevel, issinglerow, isreadonly, isinsertrecord,
      isinfotab, istranslationtab, isadvancedtab,
      ad_column_id, parent_column_id,
      whereclause, orderbyclause, entitytype, ad_tab_uu,
      displaylogic
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Tab' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Support Location Findings',
      'Support Location open findings — why, resolve, open source',
      'Support Location open findings — location attributes and related sources',
      v_result_table, v_window_id,
      75, 2, 'N', 'N', 'N',
      'N', 'N', 'N',
      v_result_link, v_dash_pk,
      v_where,
      'Severity, DueDate, AbERP_ComplianceResult_ID',
      'Ab_ERP', v_find_uu,
      '@ActiveSupportLocations@>-1'
    ) RETURNING ad_tab_id INTO v_find_tab;
  ELSE
    UPDATE ad_tab SET
      name = 'Support Location Findings',
      description = 'Support Location open findings — why, resolve, open source',
      help = 'Support Location open findings — location attributes and related sources',
      ad_table_id = v_result_table,
      ad_window_id = v_window_id,
      seqno = 75,
      tablevel = 2,
      issinglerow = 'N',
      isreadonly = 'N',
      isinsertrecord = 'N',
      ad_column_id = v_result_link,
      parent_column_id = v_dash_pk,
      whereclause = v_where,
      orderbyclause = 'Severity, DueDate, AbERP_ComplianceResult_ID',
      displaylogic = '@ActiveSupportLocations@>-1',
      isadvancedtab = 'N',
      entitytype = 'Ab_ERP',
      isactive = 'Y',
      updated = NOW()
    WHERE ad_tab_id = v_find_tab;
  END IF;

  UPDATE ad_tab SET
    included_tab_id = v_find_tab,
    description = 'Support Location compliance KPIs',
    help = 'KPIs for this category. Open Findings underneath lists each open issue. Use Open & Fix to jump to the source record, then Refresh Compliance.',
    updated = NOW()
  WHERE ad_tab_id = v_parent_tab;

  -- Copy fields from Employee Open Findings template
  FOR f IN
    SELECT tf.*, c.columnname
    FROM ad_field tf
    JOIN ad_column c ON c.ad_column_id = tf.ad_column_id
    WHERE tf.ad_tab_id = v_template_tab AND tf.isactive = 'Y'
    ORDER BY tf.seqno, tf.ad_field_id
  LOOP
    v_field_uu := substr(v_find_uu, 1, 8) || '-'
      || lpad((f.ad_column_id % 10000)::text, 4, '0')
      || '-4f01-8e15-000000000001';

    SELECT ad_field_id INTO v_field_id
    FROM ad_field
    WHERE ad_field_uu = v_field_uu
       OR (ad_tab_id = v_find_tab AND ad_column_id = f.ad_column_id)
    LIMIT 1;

    IF v_field_id IS NULL THEN
      INSERT INTO ad_field (
        ad_field_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby,
        name, description, help, iscentrallymaintained,
        ad_tab_id, ad_column_id,
        isdisplayed, displaylength, isreadonly, seqno, seqnogrid,
        issameline, isheading, isfieldonly, isencrypted, entitytype,
        isdisplayedgrid, xposition, columnspan, numlines,
        istoolbarbutton, ad_field_uu
      ) VALUES (
        nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
        0, 0, 'Y', NOW(), 100, NOW(), 100,
        f.name, f.description, f.help, COALESCE(f.iscentrallymaintained, 'N'),
        v_find_tab, f.ad_column_id,
        f.isdisplayed, COALESCE(f.displaylength, 0),
        CASE WHEN f.columnname = 'AbERP_OpenSource' THEN 'N' ELSE 'Y' END,
        f.seqno, COALESCE(f.seqnogrid, f.seqno),
        COALESCE(f.issameline, 'N'), COALESCE(f.isheading, 'N'),
        COALESCE(f.isfieldonly, 'N'), COALESCE(f.isencrypted, 'N'), 'Ab_ERP',
        f.isdisplayedgrid, COALESCE(f.xposition, 1), COALESCE(f.columnspan, 1), COALESCE(f.numlines, 1),
        f.istoolbarbutton, v_field_uu
      );
    ELSE
      UPDATE ad_field SET
        name = f.name,
        description = f.description,
        help = f.help,
        isdisplayed = f.isdisplayed,
        isdisplayedgrid = f.isdisplayedgrid,
        isreadonly = CASE WHEN f.columnname = 'AbERP_OpenSource' THEN 'N' ELSE 'Y' END,
        seqno = f.seqno,
        seqnogrid = COALESCE(f.seqnogrid, f.seqno),
        ad_field_uu = COALESCE(ad_field_uu, v_field_uu),
        isactive = 'Y',
        updated = NOW()
      WHERE ad_field_id = v_field_id;
    END IF;
  END LOOP;

  UPDATE ad_field SET
    name = 'Source',
    isdisplayed = 'N',
    isdisplayedgrid = 'N',
    updated = NOW()
  WHERE ad_tab_id = v_find_tab
    AND ad_column_id = (
      SELECT ad_column_id FROM ad_column
      WHERE ad_table_id = v_result_table AND columnname = 'AbERP_AssignmentLabel'
    );

  UPDATE ad_field SET
    name = 'Open & Fix',
    isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    isreadonly = 'N',
    seqno = 5,
    seqnogrid = 5,
    updated = NOW()
  WHERE ad_tab_id = v_find_tab AND ad_column_id = v_btn_col;

  IF v_process_id IS NOT NULL THEN
    SELECT ad_toolbarbutton_id INTO v_ttb
    FROM ad_toolbarbutton WHERE ad_toolbarbutton_uu = v_ttb_uu;
    IF v_ttb IS NULL THEN
      INSERT INTO ad_toolbarbutton (
        ad_toolbarbutton_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby,
        name, componentname, action, ad_tab_id, ad_process_id,
        seqno, isadvancedbutton, iscustomization, entitytype,
        ad_toolbarbutton_uu
      ) VALUES (
        nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_ToolBarButton' AND istableid = 'Y')::integer, 'N'),
        0, 0, 'Y', NOW(), 100, NOW(), 100,
        'Open & Fix', 'AbERP_OpenSource', 'W', v_find_tab, v_process_id,
        10, 'N', 'N', 'Ab_ERP', v_ttb_uu
      );
    ELSE
      UPDATE ad_toolbarbutton SET
        name = 'Open & Fix',
        ad_tab_id = v_find_tab,
        ad_process_id = v_process_id,
        isactive = 'Y',
        updated = NOW()
      WHERE ad_toolbarbutton_id = v_ttb;
    END IF;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 6. Progressive field groups + explainers for Support Location
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_tab_id INTEGER;
  v_fg_glance INTEGER;
  v_fg_action INTEGER;
  v_fg_trends INTEGER;
  v_fg_breakdown INTEGER;
  v_col INTEGER;
  v_prefix TEXT := 'Location';
BEGIN
  SELECT ad_tab_id INTO v_tab_id
  FROM ad_tab WHERE ad_tab_uu = '23a02317-c0d4-4f01-8e15-000000000001';
  IF v_tab_id IS NULL THEN
    RAISE EXCEPTION 'SAW025-41: Support Location tab missing after create';
  END IF;

  SELECT ad_fieldgroup_id INTO v_fg_glance FROM ad_fieldgroup
  WHERE ad_fieldgroup_uu = '25a039fg-0001-4f01-8e15-000000000001'
     OR (name = 'At a glance' AND entitytype = 'Ab_ERP') LIMIT 1;
  SELECT ad_fieldgroup_id INTO v_fg_action FROM ad_fieldgroup
  WHERE ad_fieldgroup_uu = '25a039fg-0002-4f01-8e15-000000000001'
     OR (name = 'Action required' AND entitytype = 'Ab_ERP') LIMIT 1;
  SELECT ad_fieldgroup_id INTO v_fg_trends FROM ad_fieldgroup
  WHERE ad_fieldgroup_uu = '25a039fg-0003-4f01-8e15-000000000001'
     OR (name = 'Trends and ageing' AND entitytype = 'Ab_ERP') LIMIT 1;
  SELECT ad_fieldgroup_id INTO v_fg_breakdown FROM ad_fieldgroup
  WHERE ad_fieldgroup_uu = '25a039fg-0004-4f01-8e15-000000000001'
     OR (name = 'Compliance breakdown' AND entitytype = 'Ab_ERP') LIMIT 1;

  IF v_fg_glance IS NULL OR v_fg_action IS NULL OR v_fg_trends IS NULL OR v_fg_breakdown IS NULL THEN
    RAISE EXCEPTION 'SAW025-41: progressive field groups missing — run sql/39 first';
  END IF;

  UPDATE ad_field f SET
    ad_fieldgroup_id = v_fg_glance,
    seqno = CASE c.columnname
      WHEN 'ActiveSupportLocations' THEN 10
      WHEN 'ActiveSupportLocationsChange90d' THEN 12
      WHEN 'LocationReadinessScore' THEN 20
      WHEN 'LocationTrafficLight' THEN 22
      WHEN 'LocationOpenFindings' THEN 30
      WHEN 'LocationCriticalOpen' THEN 32
      WHEN 'LocationTopFinding' THEN 40
      ELSE f.seqno END,
    seqnogrid = 0, updated = NOW(), updatedby = 100
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab_id AND f.ad_column_id = c.ad_column_id
    AND c.columnname IN (
      'ActiveSupportLocations', 'ActiveSupportLocationsChange90d',
      'LocationReadinessScore', 'LocationTrafficLight',
      'LocationOpenFindings', 'LocationCriticalOpen', 'LocationTopFinding'
    );

  -- Reuse explainer helpers from 39 if present via direct column/field upsert
  PERFORM pg_temp.saw041_add_kpi(
    '23a02317-c0d4-4f01-8e15-000000000001',
    'LocationPopulationExplainer', 'How calculated',
    10, 500, 'aberp_compliance_explainer(''location_population'')',
    14, 'N', 'Persistent explanation of how the calculations above are derived.');
  UPDATE ad_field f SET ad_fieldgroup_id = v_fg_glance, seqnogrid = 0, columnspan = 2, numlines = 2, updated = NOW()
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab_id AND f.ad_column_id = c.ad_column_id
    AND c.columnname = 'LocationPopulationExplainer';

  PERFORM pg_temp.saw041_add_kpi(
    '23a02317-c0d4-4f01-8e15-000000000001',
    'LocationReadinessExplainer', 'How calculated',
    10, 500, 'aberp_compliance_explainer(''readiness'')',
    24, 'N', 'Persistent explanation of how the calculations above are derived.');
  UPDATE ad_field f SET ad_fieldgroup_id = v_fg_glance, seqnogrid = 0, columnspan = 2, numlines = 2, updated = NOW()
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab_id AND f.ad_column_id = c.ad_column_id
    AND c.columnname = 'LocationReadinessExplainer';

  PERFORM pg_temp.saw041_add_kpi(
    '23a02317-c0d4-4f01-8e15-000000000001',
    'LocationFindingsExplainer', 'How calculated',
    10, 500, 'aberp_compliance_explainer(''findings'')',
    42, 'N', 'Persistent explanation of how the calculations above are derived.');
  UPDATE ad_field f SET ad_fieldgroup_id = v_fg_glance, seqnogrid = 0, columnspan = 2, numlines = 2, updated = NOW()
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab_id AND f.ad_column_id = c.ad_column_id
    AND c.columnname = 'LocationFindingsExplainer';

  UPDATE ad_field f SET
    ad_fieldgroup_id = v_fg_action,
    seqno = CASE c.columnname
      WHEN 'LocationVacant' THEN 100
      WHEN 'LocationSDA' THEN 102
      WHEN 'LocationWheelchair' THEN 110
      WHEN 'LocationBushfire' THEN 112
      WHEN 'LocationMeetsExpects' THEN 120
      ELSE f.seqno END,
    seqnogrid = 0, updated = NOW(), updatedby = 100
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab_id AND f.ad_column_id = c.ad_column_id
    AND c.columnname IN (
      'LocationVacant', 'LocationSDA', 'LocationWheelchair',
      'LocationBushfire', 'LocationMeetsExpects'
    );

  PERFORM pg_temp.saw041_add_kpi(
    '23a02317-c0d4-4f01-8e15-000000000001',
    'LocationActionExplainer', 'How calculated',
    10, 500, 'aberp_compliance_explainer(''location_actions'')',
    130, 'N', 'Persistent explanation of how the calculations above are derived.');
  UPDATE ad_field f SET ad_fieldgroup_id = v_fg_action, seqnogrid = 0, columnspan = 2, numlines = 4, updated = NOW()
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab_id AND f.ad_column_id = c.ad_column_id
    AND c.columnname = 'LocationActionExplainer';

  UPDATE ad_field f SET
    ad_fieldgroup_id = v_fg_trends,
    seqno = CASE c.columnname
      WHEN 'LocationOpenOver7d' THEN 300
      WHEN 'LocationOpenOver30d' THEN 302
      WHEN 'LocationOpenOver90d' THEN 310
      WHEN 'LocationNewFindings30d' THEN 312
      WHEN 'LocationResolved30d' THEN 320
      ELSE f.seqno END,
    seqnogrid = 0, updated = NOW(), updatedby = 100
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab_id AND f.ad_column_id = c.ad_column_id
    AND c.columnname IN (
      'LocationOpenOver7d', 'LocationOpenOver30d', 'LocationOpenOver90d',
      'LocationNewFindings30d', 'LocationResolved30d'
    );

  UPDATE ad_field f SET
    ad_fieldgroup_id = v_fg_breakdown,
    seqno = CASE c.columnname
      WHEN 'LocationTotal' THEN 500
      WHEN 'LocationCompliant' THEN 502
      WHEN 'LocationWarning' THEN 510
      WHEN 'LocationNonCompliant' THEN 512
      WHEN 'LocationCritical' THEN 520
      WHEN 'LocationOverdue' THEN 522
      WHEN 'LocationAtRisk' THEN 530
      WHEN 'LocationOnTrack' THEN 532
      WHEN 'LocationChange' THEN 540
      ELSE f.seqno END,
    seqnogrid = 0, updated = NOW(), updatedby = 100
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab_id AND f.ad_column_id = c.ad_column_id
    AND c.columnname ~ '^Location(Total|Compliant|Warning|NonCompliant|Critical|Overdue|AtRisk|OnTrack|Change)$';
END $$;

-- ---------------------------------------------------------------------------
-- 7. Verify Findings nesting + DisplayLogic
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM ad_tab parent
  JOIN ad_tab child ON child.ad_tab_id = parent.included_tab_id
  WHERE parent.ad_tab_uu = '23a02317-c0d4-4f01-8e15-000000000001'
    AND child.ad_tab_uu = '24a02415-c0d4-4f01-8e15-000000000001'
    AND child.displaylogic = '@ActiveSupportLocations@>-1';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'SAW025-41: Support Location Findings linkage/DisplayLogic failed (count=%)', v_count;
  END IF;
END $$;

SELECT
  p.name AS parent_tab,
  c.name AS findings_tab,
  c.displaylogic,
  aberp_compliance_location_kpi(1000003, 'population') AS active_locations,
  aberp_compliance_location_kpi(1000003, 'vacant') AS vacant
FROM ad_tab p
JOIN ad_tab c ON c.ad_tab_id = p.included_tab_id
WHERE p.ad_tab_uu = '23a02317-c0d4-4f01-8e15-000000000001';
