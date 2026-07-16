-- SAW025-37 — Expanded KPI summaries on all Organisation Audit category tabs
-- Uses virtual AD columns so values are live and preserve the current two-column UX.
SET search_path TO adempiere;

-- Keep ORDER BY inside database functions: iDempiere's ColumnSQL parser treats
-- any raw ORDER BY as the outer query's sort clause and truncates the select.
CREATE OR REPLACE FUNCTION aberp_compliance_top_finding(
  p_client_id NUMERIC, p_category CHAR
) RETURNS TEXT AS $$
  SELECT r.name
  FROM aberp_complianceresult cr
  JOIN aberp_compliancerule r
    ON r.aberp_compliancerule_id=cr.aberp_compliancerule_id
  WHERE cr.ad_client_id=p_client_id
    AND r.compliancecategory=p_category
    AND cr.isactive='Y' AND cr.isresolved='N'
  GROUP BY r.name
  ORDER BY COUNT(*) DESC,r.name
  LIMIT 1
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION aberp_compliance_incident_median_days(
  p_client_id NUMERIC
) RETURNS NUMERIC AS $$
  SELECT COALESCE(
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
      (ORDER BY CURRENT_DATE-x.created::date)::numeric,1),0)
  FROM aberp_incident x
  LEFT JOIN aberp_incident_status st
    ON st.aberp_incident_status_id=x.aberp_incident_status_id
  WHERE x.ad_client_id=p_client_id
    AND x.isactive='Y' AND COALESCE(st.isclosed,'N')='N'
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION aberp_compliance_incident_oldest_days(
  p_client_id NUMERIC
) RETURNS NUMERIC AS $$
  SELECT COALESCE(MAX((CURRENT_DATE - x.created::date)), 0)::numeric
  FROM aberp_incident x
  LEFT JOIN aberp_incident_status st
    ON st.aberp_incident_status_id=x.aberp_incident_status_id
  WHERE x.ad_client_id=p_client_id
    AND x.isactive='Y' AND COALESCE(st.isclosed,'N')='N'
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION aberp_compliance_incident_kpi(
  p_client_id NUMERIC, p_metric TEXT
) RETURNS NUMERIC AS $$
  SELECT CASE p_metric
    WHEN 'closed_30d' THEN (
      SELECT COUNT(*)::numeric FROM aberp_incident x
      JOIN aberp_incident_status st
        ON st.aberp_incident_status_id=x.aberp_incident_status_id
      WHERE x.ad_client_id=p_client_id
        AND st.isclosed='Y' AND x.updated::date>=CURRENT_DATE-30)
    WHEN 'overdue' THEN (
      SELECT COUNT(*)::numeric FROM aberp_incident x
      LEFT JOIN aberp_incident_status st
        ON st.aberp_incident_status_id=x.aberp_incident_status_id
      WHERE x.ad_client_id=p_client_id
        AND x.isactive='Y' AND COALESCE(st.isclosed,'N')='N'
        AND x.aberp_duedate::date<CURRENT_DATE)
    WHEN 'actions' THEN (
      SELECT COUNT(*)::numeric FROM hco_incident_actions a
      WHERE a.ad_client_id=p_client_id
        AND a.isactive='Y' AND COALESCE(a.iscomplete,'N')='N')
    WHEN 'reportable' THEN (
      SELECT COUNT(*)::numeric FROM aberp_incident x
      LEFT JOIN aberp_incident_status st
        ON st.aberp_incident_status_id=x.aberp_incident_status_id
      WHERE x.ad_client_id=p_client_id
        AND x.isactive='Y' AND COALESCE(st.isclosed,'N')='N'
        AND COALESCE(x.aberp_isreportableincident,'N')='Y')
    ELSE 0::numeric
  END
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION aberp_compliance_finding_kpi(
  p_client_id NUMERIC, p_category CHAR, p_metric TEXT
) RETURNS NUMERIC AS $$
  SELECT CASE p_metric
    WHEN 'open' THEN COUNT(*) FILTER (WHERE cr.isactive='Y' AND cr.isresolved='N')
    WHEN 'critical' THEN COUNT(*) FILTER (WHERE cr.isactive='Y' AND cr.isresolved='N' AND cr.severity='CRIT')
    WHEN 'over7' THEN COUNT(*) FILTER (WHERE cr.isactive='Y' AND cr.isresolved='N' AND cr.datedetected::date<CURRENT_DATE-7)
    WHEN 'over30' THEN COUNT(*) FILTER (WHERE cr.isactive='Y' AND cr.isresolved='N' AND cr.datedetected::date<CURRENT_DATE-30)
    WHEN 'over90' THEN COUNT(*) FILTER (WHERE cr.isactive='Y' AND cr.isresolved='N' AND cr.datedetected::date<CURRENT_DATE-90)
    WHEN 'new30' THEN COUNT(*) FILTER (WHERE cr.datedetected::date>=CURRENT_DATE-30)
    WHEN 'resolved30' THEN COUNT(*) FILTER (WHERE cr.resolveddate::date>=CURRENT_DATE-30)
    ELSE 0::numeric
  END
  FROM aberp_complianceresult cr
  JOIN aberp_compliancerule r
    ON r.aberp_compliancerule_id=cr.aberp_compliancerule_id
  WHERE cr.ad_client_id=p_client_id
    AND r.compliancecategory=p_category
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION aberp_compliance_category_readiness(
  p_client_id NUMERIC, p_category CHAR
) RETURNS NUMERIC AS $$
  SELECT COALESCE(MAX(s.auditreadinessscore),0)
  FROM aberp_compliancesnapshot s
  WHERE s.ad_client_id=p_client_id
    AND s.compliancecategory=p_category
    AND s.isactive='Y' AND s.aberp_support_location_id IS NULL
    AND s.snapshotdate=(
      SELECT MAX(s2.snapshotdate) FROM aberp_compliancesnapshot s2
      WHERE s2.ad_client_id=s.ad_client_id AND s2.isactive='Y'
        AND s2.aberp_support_location_id IS NULL)
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION aberp_compliance_category_traffic(
  p_client_id NUMERIC, p_category CHAR
) RETURNS TEXT AS $$
  SELECT COALESCE(MAX(s.trafficlight),'G')
  FROM aberp_compliancesnapshot s
  WHERE s.ad_client_id=p_client_id
    AND s.compliancecategory=p_category
    AND s.isactive='Y' AND s.aberp_support_location_id IS NULL
    AND s.snapshotdate=(
      SELECT MAX(s2.snapshotdate) FROM aberp_compliancesnapshot s2
      WHERE s2.ad_client_id=s.ad_client_id AND s2.isactive='Y'
        AND s2.aberp_support_location_id IS NULL)
