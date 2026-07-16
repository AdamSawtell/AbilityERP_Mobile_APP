-- SAW025-38 — Rostering KPIs: current + next pay period only
-- Replaces calendar 7d/14d coverage; Rostering tab pair is Current Roster | Next Roster.
SET search_path TO adempiere;

CREATE OR REPLACE FUNCTION aberp_compliance_period_shifts(
  p_client_id NUMERIC, p_which TEXT
) RETURNS NUMERIC AS $$
  WITH cur AS (
    SELECT p.startdate::date AS s, p.enddate::date AS e
    FROM aberp_pr_period p
    WHERE p.ad_client_id=p_client_id AND p.isactive='Y'
      AND CURRENT_DATE BETWEEN p.startdate::date AND p.enddate::date
    ORDER BY p.startdate DESC
    LIMIT 1
  ),
  nxt AS (
    SELECT p.startdate::date AS s, p.enddate::date AS e
    FROM aberp_pr_period p
    WHERE p.ad_client_id=p_client_id AND p.isactive='Y'
      AND p.startdate::date > COALESCE((SELECT e FROM cur), CURRENT_DATE)
    ORDER BY p.startdate
    LIMIT 1
  ),
  bounds AS (
    SELECT s, e FROM cur WHERE p_which='current'
    UNION ALL
    SELECT s, e FROM nxt WHERE p_which='next'
  )
  SELECT COUNT(*)::numeric
  FROM aberp_rostered_shift s
  JOIN bounds b ON TRUE
  WHERE s.ad_client_id=p_client_id
    AND s.isactive='Y'
    AND COALESCE(s.aberp_isshiftrosteredtemplate,'N')='N'
    AND s.startdate::date BETWEEN b.s AND b.e
$$ LANGUAGE sql STABLE;

-- Replace prior 2-arg overload from SQL 37 with a 3-arg function (default = current).
DROP FUNCTION IF EXISTS aberp_compliance_roster_kpi(NUMERIC, TEXT);
DROP FUNCTION IF EXISTS aberp_compliance_roster_kpi(NUMERIC, TEXT, TEXT);

-- p_which: current | next
-- p_metric: filled | unfilled | partial | fill_pct | cancelled | agency | employee | missing_cred
CREATE OR REPLACE FUNCTION aberp_compliance_roster_kpi(
  p_client_id NUMERIC, p_metric TEXT, p_which TEXT DEFAULT 'current'
) RETURNS NUMERIC AS $$
DECLARE
  v_start DATE;
  v_end DATE;
  v_val NUMERIC;
  v_shift_table_id INTEGER;
