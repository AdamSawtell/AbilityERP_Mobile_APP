-- SAW025-39 — Progressive category-tab UX with persistent calculation explainers
SET search_path TO adempiere;

CREATE OR REPLACE FUNCTION aberp_compliance_explainer(p_key TEXT)
RETURNS TEXT AS $$
  SELECT CASE p_key
    WHEN 'lead_readiness' THEN
      'Audit Readiness Score is the average latest score across the five categories. Traffic Light is the overall red, amber or green result.'
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
    ELSE 'Calculation details are not configured.'
  END
$$ LANGUAGE sql IMMUTABLE;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_fieldgroup_id),0)+1 FROM ad_fieldgroup))
WHERE name='AD_FieldGroup' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw025_group(
  p_uu TEXT, p_name TEXT, p_type CHAR, p_collapsed CHAR
) RETURNS INTEGER AS $$
DECLARE
  v_id INTEGER;
BEGIN
  SELECT ad_fieldgroup_id INTO v_id FROM ad_fieldgroup WHERE ad_fieldgroup_uu=p_uu;
  IF v_id IS NULL THEN
    SELECT ad_fieldgroup_id INTO v_id FROM ad_fieldgroup
    WHERE name=p_name AND entitytype='Ab_ERP' LIMIT 1;
  END IF;
  IF v_id IS NULL THEN
    INSERT INTO ad_fieldgroup (
      ad_fieldgroup_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, entitytype, fieldgrouptype, iscollapsedbydefault, ad_fieldgroup_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_FieldGroup' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100,
      p_name,'Ab_ERP',p_type,p_collapsed,p_uu
    ) RETURNING ad_fieldgroup_id INTO v_id;
  ELSE
    UPDATE ad_fieldgroup SET
      name=p_name, entitytype='Ab_ERP', fieldgrouptype=p_type,
      iscollapsedbydefault=p_collapsed,
      ad_fieldgroup_uu=COALESCE(NULLIF(ad_fieldgroup_uu,''),p_uu),
      updated=NOW(), updatedby=100
    WHERE ad_fieldgroup_id=v_id;
  END IF;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw025_explainer_column(
  p_columnname TEXT, p_key TEXT
) RETURNS INTEGER AS $$
DECLARE
  v_table_id INTEGER;
  v_element_id INTEGER;
  v_column_id INTEGER;
  v_desc TEXT := 'Persistent explanation of how the calculations above are derived.';
  v_euu TEXT := '25a039e1-0000-4000-8000-'||substr(md5(p_columnname),1,12);
  v_cuu TEXT := '25a039c1-0000-4000-8000-'||substr(md5(p_columnname),1,12);