$$ LANGUAGE sql STABLE;

-- Nested NOT EXISTS / sub-select ColumnSQL is mangled by iDempiere's virtual
-- column parser ("Could not remove", COALESCE type errors). Keep that logic here.
CREATE OR REPLACE FUNCTION aberp_compliance_client_no_support_30d(
  p_client_id NUMERIC
) RETURNS NUMERIC AS $$
  SELECT COUNT(*)::numeric
  FROM c_bpartner bp
  WHERE bp.ad_client_id=p_client_id
    AND bp.isactive='Y'
    AND COALESCE(bp.aberp_issupport_receiver,'N')='Y'
    AND NOT EXISTS (
      SELECT 1
      FROM aberp_rostered_shiftreceiver sr
      JOIN aberp_rostered_shift s
        ON s.aberp_rostered_shift_id=sr.aberp_rostered_shift_id
      WHERE sr.c_bpartner_id=bp.c_bpartner_id
        AND sr.isactive='Y' AND s.isactive='Y'
        AND s.startdate::date BETWEEN CURRENT_DATE-30 AND CURRENT_DATE
    )
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION aberp_compliance_client_kpi(
  p_client_id NUMERIC, p_metric TEXT
) RETURNS NUMERIC AS $$
  SELECT CASE p_metric
    WHEN 'risk_overdue' THEN (
      SELECT COUNT(*)::numeric FROM aberp_risks x
      WHERE x.ad_client_id=p_client_id AND x.isactive='Y' AND x.validto::date<CURRENT_DATE)
    WHEN 'risk_due_30' THEN (
      SELECT COUNT(*)::numeric FROM aberp_risks x
      WHERE x.ad_client_id=p_client_id AND x.isactive='Y'
        AND x.validto::date BETWEEN CURRENT_DATE AND CURRENT_DATE+30)
    WHEN 'plan_due_30' THEN (
      SELECT COUNT(*)::numeric FROM aberp_plans_assessment pa
      WHERE pa.ad_client_id=p_client_id AND pa.isactive='Y'
        AND pa.aberp_review_date::date BETWEEN CURRENT_DATE AND CURRENT_DATE+30)
    WHEN 'plans_expired' THEN (
      SELECT COUNT(*)::numeric FROM aberp_plans_assessment pa
      WHERE pa.ad_client_id=p_client_id AND pa.isactive='Y' AND pa.validto::date<CURRENT_DATE)
    WHEN 'assessments_current' THEN (
      SELECT COUNT(*)::numeric FROM aberp_plans_assessment pa
      WHERE pa.ad_client_id=p_client_id AND pa.isactive='Y'
        AND (pa.validto IS NULL OR pa.validto::date>=CURRENT_DATE))
    ELSE 0::numeric
  END
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION aberp_compliance_doc_kpi(
  p_client_id NUMERIC, p_metric TEXT
) RETURNS NUMERIC AS $$
  SELECT CASE p_metric
    WHEN 'expired' THEN (
      SELECT COUNT(*)::numeric FROM aberp_credentialassignment ca
      WHERE ca.ad_client_id=p_client_id AND ca.isactive='Y' AND ca.aberp_expirydate::date<CURRENT_DATE)
    WHEN 'due_30' THEN (
      SELECT COUNT(*)::numeric FROM aberp_credentialassignment ca
      WHERE ca.ad_client_id=p_client_id AND ca.isactive='Y'
        AND ca.aberp_expirydate::date BETWEEN CURRENT_DATE AND CURRENT_DATE+30)
    WHEN 'current' THEN (
      SELECT COUNT(*)::numeric FROM aberp_credentialassignment ca
      WHERE ca.ad_client_id=p_client_id AND ca.isactive='Y'
        AND (ca.aberp_expirydate IS NULL OR ca.aberp_expirydate::date>=CURRENT_DATE))
    WHEN 'current_pct' THEN (
      SELECT COALESCE(ROUND(100.0*COUNT(*) FILTER (
        WHERE ca.aberp_expirydate IS NULL OR ca.aberp_expirydate::date>=CURRENT_DATE
      )/NULLIF(COUNT(*),0),1),0)
      FROM aberp_credentialassignment ca
      WHERE ca.ad_client_id=p_client_id AND ca.isactive='Y')
    WHEN 'onboarding_expired' THEN (
      SELECT COUNT(*)::numeric FROM aberp_credentialassignment ca
      JOIN aberp_credentials cr ON cr.aberp_credentials_id=ca.aberp_credentials_id
      LEFT JOIN aberp_credentialscategory cc
        ON cc.aberp_credentialscategory_id=cr.aberp_credentialscategory_id
      WHERE ca.ad_client_id=p_client_id AND ca.isactive='Y'
        AND ca.aberp_expirydate::date<CURRENT_DATE
        AND cc.name ILIKE '%Onboarding Documentation%')
    WHEN 'added_90' THEN (
      SELECT COUNT(*)::numeric FROM aberp_credentialassignment ca
      WHERE ca.ad_client_id=p_client_id AND ca.isactive='Y' AND ca.created::date>CURRENT_DATE-90)
    WHEN 'expired_90' THEN (
      SELECT COUNT(*)::numeric FROM aberp_credentialassignment ca
      WHERE ca.ad_client_id=p_client_id
        AND ca.aberp_expirydate::date BETWEEN CURRENT_DATE-90 AND CURRENT_DATE-1)
    WHEN 'missing_evidence' THEN (
      SELECT COUNT(*)::numeric FROM aberp_complianceresult cr
      JOIN aberp_compliancerule rr ON rr.aberp_compliancerule_id=cr.aberp_compliancerule_id
      WHERE cr.ad_client_id=p_client_id AND cr.isactive='Y' AND cr.isresolved='N'
        AND rr.compliancecategory='D')
    ELSE 0::numeric
  END
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION aberp_compliance_employee_kpi(
  p_client_id NUMERIC, p_metric TEXT
) RETURNS NUMERIC AS $$
  SELECT CASE p_metric
    WHEN 'screening_expired' THEN (
      SELECT COUNT(*)::numeric FROM aberp_credentialassignment ca
      JOIN aberp_credentials cr ON cr.aberp_credentials_id=ca.aberp_credentials_id
      WHERE ca.ad_client_id=p_client_id AND ca.isactive='Y'
        AND ca.aberp_expirydate::date<CURRENT_DATE
        AND (cr.name ILIKE '%Worker Screening%' OR cr.name ILIKE '%Working with Child%'))
    WHEN 'screening_due_30' THEN (
      SELECT COUNT(*)::numeric FROM aberp_credentialassignment ca
      JOIN aberp_credentials cr ON cr.aberp_credentials_id=ca.aberp_credentials_id
      WHERE ca.ad_client_id=p_client_id AND ca.isactive='Y'
        AND ca.aberp_expirydate::date BETWEEN CURRENT_DATE AND CURRENT_DATE+30
        AND (cr.name ILIKE '%Worker Screening%' OR cr.name ILIKE '%Working with Child%'))
    WHEN 'cred_current_pct' THEN (
      SELECT COALESCE(ROUND(100.0*COUNT(*) FILTER (
        WHERE ca.aberp_expirydate IS NULL OR ca.aberp_expirydate::date>=CURRENT_DATE
      )/NULLIF(COUNT(*),0),1),0)
      FROM aberp_credentialassignment ca
      WHERE ca.ad_client_id=p_client_id AND ca.isactive='Y')
    WHEN 'unavailable_today' THEN (
      SELECT COUNT(DISTINCT x.staff_id)::numeric FROM (
        SELECT ou.aberp_user_contact_id AS staff_id
        FROM aberp_ongoingunavailability ou
        WHERE ou.ad_client_id=p_client_id AND ou.isactive='Y'
          AND COALESCE(ou.aberp_approverstatus,'AP')='AP'
          AND CURRENT_DATE BETWEEN ou.startdate::date AND COALESCE(ou.enddate::date,CURRENT_DATE)
        UNION
        SELECT ul.aberp_user_contact_id
        FROM aberp_unavailability_leave ul
        WHERE ul.ad_client_id=p_client_id AND ul.isactive='Y'
          AND COALESCE(ul.aberp_approverstatus,'AP')='AP'
          AND CURRENT_DATE BETWEEN ul.startdate::date AND COALESCE(ul.enddate::date,CURRENT_DATE)
      ) x)
    WHEN 'rostered_period' THEN (
      SELECT COUNT(DISTINCT ss.aberp_user_contact_id)::numeric
      FROM aberp_rostered_shiftstaff ss
      JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id=ss.aberp_rostered_shift_id
      JOIN aberp_pr_period p ON p.ad_client_id=s.ad_client_id AND p.isactive='Y'
        AND CURRENT_DATE BETWEEN p.startdate::date AND p.enddate::date
      WHERE s.ad_client_id=p_client_id AND s.isactive='Y' AND ss.isactive='Y'
        AND s.startdate::date BETWEEN p.startdate::date AND p.enddate::date)
    ELSE 0::numeric
  END
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION aberp_compliance_employee_new_starter_missing_docs(
  p_client_id NUMERIC
) RETURNS NUMERIC AS $$
  SELECT COUNT(*)::numeric
  FROM ad_user u
  JOIN c_bpartner bp ON bp.c_bpartner_id=u.c_bpartner_id
  WHERE u.ad_client_id=p_client_id
    AND u.isactive='Y' AND bp.isactive='Y' AND bp.isemployee='Y'
    AND u.created::date>CURRENT_DATE-90
    AND NOT EXISTS (
      SELECT 1
      FROM aberp_credentialassignment ca
      JOIN aberp_credentials cr
        ON cr.aberp_credentials_id=ca.aberp_credentials_id
      LEFT JOIN aberp_credentialscategory cc
        ON cc.aberp_credentialscategory_id=cr.aberp_credentialscategory_id
      WHERE ca.ad_client_id=u.ad_client_id
        AND ca.isactive='Y'
        AND ca.aberp_user_contact_id=u.ad_user_id
        AND cc.name ILIKE '%Onboarding Documentation%'
    )
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION aberp_compliance_roster_kpi(
  p_client_id NUMERIC, p_metric TEXT
) RETURNS NUMERIC AS $$
DECLARE
  v_from TEXT;
  v_sql TEXT;
  v_val NUMERIC;