BEGIN
  IF p_which = 'current' THEN
    SELECT p.startdate::date, p.enddate::date INTO v_start, v_end
    FROM aberp_pr_period p
    WHERE p.ad_client_id=p_client_id AND p.isactive='Y'
      AND CURRENT_DATE BETWEEN p.startdate::date AND p.enddate::date
    ORDER BY p.startdate DESC
    LIMIT 1;
  ELSIF p_which = 'next' THEN
    SELECT p.startdate::date, p.enddate::date INTO v_start, v_end
    FROM aberp_pr_period p
    WHERE p.ad_client_id=p_client_id AND p.isactive='Y'
      AND p.startdate::date > COALESCE((
            SELECT p2.enddate::date FROM aberp_pr_period p2
            WHERE p2.ad_client_id=p_client_id AND p2.isactive='Y'
              AND CURRENT_DATE BETWEEN p2.startdate::date AND p2.enddate::date
            ORDER BY p2.startdate DESC LIMIT 1
          ), CURRENT_DATE)
    ORDER BY p.startdate
    LIMIT 1;
  ELSE
    RAISE EXCEPTION 'SAW025: roster which must be current|next, got %', p_which;
  END IF;

  IF v_start IS NULL OR v_end IS NULL THEN
    RETURN 0;
  END IF;

  IF p_metric = 'agency' THEN
    SELECT COUNT(*)::numeric INTO v_val
    FROM aberp_rostered_shiftstaff ss
    JOIN ad_user u ON u.ad_user_id=ss.aberp_user_contact_id
    JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id=ss.aberp_rostered_shift_id
    WHERE s.ad_client_id=p_client_id AND s.isactive='Y' AND ss.isactive='Y'
      AND COALESCE(s.aberp_isshiftrosteredtemplate,'N')='N'
      AND COALESCE(u.aberp_isagencystaff,'N')='Y'
      AND s.startdate::date BETWEEN v_start AND v_end;
    RETURN COALESCE(v_val,0);
  END IF;

  IF p_metric = 'employee' THEN
    SELECT COUNT(*)::numeric INTO v_val
    FROM aberp_rostered_shiftstaff ss
    JOIN ad_user u ON u.ad_user_id=ss.aberp_user_contact_id
    JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id=ss.aberp_rostered_shift_id
    WHERE s.ad_client_id=p_client_id AND s.isactive='Y' AND ss.isactive='Y'
      AND COALESCE(s.aberp_isshiftrosteredtemplate,'N')='N'
      AND COALESCE(u.aberp_isagencystaff,'N')='N'
      AND s.startdate::date BETWEEN v_start AND v_end;
    RETURN COALESCE(v_val,0);
  END IF;

  IF p_metric = 'missing_cred' THEN
    SELECT ad_table_id INTO v_shift_table_id
    FROM ad_table WHERE tablename='AbERP_Rostered_Shift';

    SELECT COUNT(*)::numeric INTO v_val
    FROM aberp_complianceresult cr
    JOIN aberp_compliancerule rr
      ON rr.aberp_compliancerule_id=cr.aberp_compliancerule_id
    JOIN aberp_rostered_shift s
      ON s.aberp_rostered_shift_id=cr.record_id
     AND (v_shift_table_id IS NULL OR cr.ad_table_id=v_shift_table_id)
    WHERE cr.ad_client_id=p_client_id
      AND cr.isactive='Y' AND cr.isresolved='N'
      AND rr.aberp_compliancerule_uu='23a02358-c0d4-4f01-8e15-000000000001'
      AND s.isactive='Y'
      AND COALESCE(s.aberp_isshiftrosteredtemplate,'N')='N'
      AND s.startdate::date BETWEEN v_start AND v_end;
    RETURN COALESCE(v_val,0);
  END IF;

  IF p_metric = 'cancelled' THEN
    SELECT COUNT(*)::numeric INTO v_val
    FROM aberp_rostered_shift s
    WHERE s.ad_client_id=p_client_id AND s.isactive='Y'
      AND COALESCE(s.aberp_isshiftrosteredtemplate,'N')='N'
      AND COALESCE(s.iscancelled,'N')='Y'
      AND s.startdate::date BETWEEN v_start AND v_end;
    RETURN COALESCE(v_val,0);
  END IF;

  SELECT COALESCE(
    CASE p_metric
      WHEN 'fill_pct' THEN
        ROUND(100.0*COUNT(*) FILTER (WHERE q.assigned>=q.req)/NULLIF(COUNT(*),0),1)
      WHEN 'filled' THEN
        COUNT(*) FILTER (WHERE q.assigned>=q.req)
      WHEN 'unfilled' THEN
        COUNT(*) FILTER (WHERE q.assigned=0)
      WHEN 'partial' THEN
        COUNT(*) FILTER (WHERE q.assigned>0 AND q.assigned<q.req)
      ELSE NULL
    END, 0)
  INTO v_val
  FROM (
    SELECT s.aberp_rostered_shift_id,
           GREATEST(COALESCE(s.aberp_no_of_staff,1),1) AS req,
           (SELECT COUNT(*) FROM aberp_rostered_shiftstaff ss
            WHERE ss.aberp_rostered_shift_id=s.aberp_rostered_shift_id
              AND ss.isactive='Y' AND COALESCE(ss.aberp_user_contact_id,0)>0) AS assigned
    FROM aberp_rostered_shift s
    WHERE s.ad_client_id=p_client_id AND s.isactive='Y'
      AND COALESCE(s.aberp_isshiftrosteredtemplate,'N')='N'
      AND s.startdate::date BETWEEN v_start AND v_end
  ) q;

  IF v_val IS NULL THEN
    RAISE EXCEPTION 'SAW025: unknown roster metric %', p_metric;
  END IF;
  RETURN v_val;
END;
$$ LANGUAGE plpgsql STABLE;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw025_kpi_column_38(
  p_columnname TEXT, p_name TEXT, p_ref INTEGER, p_length INTEGER,
  p_columnsql TEXT, p_description TEXT
) RETURNS void AS $$
DECLARE
  v_table_id INTEGER;
  v_element_id INTEGER;
  v_column_id INTEGER;
  v_element_uu TEXT := '25a038e1-0000-4000-8000-' || substr(md5(p_columnname),1,12);
  v_column_uu TEXT := '25a038c1-0000-4000-8000-' || substr(md5(p_columnname),1,12);
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
      p_columnname,'Ab_ERP',p_name,p_name,p_description,v_element_uu
    ) RETURNING ad_element_id INTO v_element_id;
  ELSE
    UPDATE ad_element SET name=p_name, printname=p_name, description=p_description,
      entitytype='Ab_ERP', updated=NOW()
    WHERE ad_element_id=v_element_id;
  END IF;

  SELECT ad_column_id INTO v_column_id
  FROM ad_column WHERE ad_table_id=v_table_id AND columnname=p_columnname;
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