BEGIN
  SELECT ad_table_id INTO v_table_id FROM ad_table WHERE tablename='AbERP_ComplianceDashboard';
  SELECT ad_element_id INTO v_element_id FROM ad_element WHERE columnname=p_columnname LIMIT 1;
  IF v_element_id IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, description, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_Element' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100,
      p_columnname,'Ab_ERP','How calculated','How calculated',v_desc,v_euu
    ) RETURNING ad_element_id INTO v_element_id;
  END IF;

  SELECT ad_column_id INTO v_column_id FROM ad_column
  WHERE ad_table_id=v_table_id AND columnname=p_columnname;
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
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_Column' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100,
      'How calculated',v_desc,v_desc,1,'Ab_ERP',
      p_columnname,v_table_id,10,500,
      'N','N','N','N','N',
      900,'N','N','N',
      'aberp_compliance_explainer('''||p_key||''')','N','N',
      'N','N',v_element_id,v_cuu
    ) RETURNING ad_column_id INTO v_column_id;
  ELSE
    UPDATE ad_column SET
      name='How calculated', description=v_desc, help=v_desc,
      ad_reference_id=10, fieldlength=500,
      columnsql='aberp_compliance_explainer('''||p_key||''')',
      isupdateable='N', entitytype='Ab_ERP', updated=NOW(), updatedby=100
    WHERE ad_column_id=v_column_id;
  END IF;
  RETURN v_column_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw025_explainer_field(
  p_tab_id NUMERIC, p_column_id INTEGER, p_group_id INTEGER,
  p_seqno INTEGER, p_lines INTEGER, p_key TEXT
) RETURNS void AS $$
DECLARE
  v_field_id INTEGER;
  v_fuu TEXT := '25a039f1-0000-4000-8000-'||substr(md5(p_tab_id::text||p_key),1,12);
BEGIN
  SELECT ad_field_id INTO v_field_id FROM ad_field
  WHERE ad_tab_id=p_tab_id AND ad_column_id=p_column_id;
  IF v_field_id IS NULL THEN
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, iscentrallymaintained,
      ad_tab_id, ad_column_id, ad_fieldgroup_id,
      isdisplayed, displaylength, seqno, sortno,
      issameline, isheading, isfieldonly, isreadonly,
      entitytype, xposition, columnspan, numlines,
      isdisplayedgrid, seqnogrid, isencrypted, ad_field_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_Field' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100,
      'How calculated','How the calculations above are derived.',
      'How the calculations above are derived.','N',
      p_tab_id,p_column_id,p_group_id,
      'Y',100,p_seqno,NULL,
      'N','N','Y','Y',
      'Ab_ERP',1,5,p_lines,
      'N',0,'N',v_fuu
    );
  ELSE
    UPDATE ad_field SET
      name='How calculated', description='How the calculations above are derived.',
      help='How the calculations above are derived.',
      iscentrallymaintained='N', ad_fieldgroup_id=p_group_id,
      isdisplayed='Y', isdisplayedgrid='N',
      seqno=p_seqno, seqnogrid=0, issameline='N',
      isfieldonly='Y', isreadonly='Y',
      xposition=1, columnspan=5, numlines=p_lines, displaylength=100,
      entitytype='Ab_ERP', updated=NOW(), updatedby=100
    WHERE ad_field_id=v_field_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_fg_glance INTEGER;
  v_fg_action INTEGER;
  v_fg_trends INTEGER;
  v_fg_breakdown INTEGER;
  v_tab RECORD;
  v_col INTEGER;
  v_prefix TEXT;
  v_pop_key TEXT;
  v_action_key TEXT;
  v_pop_column TEXT;
  v_action_column TEXT;
  v_lead_tab NUMERIC;
BEGIN
  v_fg_glance := pg_temp.saw025_group(
    '25a039fg-0001-4f01-8e15-000000000001','At a glance','L','N');
  v_fg_action := pg_temp.saw025_group(
    '25a039fg-0002-4f01-8e15-000000000001','Action required','C','N');
  v_fg_trends := pg_temp.saw025_group(
    '25a039fg-0003-4f01-8e15-000000000001','Trends and ageing','C','Y');
  v_fg_breakdown := pg_temp.saw025_group(
    '25a039fg-0004-4f01-8e15-000000000001','Compliance breakdown','C','Y');

  FOR v_tab IN
    SELECT ad_tab_id, ad_tab_uu,
      CASE ad_tab_uu
        WHEN '23a02311-c0d4-4f01-8e15-000000000001' THEN 'Employee'
        WHEN '23a02312-c0d4-4f01-8e15-000000000001' THEN 'Client'
        WHEN '23a02313-c0d4-4f01-8e15-000000000001' THEN 'Incident'
        WHEN '23a02314-c0d4-4f01-8e15-000000000001' THEN 'Roster'
        WHEN '23a02315-c0d4-4f01-8e15-000000000001' THEN 'Doc'
      END AS prefix,
      CASE ad_tab_uu
        WHEN '23a02311-c0d4-4f01-8e15-000000000001' THEN 'employee'
        WHEN '23a02312-c0d4-4f01-8e15-000000000001' THEN 'client'
        WHEN '23a02313-c0d4-4f01-8e15-000000000001' THEN 'incident'
        WHEN '23a02314-c0d4-4f01-8e15-000000000001' THEN 'roster'
        WHEN '23a02315-c0d4-4f01-8e15-000000000001' THEN 'doc'
      END AS key_prefix
    FROM ad_tab
    WHERE ad_tab_uu IN (
      '23a02311-c0d4-4f01-8e15-000000000001',
      '23a02312-c0d4-4f01-8e15-000000000001',
      '23a02313-c0d4-4f01-8e15-000000000001',
      '23a02314-c0d4-4f01-8e15-000000000001',
      '23a02315-c0d4-4f01-8e15-000000000001'
    )
  LOOP
    v_prefix := v_tab.prefix;
    v_pop_key := v_tab.key_prefix||'_population';
    v_action_key := v_tab.key_prefix||'_actions';
    v_pop_column := v_prefix||'PopulationExplainer';
    v_action_column := v_prefix||'ActionExplainer';

    -- At a glance: population pair.
    UPDATE ad_field f SET
      ad_fieldgroup_id=v_fg_glance,
      seqno=CASE c.columnname
        WHEN 'ActiveEmployees' THEN 10 WHEN 'ActiveEmployeesChange90d' THEN 12
        WHEN 'ActiveClients' THEN 10 WHEN 'ActiveClientsChange90d' THEN 12
        WHEN 'ActiveIncidents' THEN 10 WHEN 'ActiveIncidentsChange90d' THEN 12
        WHEN 'PeriodShifts' THEN 10 WHEN 'NextPeriodShifts' THEN 12
        WHEN 'TotalDocuments' THEN 10 WHEN 'TotalDocumentsChange90d' THEN 12
        ELSE f.seqno END,
      seqnogrid=0, updated=NOW(), updatedby=100
    FROM ad_column c
    WHERE f.ad_tab_id=v_tab.ad_tab_id AND f.ad_column_id=c.ad_column_id
      AND c.columnname IN (
        'ActiveEmployees','ActiveEmployeesChange90d',
        'ActiveClients','ActiveClientsChange90d',
        'ActiveIncidents','ActiveIncidentsChange90d',
        'PeriodShifts','NextPeriodShifts',
        'TotalDocuments','TotalDocumentsChange90d'
      );

    v_col := pg_temp.saw025_explainer_column(v_pop_column,v_pop_key);
    PERFORM pg_temp.saw025_explainer_field(
      v_tab.ad_tab_id,v_col,v_fg_glance,14,2,v_pop_key);

    -- At a glance: readiness/status, open/critical, top finding.
    UPDATE ad_field f SET
      ad_fieldgroup_id=v_fg_glance,
      seqno=CASE c.columnname
        WHEN v_prefix||'ReadinessScore' THEN 20
        WHEN v_prefix||'TrafficLight' THEN 22
        WHEN v_prefix||'OpenFindings' THEN 30
        WHEN v_prefix||'CriticalOpen' THEN 32
        WHEN v_prefix||'TopFinding' THEN 40
        ELSE f.seqno END,
      seqnogrid=0, updated=NOW(), updatedby=100
    FROM ad_column c
    WHERE f.ad_tab_id=v_tab.ad_tab_id AND f.ad_column_id=c.ad_column_id
      AND c.columnname IN (
        v_prefix||'ReadinessScore',v_prefix||'TrafficLight',
        v_prefix||'OpenFindings',v_prefix||'CriticalOpen',
        v_prefix||'TopFinding'
      );

    v_col := pg_temp.saw025_explainer_column(v_prefix||'ReadinessExplainer','readiness');
    PERFORM pg_temp.saw025_explainer_field(
      v_tab.ad_tab_id,v_col,v_fg_glance,24,2,v_tab.key_prefix||'_readiness');
    v_col := pg_temp.saw025_explainer_column(v_prefix||'FindingsExplainer','findings');
    PERFORM pg_temp.saw025_explainer_field(
      v_tab.ad_tab_id,v_col,v_fg_glance,42,2,v_tab.key_prefix||'_findings');

    -- Action-required metrics are the category-specific fields introduced at 60+.
    UPDATE ad_field f SET
      ad_fieldgroup_id=v_fg_action,
      seqno=CASE c.columnname
        WHEN 'EmployeeScreeningExpired' THEN 100
        WHEN 'EmployeeScreeningDue30' THEN 102
        WHEN 'EmployeeCredentialCurrentPct' THEN 110
        WHEN 'EmployeeNewStarterMissingDocs' THEN 112
        WHEN 'EmployeeUnavailableToday' THEN 120
        WHEN 'EmployeeRosteredThisPeriod' THEN 122
        WHEN 'ClientRiskOverdue' THEN 100
        WHEN 'ClientRiskDue30' THEN 102
        WHEN 'ClientNoSupport30d' THEN 110
        WHEN 'ClientPlanReviewDue30' THEN 112
        WHEN 'ClientPlansExpired' THEN 120
        WHEN 'ClientAssessmentsCurrent' THEN 122
        WHEN 'IncidentClosed30d' THEN 100
        WHEN 'IncidentOverdueInvestigations' THEN 102
        WHEN 'IncidentOutstandingActions' THEN 110
        WHEN 'IncidentReportableOpen' THEN 112
        WHEN 'IncidentMedianDaysOpen' THEN 120
        WHEN 'IncidentOldestDaysOpen' THEN 122
        WHEN 'RosterFillRatePct' THEN 100
        WHEN 'RosterCoverage7dPct' THEN 102
        WHEN 'RosterUnfilledShifts' THEN 110
        WHEN 'RosterCoverage14dPct' THEN 112
        WHEN 'RosterFilledShifts' THEN 120
        WHEN 'RosterPartialShifts' THEN 122
        WHEN 'RosterCancelledShifts' THEN 130
        WHEN 'RosterAgencyAssignments' THEN 132
        WHEN 'RosterMissingCredential' THEN 140
        WHEN 'RosterEmployeeAssignments' THEN 142
        WHEN 'DocExpiredDocuments' THEN 100
        WHEN 'DocDue30' THEN 102
        WHEN 'DocCurrentDocuments' THEN 110
        WHEN 'DocCurrentPct' THEN 112
        WHEN 'DocOnboardingExpired' THEN 120
        WHEN 'DocAdded90d' THEN 122
        WHEN 'DocExpired90d' THEN 130
        WHEN 'DocMissingEvidence' THEN 132
        ELSE f.seqno END,
      seqnogrid=0, updated=NOW(), updatedby=100
    FROM ad_column c
    WHERE f.ad_tab_id=v_tab.ad_tab_id AND f.ad_column_id=c.ad_column_id
      AND (
        (v_prefix='Employee' AND c.columnname IN (
          'EmployeeScreeningExpired','EmployeeScreeningDue30',
          'EmployeeCredentialCurrentPct','EmployeeNewStarterMissingDocs',
          'EmployeeUnavailableToday','EmployeeRosteredThisPeriod'))
        OR (v_prefix='Client' AND c.columnname IN (
          'ClientRiskOverdue','ClientRiskDue30','ClientNoSupport30d',
          'ClientPlanReviewDue30','ClientPlansExpired','ClientAssessmentsCurrent'))
        OR (v_prefix='Incident' AND c.columnname IN (
          'IncidentClosed30d','IncidentOverdueInvestigations',
          'IncidentOutstandingActions','IncidentReportableOpen',
          'IncidentMedianDaysOpen','IncidentOldestDaysOpen'))
        OR (v_prefix='Roster' AND c.columnname IN (
          'RosterFillRatePct','RosterCoverage7dPct','RosterUnfilledShifts',
          'RosterCoverage14dPct','RosterFilledShifts','RosterPartialShifts',
          'RosterCancelledShifts','RosterAgencyAssignments',
          'RosterMissingCredential','RosterEmployeeAssignments'))
        OR (v_prefix='Doc' AND c.columnname IN (
          'DocExpiredDocuments','DocDue30','DocCurrentDocuments','DocCurrentPct',
          'DocOnboardingExpired','DocAdded90d','DocExpired90d','DocMissingEvidence'))
      );

    v_col := pg_temp.saw025_explainer_column(v_action_column,v_action_key);
    PERFORM pg_temp.saw025_explainer_field(
      v_tab.ad_tab_id,v_col,v_fg_action,
      CASE
        WHEN v_prefix='Roster' THEN 150
        WHEN v_prefix='Doc' THEN 140
        ELSE 130
      END,
      CASE WHEN v_prefix='Roster' THEN 5 ELSE 4 END,v_action_key);

    -- Finding history is secondary and collapsed.
    UPDATE ad_field f SET
      ad_fieldgroup_id=v_fg_trends,
      seqno=CASE c.columnname
        WHEN v_prefix||'OpenOver7d' THEN 300
        WHEN v_prefix||'OpenOver30d' THEN 302
        WHEN v_prefix||'OpenOver90d' THEN 310
        WHEN v_prefix||'NewFindings30d' THEN 312
        WHEN v_prefix||'Resolved30d' THEN 320
        ELSE f.seqno END,
      seqnogrid=0, updated=NOW(), updatedby=100
    FROM ad_column c
    WHERE f.ad_tab_id=v_tab.ad_tab_id AND f.ad_column_id=c.ad_column_id
      AND c.columnname IN (
        v_prefix||'OpenOver7d',v_prefix||'OpenOver30d',v_prefix||'OpenOver90d',
        v_prefix||'NewFindings30d',v_prefix||'Resolved30d'
      );

    -- Legacy snapshot buckets stay available but collapsed.
    UPDATE ad_field f SET
      ad_fieldgroup_id=v_fg_breakdown,
      seqno=CASE c.columnname
        WHEN v_prefix||'Total' THEN 500
        WHEN v_prefix||'Compliant' THEN 502
        WHEN v_prefix||'Warning' THEN 510
        WHEN v_prefix||'NonCompliant' THEN 512
        WHEN v_prefix||'Critical' THEN 520
        WHEN v_prefix||'Overdue' THEN 522
        WHEN v_prefix||'AtRisk' THEN 530
        WHEN v_prefix||'OnTrack' THEN 532
        WHEN v_prefix||'Change' THEN 540
        ELSE f.seqno END,
      seqnogrid=0, updated=NOW(), updatedby=100
    FROM ad_column c
    WHERE f.ad_tab_id=v_tab.ad_tab_id AND f.ad_column_id=c.ad_column_id
      AND c.columnname ~ ('^'||v_prefix||'(Total|Compliant|Warning|NonCompliant|Critical|Overdue|AtRisk|OnTrack|Change)$');
  END LOOP;

  -- Organisation Audit lead page: every calculation pair gets a persistent explainer.
  SELECT ad_tab_id INTO v_lead_tab
  FROM ad_tab
  WHERE ad_tab_uu='23a02310-c0d4-4f01-8e15-000000000001';
  IF v_lead_tab IS NULL THEN
    RAISE EXCEPTION 'SAW025-39: Organisation Audit lead tab missing';
  END IF;

  UPDATE ad_field f SET
    ad_fieldgroup_id=CASE
      WHEN c.columnname='AbERP_RefreshCompliance' THEN v_fg_action
      ELSE v_fg_glance
    END,
    seqno=CASE c.columnname
      WHEN 'OverallScore' THEN 10
      WHEN 'OverallTrafficLight' THEN 12
      WHEN 'TotalItems' THEN 20
      WHEN 'TotalCompliant' THEN 22
      WHEN 'TotalWarning' THEN 30
      WHEN 'TotalNonCompliant' THEN 32
      WHEN 'TotalCritical' THEN 40
      WHEN 'LastRefreshed' THEN 42
      WHEN 'AbERP_RefreshCompliance' THEN 50
      ELSE f.seqno
    END,
    seqnogrid=0, updated=NOW(), updatedby=100
  FROM ad_column c
  WHERE f.ad_tab_id=v_lead_tab AND f.ad_column_id=c.ad_column_id
    AND c.columnname IN (
      'OverallScore','OverallTrafficLight','TotalItems','TotalCompliant',
      'TotalWarning','TotalNonCompliant','TotalCritical','LastRefreshed',
      'AbERP_RefreshCompliance'
    );

  v_col := pg_temp.saw025_explainer_column('LeadReadinessExplainer','lead_readiness');
  PERFORM pg_temp.saw025_explainer_field(
    v_lead_tab,v_col,v_fg_glance,14,2,'lead_readiness');
  v_col := pg_temp.saw025_explainer_column('LeadItemsExplainer','lead_items');
  PERFORM pg_temp.saw025_explainer_field(
    v_lead_tab,v_col,v_fg_glance,24,2,'lead_items');
  v_col := pg_temp.saw025_explainer_column('LeadExceptionsExplainer','lead_exceptions');
  PERFORM pg_temp.saw025_explainer_field(
    v_lead_tab,v_col,v_fg_glance,34,2,'lead_exceptions');
  v_col := pg_temp.saw025_explainer_column('LeadRefreshExplainer','lead_refresh');
  PERFORM pg_temp.saw025_explainer_field(
    v_lead_tab,v_col,v_fg_action,52,2,'lead_refresh');

  INSERT INTO ad_fieldgroup_trl (
    ad_fieldgroup_id, ad_language, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, name, istranslated
  )
  SELECT fg.ad_fieldgroup_id,l.ad_language,0,0,'Y',
         NOW(),100,NOW(),100,fg.name,'N'
  FROM ad_fieldgroup fg
  CROSS JOIN ad_language l
  WHERE fg.ad_fieldgroup_id IN (v_fg_glance,v_fg_action,v_fg_trends,v_fg_breakdown)
    AND l.issystemlanguage='Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_fieldgroup_trl t
      WHERE t.ad_fieldgroup_id=fg.ad_fieldgroup_id
        AND t.ad_language=l.ad_language
    );

  UPDATE ad_fieldgroup_trl t SET name=fg.name, updated=NOW(), updatedby=100
  FROM ad_fieldgroup fg
  WHERE t.ad_fieldgroup_id=fg.ad_fieldgroup_id
    AND fg.ad_fieldgroup_id IN (v_fg_glance,v_fg_action,v_fg_trends,v_fg_breakdown);
END $$;

SELECT 'SAW025-39 progressive category UX + explainers installed' AS status;