BEGIN
  IF p_metric IN ('filled','unfilled','partial','fill_pct','cancelled') THEN
    v_from :=
      ' FROM aberp_rostered_shift s'
      ||' JOIN aberp_pr_period p ON p.ad_client_id=s.ad_client_id AND p.isactive=''Y'''
      ||' AND CURRENT_DATE BETWEEN p.startdate::date AND p.enddate::date'
      ||' WHERE s.ad_client_id=$1 AND s.isactive=''Y'''
      ||' AND COALESCE(s.aberp_isshiftrosteredtemplate,''N'')=''N'''
      ||' AND s.startdate::date BETWEEN p.startdate::date AND p.enddate::date';
  ELSIF p_metric = 'cov7' THEN
    v_from :=
      ' FROM aberp_rostered_shift s'
      ||' WHERE s.ad_client_id=$1 AND s.isactive=''Y'''
      ||' AND COALESCE(s.aberp_isshiftrosteredtemplate,''N'')=''N'''
      ||' AND s.startdate::date BETWEEN CURRENT_DATE AND CURRENT_DATE+7';
  ELSIF p_metric = 'cov14' THEN
    v_from :=
      ' FROM aberp_rostered_shift s'
      ||' WHERE s.ad_client_id=$1 AND s.isactive=''Y'''
      ||' AND COALESCE(s.aberp_isshiftrosteredtemplate,''N'')=''N'''
      ||' AND s.startdate::date BETWEEN CURRENT_DATE AND CURRENT_DATE+14';
  ELSIF p_metric = 'agency' THEN
    EXECUTE
      'SELECT COUNT(*)::numeric FROM aberp_rostered_shiftstaff ss'
      ||' JOIN ad_user u ON u.ad_user_id=ss.aberp_user_contact_id'
      ||' JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id=ss.aberp_rostered_shift_id'
      ||' JOIN aberp_pr_period p ON p.ad_client_id=s.ad_client_id AND p.isactive=''Y'''
      ||' AND CURRENT_DATE BETWEEN p.startdate::date AND p.enddate::date'
      ||' WHERE s.ad_client_id=$1 AND s.isactive=''Y'' AND ss.isactive=''Y'''
      ||' AND COALESCE(u.aberp_isagencystaff,''N'')=''Y'''
      ||' AND s.startdate::date BETWEEN p.startdate::date AND p.enddate::date'
      INTO v_val USING p_client_id;
    RETURN COALESCE(v_val,0);
  ELSIF p_metric = 'employee' THEN
    EXECUTE
      'SELECT COUNT(*)::numeric FROM aberp_rostered_shiftstaff ss'
      ||' JOIN ad_user u ON u.ad_user_id=ss.aberp_user_contact_id'
      ||' JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id=ss.aberp_rostered_shift_id'
      ||' JOIN aberp_pr_period p ON p.ad_client_id=s.ad_client_id AND p.isactive=''Y'''
      ||' AND CURRENT_DATE BETWEEN p.startdate::date AND p.enddate::date'
      ||' WHERE s.ad_client_id=$1 AND s.isactive=''Y'' AND ss.isactive=''Y'''
      ||' AND COALESCE(u.aberp_isagencystaff,''N'')=''N'''
      ||' AND s.startdate::date BETWEEN p.startdate::date AND p.enddate::date'
      INTO v_val USING p_client_id;
    RETURN COALESCE(v_val,0);
  ELSIF p_metric = 'missing_cred' THEN
    SELECT COUNT(*)::numeric INTO v_val
    FROM aberp_complianceresult cr
    JOIN aberp_compliancerule rr
      ON rr.aberp_compliancerule_id=cr.aberp_compliancerule_id
    WHERE cr.ad_client_id=p_client_id
      AND cr.isactive='Y' AND cr.isresolved='N'
      AND rr.aberp_compliancerule_uu='23a02358-c0d4-4f01-8e15-000000000001';
    RETURN COALESCE(v_val,0);
  ELSE
    RAISE EXCEPTION 'SAW025: unknown roster metric %', p_metric;
  END IF;

  IF p_metric = 'cancelled' THEN
    EXECUTE 'SELECT COUNT(*)::numeric'||v_from||' AND COALESCE(s.iscancelled,''N'')=''Y'''
      INTO v_val USING p_client_id;
    RETURN COALESCE(v_val,0);
  END IF;

  v_sql :=
    'SELECT COALESCE('
    || CASE
         WHEN p_metric IN ('fill_pct','cov7','cov14') THEN
           'ROUND(100.0*COUNT(*) FILTER (WHERE q.assigned>=q.req)/NULLIF(COUNT(*),0),1)'
         WHEN p_metric='filled' THEN 'COUNT(*) FILTER (WHERE q.assigned>=q.req)'
         WHEN p_metric='unfilled' THEN 'COUNT(*) FILTER (WHERE q.assigned=0)'
         WHEN p_metric='partial' THEN 'COUNT(*) FILTER (WHERE q.assigned>0 AND q.assigned<q.req)'
       END
    ||',0) FROM (SELECT s.aberp_rostered_shift_id,'
    ||' GREATEST(COALESCE(s.aberp_no_of_staff,1),1) req,'
    ||' (SELECT COUNT(*) FROM aberp_rostered_shiftstaff ss'
    ||'  WHERE ss.aberp_rostered_shift_id=s.aberp_rostered_shift_id'
    ||'    AND ss.isactive=''Y'' AND COALESCE(ss.aberp_user_contact_id,0)>0) assigned'
    ||v_from||') q';
  EXECUTE v_sql INTO v_val USING p_client_id;
  RETURN COALESCE(v_val,0);