CREATE OR REPLACE FUNCTION pg_temp.saw025_kpi_field_38(
  p_tab_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_seqno INTEGER, p_sameline CHAR, p_description TEXT
) RETURNS void AS $$
DECLARE
  v_tab_id INTEGER;
  v_table_id INTEGER;
  v_column_id INTEGER;
  v_field_id INTEGER;
  v_field_uu TEXT := '25a038f1-0000-4000-8000-' || substr(md5(p_tab_uu||p_columnname),1,12);
BEGIN
  SELECT ad_tab_id INTO v_tab_id FROM ad_tab WHERE ad_tab_uu=p_tab_uu;
  SELECT ad_table_id INTO v_table_id FROM ad_table WHERE tablename='AbERP_ComplianceDashboard';
  SELECT ad_column_id INTO v_column_id FROM ad_column
  WHERE ad_table_id=v_table_id AND columnname=p_columnname;
  IF v_tab_id IS NULL OR v_column_id IS NULL THEN
    RAISE EXCEPTION 'SAW025-38: missing tab/column % / %', p_tab_uu, p_columnname;
  END IF;

  SELECT ad_field_id INTO v_field_id FROM ad_field
  WHERE ad_tab_id=v_tab_id AND ad_column_id=v_column_id;
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
      p_name,p_description,p_description,'N',
      v_tab_id,v_column_id,NULL,
      'Y',p_seqno,p_seqno,NULL,
      p_sameline,'N','N','Y',
      'Ab_ERP', CASE WHEN p_sameline='Y' THEN 4 ELSE 1 END, 2, 1,
      'Y',p_seqno,'N',v_field_uu
    );
  ELSE
    UPDATE ad_field SET
      name=p_name, description=p_description, help=p_description,
      isdisplayed='Y', isdisplayedgrid='Y', isreadonly='Y',
      seqno=p_seqno, seqnogrid=p_seqno, issameline=p_sameline,
      xposition=CASE WHEN p_sameline='Y' THEN 4 ELSE 1 END,
      columnspan=2, entitytype='Ab_ERP', updated=NOW()
    WHERE ad_field_id=v_field_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  r CONSTANT TEXT := '23a02314-c0d4-4f01-8e15-000000000001';
  cl CONSTANT TEXT := 'AbERP_ComplianceDashboard.AD_Client_ID';
  v_tab_id INTEGER;
  v_table_id INTEGER;