END;
$$ LANGUAGE plpgsql STABLE;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw025_kpi_column(
  p_columnname TEXT, p_name TEXT, p_ref INTEGER, p_length INTEGER,
  p_columnsql TEXT, p_description TEXT
) RETURNS void AS $$
DECLARE
  v_table_id INTEGER;
  v_element_id INTEGER;
  v_column_id INTEGER;
  v_element_uu TEXT := '25a037e1-0000-4000-8000-' || substr(md5(p_columnname),1,12);
  v_column_uu TEXT := '25a037c1-0000-4000-8000-' || substr(md5(p_columnname),1,12);
BEGIN
  SELECT ad_table_id INTO v_table_id
  FROM ad_table WHERE tablename='AbERP_ComplianceDashboard';
  IF v_table_id IS NULL THEN
    RAISE EXCEPTION 'SAW025-37: AbERP_ComplianceDashboard table missing';
  END IF;

  SELECT ad_element_id INTO v_element_id
  FROM ad_element WHERE columnname=p_columnname LIMIT 1;
  IF v_element_id IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, description, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_Element' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100,
      p_columnname,'Ab_ERP',p_name,p_name,p_description,v_element_uu
    ) RETURNING ad_element_id INTO v_element_id;
  ELSE
    UPDATE ad_element SET
      name=p_name, printname=p_name, description=p_description,
      entitytype='Ab_ERP', updated=NOW()
    WHERE ad_element_id=v_element_id;
  END IF;

  SELECT ad_column_id INTO v_column_id
  FROM ad_column
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
      p_name,p_description,p_description,1,'Ab_ERP',
      p_columnname,v_table_id,p_ref,p_length,
      'N','N','N','N','N',
      500,'N','N','N',
      p_columnsql,'N','N',
      'N','N',v_element_id,v_column_uu
    );
  ELSE
    UPDATE ad_column SET
      name=p_name, description=p_description, help=p_description,
      ad_reference_id=p_ref, fieldlength=p_length,
      columnsql=p_columnsql, isupdateable='N', ismandatory='N',
      entitytype='Ab_ERP', updated=NOW()
    WHERE ad_column_id=v_column_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw025_kpi_field(
  p_tab_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_seqno INTEGER, p_sameline CHAR, p_description TEXT
) RETURNS void AS $$
DECLARE
  v_tab_id INTEGER;
  v_table_id INTEGER;
  v_column_id INTEGER;
  v_field_id INTEGER;
  v_field_uu TEXT := '25a037f1-0000-4000-8000-' || substr(md5(p_tab_uu||p_columnname),1,12);
BEGIN
  SELECT ad_tab_id, ad_table_id INTO v_tab_id, v_table_id
  FROM ad_tab WHERE ad_tab_uu=p_tab_uu;
  IF v_tab_id IS NULL THEN
    RAISE EXCEPTION 'SAW025-37: tab missing %',p_tab_uu;
  END IF;
  SELECT ad_column_id INTO v_column_id
  FROM ad_column WHERE ad_table_id=v_table_id AND columnname=p_columnname;
  IF v_column_id IS NULL THEN
    RAISE EXCEPTION 'SAW025-37: column missing %',p_columnname;
  END IF;

  SELECT ad_field_id INTO v_field_id
  FROM ad_field WHERE ad_tab_id=v_tab_id AND ad_column_id=v_column_id;
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
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name='AD_Field' AND istableid='Y')::integer,'N'),
      0,0,'Y',NOW(),100,NOW(),100,
      p_name,p_description,p_description,'N',
      v_tab_id,v_column_id,'Y',CASE WHEN (SELECT ad_reference_id FROM ad_column WHERE ad_column_id=v_column_id)=10 THEN 40 ELSE 14 END,
      'Y',p_seqno,p_sameline,'N','N',
      'N','Ab_ERP','Y',p_seqno,
      1,2,1,v_field_uu
    );
  ELSE
    UPDATE ad_field SET
      name=p_name, description=p_description, help=p_description,
      isdisplayed='Y', isreadonly='Y', seqno=p_seqno,
      issameline=p_sameline, isdisplayedgrid='Y', seqnogrid=p_seqno,
      updated=NOW()
    WHERE ad_field_id=v_field_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw025_add_kpi(
  p_tab_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_ref INTEGER, p_length INTEGER, p_columnsql TEXT,
  p_seqno INTEGER, p_sameline CHAR, p_description TEXT
) RETURNS void AS $$
BEGIN
  PERFORM pg_temp.saw025_kpi_column(
    p_columnname,p_name,p_ref,p_length,p_columnsql,p_description);
  PERFORM pg_temp.saw025_kpi_field(
    p_tab_uu,p_columnname,p_name,p_seqno,p_sameline,p_description);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw025_shared_kpis(
  p_tab_uu TEXT, p_prefix TEXT, p_category TEXT
) RETURNS void AS $$
DECLARE
  v_client TEXT := 'AbERP_ComplianceDashboard.AD_Client_ID';