BEGIN
  SELECT ad_tab_id INTO v_tab_id FROM ad_tab WHERE ad_tab_uu=r;
  SELECT ad_table_id INTO v_table_id FROM ad_table WHERE tablename='AbERP_ComplianceDashboard';
  IF v_tab_id IS NULL OR v_table_id IS NULL THEN
    RAISE EXCEPTION 'SAW025-38: Rostering tab or dashboard table missing';
  END IF;

  UPDATE ad_field f SET
    name='Current Roster',
    description='Shifts in the current pay / roster period.',
    help='Shifts in the current pay / roster period.',
    updated=NOW()
  WHERE f.ad_tab_id=v_tab_id
    AND f.ad_column_id=(SELECT ad_column_id FROM ad_column WHERE ad_table_id=v_table_id AND columnname='PeriodShifts');

  UPDATE ad_field f SET isdisplayed='N', isdisplayedgrid='N', updated=NOW()
  WHERE f.ad_tab_id=v_tab_id
    AND f.ad_column_id=(SELECT ad_column_id FROM ad_column WHERE ad_table_id=v_table_id AND columnname='PeriodShiftsChange90d');

  PERFORM pg_temp.saw025_kpi_column_38(
    'NextPeriodShifts','Next Roster',11,10,
    'aberp_compliance_period_shifts('||cl||',''next'')',
    'Shifts in the next pay / roster period.');
  PERFORM pg_temp.saw025_kpi_field_38(
    r,'NextPeriodShifts','Next Roster',4,'Y',
    'Shifts in the next pay / roster period.');

  PERFORM pg_temp.saw025_kpi_column_38(
    'RosterFillRatePct','Current Fill Rate %',22,10,
    'aberp_compliance_roster_kpi('||cl||',''fill_pct'',''current'')',
    'Fill rate for the current roster period.');
  PERFORM pg_temp.saw025_kpi_field_38(r,'RosterFillRatePct','Current Fill Rate %',60,'N',
    'Fill rate for the current roster period.');

  PERFORM pg_temp.saw025_kpi_column_38(
    'RosterCoverage7dPct','Next Fill Rate %',22,10,
    'aberp_compliance_roster_kpi('||cl||',''fill_pct'',''next'')',
    'Fill rate for the next roster period.');
  PERFORM pg_temp.saw025_kpi_field_38(r,'RosterCoverage7dPct','Next Fill Rate %',62,'Y',
    'Fill rate for the next roster period.');

  PERFORM pg_temp.saw025_kpi_column_38(
    'RosterUnfilledShifts','Current Unfilled',11,10,
    'aberp_compliance_roster_kpi('||cl||',''unfilled'',''current'')',
    'Unfilled shifts in the current roster period.');
  PERFORM pg_temp.saw025_kpi_field_38(r,'RosterUnfilledShifts','Current Unfilled',70,'N',
    'Unfilled shifts in the current roster period.');

  PERFORM pg_temp.saw025_kpi_column_38(
    'RosterCoverage14dPct','Next Unfilled',11,10,
    'aberp_compliance_roster_kpi('||cl||',''unfilled'',''next'')',
    'Unfilled shifts in the next roster period.');
  PERFORM pg_temp.saw025_kpi_field_38(r,'RosterCoverage14dPct','Next Unfilled',72,'Y',
    'Unfilled shifts in the next roster period.');

  PERFORM pg_temp.saw025_kpi_column_38(
    'RosterFilledShifts','Current Filled',11,10,
    'aberp_compliance_roster_kpi('||cl||',''filled'',''current'')',
    'Filled shifts in the current roster period.');
  PERFORM pg_temp.saw025_kpi_field_38(r,'RosterFilledShifts','Current Filled',80,'N',
    'Filled shifts in the current roster period.');

  PERFORM pg_temp.saw025_kpi_column_38(
    'RosterPartialShifts','Next Filled',11,10,
    'aberp_compliance_roster_kpi('||cl||',''filled'',''next'')',
    'Filled shifts in the next roster period.');
  PERFORM pg_temp.saw025_kpi_field_38(r,'RosterPartialShifts','Next Filled',82,'Y',
    'Filled shifts in the next roster period.');

  PERFORM pg_temp.saw025_kpi_column_38(
    'RosterCancelledShifts','Current Cancelled',11,10,
    'aberp_compliance_roster_kpi('||cl||',''cancelled'',''current'')',
    'Cancelled shifts in the current roster period.');
  PERFORM pg_temp.saw025_kpi_field_38(r,'RosterCancelledShifts','Current Cancelled',90,'N',
    'Cancelled shifts in the current roster period.');

  PERFORM pg_temp.saw025_kpi_column_38(
    'RosterAgencyAssignments','Next Cancelled',11,10,
    'aberp_compliance_roster_kpi('||cl||',''cancelled'',''next'')',
    'Cancelled shifts in the next roster period.');
  PERFORM pg_temp.saw025_kpi_field_38(r,'RosterAgencyAssignments','Next Cancelled',92,'Y',
    'Cancelled shifts in the next roster period.');

  PERFORM pg_temp.saw025_kpi_column_38(
    'RosterMissingCredential','Current Missing Cred',11,10,
    'aberp_compliance_roster_kpi('||cl||',''missing_cred'',''current'')',
    'Shifts in the current roster with allocated staff missing a required credential.');
  PERFORM pg_temp.saw025_kpi_field_38(r,'RosterMissingCredential','Current Missing Cred',100,'N',
    'Shifts in the current roster with allocated staff missing a required credential.');

  PERFORM pg_temp.saw025_kpi_column_38(
    'RosterEmployeeAssignments','Next Missing Cred',11,10,
    'aberp_compliance_roster_kpi('||cl||',''missing_cred'',''next'')',
    'Shifts in the next roster with allocated staff missing a required credential.');
  PERFORM pg_temp.saw025_kpi_field_38(r,'RosterEmployeeAssignments','Next Missing Cred',102,'Y',
    'Shifts in the next roster with allocated staff missing a required credential.');
END $$;

SELECT 'SAW025-38 roster current+next period KPIs installed' AS status;