BEGIN
  PERFORM pg_temp.saw025_add_kpi(p_tab_uu,p_prefix||'ReadinessScore','Readiness Score',
    22,10,
    'aberp_compliance_category_readiness('||v_client||','''||p_category||''')',
    10,'N','Latest category audit-readiness score.');

  PERFORM pg_temp.saw025_add_kpi(p_tab_uu,p_prefix||'TrafficLight','Status',
    10,2,
    'aberp_compliance_category_traffic('||v_client||','''||p_category||''')',
    12,'Y','Latest category traffic light (R/A/G).');

  PERFORM pg_temp.saw025_add_kpi(p_tab_uu,p_prefix||'OpenFindings','Open Findings',
    11,10,'aberp_compliance_finding_kpi('||v_client||','''||p_category||''',''open'')',
    20,'N','Current unresolved findings in this category.');
  PERFORM pg_temp.saw025_add_kpi(p_tab_uu,p_prefix||'CriticalOpen','Critical Open',
    11,10,'aberp_compliance_finding_kpi('||v_client||','''||p_category||''',''critical'')',
    22,'Y','Current unresolved critical findings.');

  PERFORM pg_temp.saw025_add_kpi(p_tab_uu,p_prefix||'OpenOver7d','Open > 7 days',
    11,10,'aberp_compliance_finding_kpi('||v_client||','''||p_category||''',''over7'')',
    30,'N','Unresolved findings detected more than 7 days ago.');
  PERFORM pg_temp.saw025_add_kpi(p_tab_uu,p_prefix||'OpenOver30d','Open > 30 days',
    11,10,'aberp_compliance_finding_kpi('||v_client||','''||p_category||''',''over30'')',
    32,'Y','Unresolved findings detected more than 30 days ago.');
  PERFORM pg_temp.saw025_add_kpi(p_tab_uu,p_prefix||'OpenOver90d','Open > 90 days',
    11,10,'aberp_compliance_finding_kpi('||v_client||','''||p_category||''',''over90'')',
    40,'N','Unresolved findings detected more than 90 days ago.');
  PERFORM pg_temp.saw025_add_kpi(p_tab_uu,p_prefix||'NewFindings30d','New Findings (30d)',
    11,10,'aberp_compliance_finding_kpi('||v_client||','''||p_category||''',''new30'')',
    42,'Y','Findings detected during the last 30 days.');

  PERFORM pg_temp.saw025_add_kpi(p_tab_uu,p_prefix||'Resolved30d','Resolved (30d)',
    11,10,'aberp_compliance_finding_kpi('||v_client||','''||p_category||''',''resolved30'')',
    50,'N','Findings resolved during the last 30 days.');
  PERFORM pg_temp.saw025_add_kpi(p_tab_uu,p_prefix||'TopFinding','Top Finding',
    10,120,
    'COALESCE(aberp_compliance_top_finding('||v_client||','''||p_category||'''),''—'')',
    52,'Y','Most frequent current unresolved finding type.');
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  e CONSTANT TEXT := '23a02311-c0d4-4f01-8e15-000000000001';
  c CONSTANT TEXT := '23a02312-c0d4-4f01-8e15-000000000001';
  i CONSTANT TEXT := '23a02313-c0d4-4f01-8e15-000000000001';
  r CONSTANT TEXT := '23a02314-c0d4-4f01-8e15-000000000001';
  d CONSTANT TEXT := '23a02315-c0d4-4f01-8e15-000000000001';
  cl CONSTANT TEXT := 'AbERP_ComplianceDashboard.AD_Client_ID';
  shift_base TEXT :=
    ' FROM AbERP_Rostered_Shift s JOIN AbERP_PR_Period p ON p.AD_Client_ID=s.AD_Client_ID'
    ||' AND p.IsActive=''Y'' AND CURRENT_DATE BETWEEN p.StartDate::date AND p.EndDate::date'
    ||' WHERE s.AD_Client_ID='||cl||' AND s.IsActive=''Y'''
    ||' AND COALESCE(s.AbERP_IsShiftRosteredTemplate,''N'')=''N'''
    ||' AND s.StartDate::date BETWEEN p.StartDate::date AND p.EndDate::date';
BEGIN
  -- Put legacy compliance-bucket fields below the expanded summary.
  UPDATE ad_field f SET
    seqno=200+COALESCE(f.seqno,0), seqnogrid=200+COALESCE(f.seqnogrid,f.seqno,0), updated=NOW()
  WHERE f.ad_tab_id IN (SELECT ad_tab_id FROM ad_tab WHERE ad_tab_uu IN (e,c,i,r,d))
    AND f.ad_column_id IN (
      SELECT ad_column_id FROM ad_column
      WHERE ad_table_id=(SELECT ad_table_id FROM ad_table WHERE tablename='AbERP_ComplianceDashboard')
        AND (columnname ~ '^(Employee|Client|Incident|Roster|Doc)(Total|Compliant|Warning|NonCompliant|Critical|Overdue|AtRisk|OnTrack|Change)$')
    )
    AND COALESCE(f.seqno,0)<200;

  -- The old Change field compares refreshes, not 90 days.
  UPDATE ad_field f SET name='Finding Count Change', updated=NOW()
  WHERE f.ad_tab_id IN (SELECT ad_tab_id FROM ad_tab WHERE ad_tab_uu IN (e,c,i,r,d))
    AND f.ad_column_id IN (
      SELECT ad_column_id FROM ad_column
      WHERE ad_table_id=(SELECT ad_table_id FROM ad_table WHERE tablename='AbERP_ComplianceDashboard')
        AND columnname IN ('EmployeeChange','ClientChange','IncidentChange','RosterChange','DocChange')
    );

  PERFORM pg_temp.saw025_shared_kpis(e,'Employee','W');
  PERFORM pg_temp.saw025_shared_kpis(c,'Client','P');
  PERFORM pg_temp.saw025_shared_kpis(i,'Incident','I');
  PERFORM pg_temp.saw025_shared_kpis(r,'Roster','R');
  PERFORM pg_temp.saw025_shared_kpis(d,'Doc','D');

  -- Employee
  PERFORM pg_temp.saw025_add_kpi(e,'EmployeeScreeningExpired','Screening Expired',11,10,
    'aberp_compliance_employee_kpi('||cl||',''screening_expired'')',
    60,'N','Expired worker screening or working-with-children credentials.');
  PERFORM pg_temp.saw025_add_kpi(e,'EmployeeScreeningDue30','Screening Due (30d)',11,10,
    'aberp_compliance_employee_kpi('||cl||',''screening_due_30'')',
    62,'Y','Worker screening or working-with-children credentials due within 30 days.');
  PERFORM pg_temp.saw025_add_kpi(e,'EmployeeCredentialCurrentPct','Credentials Current %',22,10,
    'aberp_compliance_employee_kpi('||cl||',''cred_current_pct'')',
    70,'N','Percentage of active credential assignments not expired.');
  PERFORM pg_temp.saw025_add_kpi(e,'EmployeeNewStarterMissingDocs','New Starters Missing Docs',11,10,
    'aberp_compliance_employee_new_starter_missing_docs('||cl||')',
    72,'Y','Active employees created in the last 90 days with no active onboarding-document assignment.');
  PERFORM pg_temp.saw025_add_kpi(e,'EmployeeUnavailableToday','Unavailable Today',11,10,
    'aberp_compliance_employee_kpi('||cl||',''unavailable_today'')',
    80,'N','Distinct approved staff unavailable today.');
  PERFORM pg_temp.saw025_add_kpi(e,'EmployeeRosteredThisPeriod','Rostered This Period',11,10,
    'aberp_compliance_employee_kpi('||cl||',''rostered_period'')',
    82,'Y','Distinct staff allocated to shifts in the current pay period.');

  -- Client
  PERFORM pg_temp.saw025_add_kpi(c,'ClientRiskOverdue','Risk Reviews Overdue',11,10,
    'aberp_compliance_client_kpi('||cl||',''risk_overdue'')',
    60,'N','Active client risk records past Valid To.');
  PERFORM pg_temp.saw025_add_kpi(c,'ClientRiskDue30','Risk Reviews Due (30d)',11,10,
    'aberp_compliance_client_kpi('||cl||',''risk_due_30'')',
    62,'Y','Active client risk records due within 30 days.');
  PERFORM pg_temp.saw025_add_kpi(c,'ClientNoSupport30d','No Support (30d)',11,10,
    'aberp_compliance_client_no_support_30d('||cl||')',
    70,'N','Active support receivers with no rostered support in the last 30 days.');
  PERFORM pg_temp.saw025_add_kpi(c,'ClientPlanReviewDue30','Plan Reviews Due (30d)',11,10,
    'aberp_compliance_client_kpi('||cl||',''plan_due_30'')',
    72,'Y','Active plans or assessments with review date within 30 days.');
  PERFORM pg_temp.saw025_add_kpi(c,'ClientPlansExpired','Plans Expired',11,10,
    'aberp_compliance_client_kpi('||cl||',''plans_expired'')',
    80,'N','Active plans or assessments past Valid To.');
  PERFORM pg_temp.saw025_add_kpi(c,'ClientAssessmentsCurrent','Assessments Current',11,10,
    'aberp_compliance_client_kpi('||cl||',''assessments_current'')',
    82,'Y','Active plans or assessments not expired.');

  -- Incidents
  PERFORM pg_temp.saw025_add_kpi(i,'IncidentClosed30d','Closed (30d)',11,10,
    'aberp_compliance_incident_kpi('||cl||',''closed_30d'')',
    60,'N','Incidents moved to a closed status in the last 30 days.');
  PERFORM pg_temp.saw025_add_kpi(i,'IncidentOverdueInvestigations','Investigations Overdue',11,10,
    'aberp_compliance_incident_kpi('||cl||',''overdue'')',
    62,'Y','Open active incidents past their due date.');
  PERFORM pg_temp.saw025_add_kpi(i,'IncidentOutstandingActions','Outstanding Actions',11,10,
    'aberp_compliance_incident_kpi('||cl||',''actions'')',
    70,'N','Active incident actions not marked complete.');
  PERFORM pg_temp.saw025_add_kpi(i,'IncidentReportableOpen','Reportable Open',11,10,
    'aberp_compliance_incident_kpi('||cl||',''reportable'')',
    72,'Y','Open active incidents marked reportable.');
  PERFORM pg_temp.saw025_add_kpi(i,'IncidentMedianDaysOpen','Median Days Open',22,10,
    'aberp_compliance_incident_median_days('||cl||')',
    80,'N','Median age in days of open active incidents.');
  PERFORM pg_temp.saw025_add_kpi(i,'IncidentOldestDaysOpen','Oldest Open (days)',11,10,
    'aberp_compliance_incident_oldest_days('||cl||')',
    82,'Y','Age in days of the oldest open active incident.');

  -- Rostering (nested shift/staff subqueries live in aberp_compliance_roster_kpi)
  PERFORM pg_temp.saw025_add_kpi(r,'RosterFilledShifts','Filled Shifts',11,10,
    'aberp_compliance_roster_kpi('||cl||',''filled'')',
    60,'N','Current-period shifts with allocated staff meeting or exceeding required staff.');
  PERFORM pg_temp.saw025_add_kpi(r,'RosterUnfilledShifts','Unfilled Shifts',11,10,
    'aberp_compliance_roster_kpi('||cl||',''unfilled'')',
    62,'Y','Current-period shifts with no allocated staff.');
  PERFORM pg_temp.saw025_add_kpi(r,'RosterPartialShifts','Partially Filled',11,10,
    'aberp_compliance_roster_kpi('||cl||',''partial'')',
    70,'N','Current-period shifts with some but fewer than required staff.');
  PERFORM pg_temp.saw025_add_kpi(r,'RosterFillRatePct','Fill Rate %',22,10,
    'aberp_compliance_roster_kpi('||cl||',''fill_pct'')',
    72,'Y','Percentage of current-period shifts meeting required staffing.');
  PERFORM pg_temp.saw025_add_kpi(r,'RosterCoverage7dPct','Coverage (7d) %',22,10,
    'aberp_compliance_roster_kpi('||cl||',''cov7'')',
    80,'N','Percentage of shifts in the next 7 days meeting required staffing.');
  PERFORM pg_temp.saw025_add_kpi(r,'RosterCoverage14dPct','Coverage (14d) %',22,10,
    'aberp_compliance_roster_kpi('||cl||',''cov14'')',
    82,'Y','Percentage of shifts in the next 14 days meeting required staffing.');
  PERFORM pg_temp.saw025_add_kpi(r,'RosterMissingCredential','Missing Credential',11,10,
    'aberp_compliance_roster_kpi('||cl||',''missing_cred'')',
    90,'N','Open roster findings where allocated staff lack a required credential.');
  PERFORM pg_temp.saw025_add_kpi(r,'RosterAgencyAssignments','Agency Assignments',11,10,
    'aberp_compliance_roster_kpi('||cl||',''agency'')',
    92,'Y','Agency-staff allocations in the current pay period.');
  PERFORM pg_temp.saw025_add_kpi(r,'RosterCancelledShifts','Cancelled Shifts',11,10,
    'aberp_compliance_roster_kpi('||cl||',''cancelled'')',
    100,'N','Cancelled shifts in the current pay period.');
  PERFORM pg_temp.saw025_add_kpi(r,'RosterEmployeeAssignments','Employee Assignments',11,10,
    'aberp_compliance_roster_kpi('||cl||',''employee'')',
    102,'Y','Non-agency staff allocations in the current pay period.');

  -- Documentation
  PERFORM pg_temp.saw025_add_kpi(d,'DocExpiredDocuments','Expired Documents',11,10,
    'aberp_compliance_doc_kpi('||cl||',''expired'')',
    60,'N','Active credential/document assignments past expiry.');
  PERFORM pg_temp.saw025_add_kpi(d,'DocDue30','Due (30d)',11,10,
    'aberp_compliance_doc_kpi('||cl||',''due_30'')',
    62,'Y','Active credential/document assignments expiring within 30 days.');
  PERFORM pg_temp.saw025_add_kpi(d,'DocCurrentDocuments','Current Documents',11,10,
    'aberp_compliance_doc_kpi('||cl||',''current'')',
    70,'N','Active credential/document assignments not expired.');
  PERFORM pg_temp.saw025_add_kpi(d,'DocCurrentPct','Current %',22,10,
    'aberp_compliance_doc_kpi('||cl||',''current_pct'')',
    72,'Y','Percentage of active credential/document assignments not expired.');
  PERFORM pg_temp.saw025_add_kpi(d,'DocOnboardingExpired','Onboarding Expired',11,10,
    'aberp_compliance_doc_kpi('||cl||',''onboarding_expired'')',
    80,'N','Expired assignments in the Onboarding Documentation category.');
  PERFORM pg_temp.saw025_add_kpi(d,'DocAdded90d','Documents Added (90d)',11,10,
    'aberp_compliance_doc_kpi('||cl||',''added_90'')',
    82,'Y','Active credential/document assignments created in the last 90 days.');
  PERFORM pg_temp.saw025_add_kpi(d,'DocExpired90d','Expired in 90d',11,10,
    'aberp_compliance_doc_kpi('||cl||',''expired_90'')',
    90,'N','Credential/document assignments whose expiry date occurred in the last 90 days.');
  PERFORM pg_temp.saw025_add_kpi(d,'DocMissingEvidence','Missing Evidence',11,10,
    'aberp_compliance_doc_kpi('||cl||',''missing_evidence'')',
    92,'Y','Open documentation findings requiring evidence or renewal.');
END $$;

SELECT 'SAW025-37 category KPI expansion installed' AS status;
