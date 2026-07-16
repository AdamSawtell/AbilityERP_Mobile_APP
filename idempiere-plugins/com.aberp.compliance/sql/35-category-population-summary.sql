-- SAW025 — Category tab population summaries (count + 90d change) at top of each tab
-- Employee / Client / Incidents: active population + vs snapshot ≤90d ago
-- Rostering: shifts in current pay period + vs avg completed periods in last 90d
-- Documentation: active credential assignments + vs snapshot ≤90d ago
SET search_path TO adempiere;

-- 1. Physical population on snapshots (written by ComplianceEngine on Refresh)
ALTER TABLE aberp_compliancesnapshot
  ADD COLUMN IF NOT EXISTS populationcount NUMERIC(10);

COMMENT ON COLUMN aberp_compliancesnapshot.populationcount IS
  'SAW025 category population (active employees/clients/incidents, period shifts, or documents)';

-- 2. Recreate dashboard view with live population + 90d change columns
-- (CREATE OR REPLACE cannot rename/reorder trailing columns — drop first)
DROP VIEW IF EXISTS aberp_compliancedashboard CASCADE;
CREATE VIEW aberp_compliancedashboard AS
WITH clients AS (
  SELECT DISTINCT ad_client_id
  FROM aberp_compliancesnapshot
  WHERE isactive = 'Y'
  UNION
  SELECT ad_client_id FROM ad_client WHERE ad_client_id IN (1000002, 1000003)
),
cur AS (
  SELECT
    s.ad_client_id,
    s.compliancecategory,
    COALESCE(SUM(s.totalitems),0) AS totalitems,
    COALESCE(SUM(s.compliant),0) AS compliant,
    COALESCE(SUM(s.warning),0) AS warning,
    COALESCE(SUM(s.noncompliant),0) AS noncompliant,
    COALESCE(SUM(s.critical),0) AS critical,
    COALESCE(SUM(s.overdue),0) AS overdue,
    COALESCE(SUM(s.atrisk),0) AS atrisk,
    COALESCE(SUM(s.ontrack),0) AS ontrack,
    COALESCE(AVG(s.auditreadinessscore),0) AS score,
    MAX(s.trafficlight) AS trafficlight,
    MAX(s.lastcalculated) AS lastcalculated,
    MAX(s.snapshotdate) AS snapshotdate,
    MAX(s.populationcount) AS populationcount
  FROM aberp_compliancesnapshot s
  WHERE s.isactive = 'Y'
    AND s.aberp_support_location_id IS NULL
    AND s.snapshotdate = (
      SELECT MAX(s2.snapshotdate)
      FROM aberp_compliancesnapshot s2
      WHERE s2.isactive = 'Y'
        AND s2.aberp_support_location_id IS NULL
        AND s2.ad_client_id = s.ad_client_id
    )
  GROUP BY s.ad_client_id, s.compliancecategory
),
prev AS (
  SELECT
    s.ad_client_id,
    s.compliancecategory,
    COALESCE(SUM(s.totalitems),0) AS totalitems
  FROM aberp_compliancesnapshot s
  WHERE s.isactive = 'Y'
    AND s.aberp_support_location_id IS NULL
    AND s.snapshotdate = (
      SELECT snapshotdate FROM (
        SELECT DISTINCT s2.snapshotdate
        FROM aberp_compliancesnapshot s2
        WHERE s2.isactive = 'Y'
          AND s2.aberp_support_location_id IS NULL
          AND s2.ad_client_id = s.ad_client_id
        ORDER BY s2.snapshotdate DESC
        OFFSET 1 LIMIT 1
      ) x
    )
  GROUP BY s.ad_client_id, s.compliancecategory
),
pop90 AS (
  SELECT DISTINCT ON (s.ad_client_id, s.compliancecategory)
    s.ad_client_id,
    s.compliancecategory,
    s.populationcount
  FROM aberp_compliancesnapshot s
  WHERE s.isactive = 'Y'
    AND s.aberp_support_location_id IS NULL
    AND s.populationcount IS NOT NULL
    AND s.snapshotdate::date <= (CURRENT_DATE - 90)
  ORDER BY s.ad_client_id, s.compliancecategory, s.snapshotdate DESC
),
live_emp AS (
  SELECT bp.ad_client_id, COUNT(*)::numeric AS n
  FROM ad_user u
  JOIN c_bpartner bp ON bp.c_bpartner_id = u.c_bpartner_id
  WHERE u.isactive = 'Y' AND bp.isactive = 'Y' AND bp.isemployee = 'Y'
  GROUP BY bp.ad_client_id
),
live_cli AS (
  SELECT bp.ad_client_id, COUNT(*)::numeric AS n
  FROM c_bpartner bp
  WHERE bp.isactive = 'Y' AND bp.iscustomer = 'Y'
  GROUP BY bp.ad_client_id
),
live_inc AS (
  SELECT i.ad_client_id, COUNT(*)::numeric AS n
  FROM aberp_incident i
  LEFT JOIN aberp_incident_status s ON s.aberp_incident_status_id = i.aberp_incident_status_id
  WHERE i.isactive = 'Y'
    AND COALESCE(s.name, '') NOT ILIKE '%closed%'
  GROUP BY i.ad_client_id
),
live_doc AS (
  SELECT ca.ad_client_id, COUNT(*)::numeric AS n
  FROM aberp_credentialassignment ca
  WHERE ca.isactive = 'Y'
  GROUP BY ca.ad_client_id
),
live_roster AS (
  SELECT rs.ad_client_id, COUNT(*)::numeric AS n
  FROM aberp_rostered_shift rs
  JOIN aberp_pr_period p
    ON p.ad_client_id = rs.ad_client_id
   AND p.isactive = 'Y'
   AND CURRENT_DATE BETWEEN p.startdate::date AND p.enddate::date
  WHERE rs.isactive = 'Y'
    AND COALESCE(rs.aberp_isshiftrosteredtemplate, 'N') = 'N'
    AND rs.startdate::date BETWEEN p.startdate::date AND p.enddate::date
  GROUP BY rs.ad_client_id
),
roster_avg90 AS (
  SELECT ad_client_id, ROUND(AVG(cnt), 0)::numeric AS avg_n
  FROM (
    SELECT p.ad_client_id, p.aberp_pr_period_id, COUNT(rs.aberp_rostered_shift_id)::numeric AS cnt
    FROM aberp_pr_period p
    LEFT JOIN aberp_rostered_shift rs
      ON rs.ad_client_id = p.ad_client_id
     AND rs.isactive = 'Y'
     AND COALESCE(rs.aberp_isshiftrosteredtemplate, 'N') = 'N'
     AND rs.startdate::date BETWEEN p.startdate::date AND p.enddate::date
    WHERE p.isactive = 'Y'
      AND p.enddate::date < CURRENT_DATE
      AND p.enddate::date >= (CURRENT_DATE - 90)
    GROUP BY p.ad_client_id, p.aberp_pr_period_id
  ) x
  GROUP BY ad_client_id
)
SELECT
  c.ad_client_id AS aberp_compliancedashboard_id,
  c.ad_client_id,
  0::numeric(10) AS ad_org_id,
  'Y'::character(1) AS isactive,
  TIMESTAMPTZ '2020-01-01 00:00:00+00' AS created,
  100::numeric(10) AS createdby,
  TIMESTAMPTZ '2020-01-01 00:00:00+00' AS updated,
  100::numeric(10) AS updatedby,
  ('23a02304-dash-4f01-8e15-' || lpad(c.ad_client_id::text, 12, '0'))::character varying(36) AS aberp_compliancedashboard_uu,

  COALESCE((SELECT ROUND(AVG(score)::numeric, 2) FROM cur WHERE ad_client_id = c.ad_client_id), 0::numeric) AS overallscore,
  COALESCE(
    (SELECT trafficlight FROM cur WHERE ad_client_id = c.ad_client_id ORDER BY
       CASE trafficlight WHEN 'R' THEN 1 WHEN 'A' THEN 2 ELSE 3 END LIMIT 1),
    'G'
  ) AS overalltrafficlight,
  COALESCE((SELECT SUM(totalitems) FROM cur WHERE ad_client_id = c.ad_client_id), 0)::numeric AS totalitems,
  COALESCE((SELECT SUM(compliant) FROM cur WHERE ad_client_id = c.ad_client_id), 0)::numeric AS totalcompliant,
  COALESCE((SELECT SUM(warning) FROM cur WHERE ad_client_id = c.ad_client_id), 0)::numeric AS totalwarning,
  COALESCE((SELECT SUM(noncompliant) FROM cur WHERE ad_client_id = c.ad_client_id), 0)::numeric AS totalnoncompliant,
  COALESCE((SELECT SUM(critical) FROM cur WHERE ad_client_id = c.ad_client_id), 0)::numeric AS totalcritical,
  (SELECT MAX(lastcalculated) FROM cur WHERE ad_client_id = c.ad_client_id) AS lastrefreshed,

  COALESCE((SELECT totalitems FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='W'),0)::numeric AS employeetotal,
  COALESCE((SELECT compliant FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='W'),0)::numeric AS employeecompliant,
  COALESCE((SELECT warning FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='W'),0)::numeric AS employeewarning,
  COALESCE((SELECT noncompliant FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='W'),0)::numeric AS employeenoncompliant,
  COALESCE((SELECT critical FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='W'),0)::numeric AS employeecritical,
  COALESCE((SELECT overdue FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='W'),0)::numeric AS employeeoverdue,
  COALESCE((SELECT atrisk FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='W'),0)::numeric AS employeeatrisk,
  COALESCE((SELECT ontrack FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='W'),0)::numeric AS employeeontrack,
  (COALESCE((SELECT totalitems FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='W'),0)
    - COALESCE((SELECT totalitems FROM prev WHERE ad_client_id = c.ad_client_id AND compliancecategory='W'),0))::numeric AS employeechange,

  COALESCE((SELECT totalitems FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='P'),0)::numeric AS clienttotal,
  COALESCE((SELECT compliant FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='P'),0)::numeric AS clientcompliant,
  COALESCE((SELECT warning FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='P'),0)::numeric AS clientwarning,
  COALESCE((SELECT noncompliant FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='P'),0)::numeric AS clientnoncompliant,
  COALESCE((SELECT critical FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='P'),0)::numeric AS clientcritical,
  COALESCE((SELECT overdue FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='P'),0)::numeric AS clientoverdue,
  COALESCE((SELECT atrisk FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='P'),0)::numeric AS clientatrisk,
  COALESCE((SELECT ontrack FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='P'),0)::numeric AS clientontrack,
  (COALESCE((SELECT totalitems FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='P'),0)
    - COALESCE((SELECT totalitems FROM prev WHERE ad_client_id = c.ad_client_id AND compliancecategory='P'),0))::numeric AS clientchange,

  COALESCE((SELECT totalitems FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='I'),0)::numeric AS incidenttotal,
  COALESCE((SELECT compliant FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='I'),0)::numeric AS incidentcompliant,
  COALESCE((SELECT warning FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='I'),0)::numeric AS incidentwarning,
  COALESCE((SELECT noncompliant FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='I'),0)::numeric AS incidentnoncompliant,
  COALESCE((SELECT critical FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='I'),0)::numeric AS incidentcritical,
  COALESCE((SELECT overdue FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='I'),0)::numeric AS incidentoverdue,
  COALESCE((SELECT atrisk FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='I'),0)::numeric AS incidentatrisk,
  COALESCE((SELECT ontrack FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='I'),0)::numeric AS incidentontrack,
  (COALESCE((SELECT totalitems FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='I'),0)
    - COALESCE((SELECT totalitems FROM prev WHERE ad_client_id = c.ad_client_id AND compliancecategory='I'),0))::numeric AS incidentchange,

  COALESCE((SELECT totalitems FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='R'),0)::numeric AS rostertotal,
  COALESCE((SELECT compliant FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='R'),0)::numeric AS rostercompliant,
  COALESCE((SELECT warning FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='R'),0)::numeric AS rosterwarning,
  COALESCE((SELECT noncompliant FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='R'),0)::numeric AS rosternoncompliant,
  COALESCE((SELECT critical FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='R'),0)::numeric AS rostercritical,
  COALESCE((SELECT overdue FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='R'),0)::numeric AS rosteroverdue,
  COALESCE((SELECT atrisk FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='R'),0)::numeric AS rosteratrisk,
  COALESCE((SELECT ontrack FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='R'),0)::numeric AS rosterontrack,
  (COALESCE((SELECT totalitems FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='R'),0)
    - COALESCE((SELECT totalitems FROM prev WHERE ad_client_id = c.ad_client_id AND compliancecategory='R'),0))::numeric AS rosterchange,

  COALESCE((SELECT totalitems FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='D'),0)::numeric AS doctotal,
  COALESCE((SELECT compliant FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='D'),0)::numeric AS doccompliant,
  COALESCE((SELECT warning FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='D'),0)::numeric AS docwarning,
  COALESCE((SELECT noncompliant FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='D'),0)::numeric AS docnoncompliant,
  COALESCE((SELECT critical FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='D'),0)::numeric AS doccritical,
  COALESCE((SELECT overdue FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='D'),0)::numeric AS docoverdue,
  COALESCE((SELECT atrisk FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='D'),0)::numeric AS docatrisk,
  COALESCE((SELECT ontrack FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='D'),0)::numeric AS docontrack,
  (COALESCE((SELECT totalitems FROM cur WHERE ad_client_id = c.ad_client_id AND compliancecategory='D'),0)
    - COALESCE((SELECT totalitems FROM prev WHERE ad_client_id = c.ad_client_id AND compliancecategory='D'),0))::numeric AS docchange,

  -- SAW025 population summaries (live counts; 90d change vs snapshot baseline or roster period avg)
  COALESCE((SELECT n FROM live_emp WHERE ad_client_id = c.ad_client_id), 0)::numeric AS activeemployees,
  (COALESCE((SELECT n FROM live_emp WHERE ad_client_id = c.ad_client_id), 0)
    - COALESCE(
        (SELECT populationcount FROM pop90 WHERE ad_client_id = c.ad_client_id AND compliancecategory = 'W'),
        (SELECT n FROM live_emp WHERE ad_client_id = c.ad_client_id),
        0
      ))::numeric AS activeemployeeschange90d,

  COALESCE((SELECT n FROM live_cli WHERE ad_client_id = c.ad_client_id), 0)::numeric AS activeclients,
  (COALESCE((SELECT n FROM live_cli WHERE ad_client_id = c.ad_client_id), 0)
    - COALESCE(
        (SELECT populationcount FROM pop90 WHERE ad_client_id = c.ad_client_id AND compliancecategory = 'P'),
        (SELECT n FROM live_cli WHERE ad_client_id = c.ad_client_id),
        0
      ))::numeric AS activeclientschange90d,

  COALESCE((SELECT n FROM live_inc WHERE ad_client_id = c.ad_client_id), 0)::numeric AS activeincidents,
  (COALESCE((SELECT n FROM live_inc WHERE ad_client_id = c.ad_client_id), 0)
    - COALESCE(
        (SELECT populationcount FROM pop90 WHERE ad_client_id = c.ad_client_id AND compliancecategory = 'I'),
        (SELECT n FROM live_inc WHERE ad_client_id = c.ad_client_id),
        0
      ))::numeric AS activeincidentschange90d,

  COALESCE((SELECT n FROM live_roster WHERE ad_client_id = c.ad_client_id), 0)::numeric AS periodshifts,
  (COALESCE((SELECT n FROM live_roster WHERE ad_client_id = c.ad_client_id), 0)
    - COALESCE((SELECT avg_n FROM roster_avg90 WHERE ad_client_id = c.ad_client_id),
               (SELECT n FROM live_roster WHERE ad_client_id = c.ad_client_id),
               0))::numeric AS periodshiftschange90d,

  COALESCE((SELECT n FROM live_doc WHERE ad_client_id = c.ad_client_id), 0)::numeric AS totaldocuments,
  (COALESCE((SELECT n FROM live_doc WHERE ad_client_id = c.ad_client_id), 0)
    - COALESCE(
        (SELECT populationcount FROM pop90 WHERE ad_client_id = c.ad_client_id AND compliancecategory = 'D'),
        (SELECT n FROM live_doc WHERE ad_client_id = c.ad_client_id),
        0
      ))::numeric AS totaldocumentschange90d,

  NULL::character(1) AS aberp_refreshcompliance
FROM clients c;

-- 3. AD: PopulationCount on snapshot + summary columns on dashboard view
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw025_col(
  p_table_id INTEGER, p_uu TEXT, p_columnname TEXT, p_name TEXT, p_seqno INTEGER
) RETURNS void AS $$
DECLARE
  v_col_id INTEGER;
  v_el INTEGER;
BEGIN
  SELECT ad_element_id INTO v_el FROM ad_element WHERE columnname = p_columnname LIMIT 1;
  IF v_el IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_columnname, 'Ab_ERP', p_name, p_name,
      '25a025e1-0000-4000-8000-' || lpad(substr(md5(p_columnname), 1, 12), 12, '0')
    ) RETURNING ad_element_id INTO v_el;
  END IF;

  SELECT ad_column_id INTO v_col_id FROM ad_column WHERE ad_column_uu = p_uu;
  IF v_col_id IS NULL THEN
    SELECT ad_column_id INTO v_col_id FROM ad_column
    WHERE ad_table_id = p_table_id AND columnname = p_columnname;
  END IF;

  IF v_col_id IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, version, entitytype, columnname, ad_table_id,
      ad_reference_id, fieldlength, iskey, isparent, ismandatory, isupdateable,
      isidentifier, seqno, istranslated, isencrypted, isselectioncolumn,
      ad_element_id, issyncdatabase, isalwaysupdateable, isallowcopy, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, 0, 'Ab_ERP', p_columnname, p_table_id,
      11, 10, 'N', 'N', 'N', 'N',
      'N', p_seqno, 'N', 'N', 'N',
      v_el, 'Y', 'N', 'N', p_uu
    );
  ELSE
    UPDATE ad_column SET
      name = p_name,
      ad_reference_id = 11,
      entitytype = 'Ab_ERP',
      ad_column_uu = COALESCE(ad_column_uu, p_uu),
      updated = NOW()
    WHERE ad_column_id = v_col_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw025_field(
  p_tab_uu TEXT, p_field_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_seqno INTEGER, p_sameline CHAR
) RETURNS void AS $$
DECLARE
  v_tab_id INTEGER;
  v_col_id INTEGER;
  v_field_id INTEGER;
  v_table_id INTEGER;
BEGIN
  SELECT ad_tab_id, ad_table_id INTO v_tab_id, v_table_id
  FROM ad_tab WHERE ad_tab_uu = p_tab_uu;
  IF v_tab_id IS NULL THEN
    RAISE EXCEPTION 'SAW025: tab missing %', p_tab_uu;
  END IF;
  SELECT ad_column_id INTO v_col_id
  FROM ad_column WHERE ad_table_id = v_table_id AND columnname = p_columnname;
  IF v_col_id IS NULL THEN
    RAISE EXCEPTION 'SAW025: column missing %', p_columnname;
  END IF;

  SELECT ad_field_id INTO v_field_id FROM ad_field WHERE ad_field_uu = p_field_uu;
  IF v_field_id IS NULL THEN
    SELECT ad_field_id INTO v_field_id FROM ad_field
    WHERE ad_tab_id = v_tab_id AND ad_column_id = v_col_id;
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
      p_name, 'N', v_tab_id, v_col_id,
      'Y', 14, 'Y', p_seqno, p_sameline,
      'N', 'N', 'N', 'Ab_ERP',
      'Y', p_seqno, 1, 2, 1, p_field_uu
    );
  ELSE
    UPDATE ad_field SET
      name = p_name,
      isdisplayed = 'Y',
      isreadonly = 'Y',
      seqno = p_seqno,
      issameline = p_sameline,
      isdisplayedgrid = 'Y',
      seqnogrid = p_seqno,
      ad_field_uu = COALESCE(ad_field_uu, p_field_uu),
      updated = NOW()
    WHERE ad_field_id = v_field_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_snap_id INTEGER;
  v_dash_id INTEGER;
BEGIN
  SELECT ad_table_id INTO v_snap_id FROM ad_table WHERE tablename = 'AbERP_ComplianceSnapshot';
  SELECT ad_table_id INTO v_dash_id FROM ad_table WHERE tablename = 'AbERP_ComplianceDashboard';
  IF v_snap_id IS NULL OR v_dash_id IS NULL THEN
    RAISE EXCEPTION 'SAW025: snapshot/dashboard tables missing';
  END IF;

  PERFORM pg_temp.saw025_col(v_snap_id, '25a02503-c030-4f01-8e15-000000000001', 'PopulationCount', 'Population Count', 230);
  PERFORM pg_temp.saw025_col(v_dash_id, '25a02504-c101-4f01-8e15-000000000001', 'ActiveEmployees', 'Active Employees', 300);
  PERFORM pg_temp.saw025_col(v_dash_id, '25a02504-c102-4f01-8e15-000000000001', 'ActiveEmployeesChange90d', 'Active Employees Change (90d)', 310);
  PERFORM pg_temp.saw025_col(v_dash_id, '25a02504-c103-4f01-8e15-000000000001', 'ActiveClients', 'Active Clients', 320);
  PERFORM pg_temp.saw025_col(v_dash_id, '25a02504-c104-4f01-8e15-000000000001', 'ActiveClientsChange90d', 'Active Clients Change (90d)', 330);
  PERFORM pg_temp.saw025_col(v_dash_id, '25a02504-c105-4f01-8e15-000000000001', 'ActiveIncidents', 'Active Incidents', 340);
  PERFORM pg_temp.saw025_col(v_dash_id, '25a02504-c106-4f01-8e15-000000000001', 'ActiveIncidentsChange90d', 'Active Incidents Change (90d)', 350);
  PERFORM pg_temp.saw025_col(v_dash_id, '25a02504-c107-4f01-8e15-000000000001', 'PeriodShifts', 'Shifts (Current Period)', 360);
  PERFORM pg_temp.saw025_col(v_dash_id, '25a02504-c108-4f01-8e15-000000000001', 'PeriodShiftsChange90d', 'Shifts vs 90d Period Avg', 370);
  PERFORM pg_temp.saw025_col(v_dash_id, '25a02504-c109-4f01-8e15-000000000001', 'TotalDocuments', 'Total Documents', 380);
  PERFORM pg_temp.saw025_col(v_dash_id, '25a02504-c110-4f01-8e15-000000000001', 'TotalDocumentsChange90d', 'Total Documents Change (90d)', 390);

  -- Fields at top of each category tab (seq 2 / 4 ahead of Total Items at 10)
  PERFORM pg_temp.saw025_field('23a02311-c0d4-4f01-8e15-000000000001',
    '25a02511-f001-4f01-8e15-000000000001', 'ActiveEmployees', 'Active Employees', 2, 'N');
  PERFORM pg_temp.saw025_field('23a02311-c0d4-4f01-8e15-000000000001',
    '25a02511-f002-4f01-8e15-000000000001', 'ActiveEmployeesChange90d', 'Change (90d)', 4, 'Y');

  PERFORM pg_temp.saw025_field('23a02312-c0d4-4f01-8e15-000000000001',
    '25a02512-f001-4f01-8e15-000000000001', 'ActiveClients', 'Active Clients', 2, 'N');
  PERFORM pg_temp.saw025_field('23a02312-c0d4-4f01-8e15-000000000001',
    '25a02512-f002-4f01-8e15-000000000001', 'ActiveClientsChange90d', 'Change (90d)', 4, 'Y');

  PERFORM pg_temp.saw025_field('23a02313-c0d4-4f01-8e15-000000000001',
    '25a02513-f001-4f01-8e15-000000000001', 'ActiveIncidents', 'Active Incidents', 2, 'N');
  PERFORM pg_temp.saw025_field('23a02313-c0d4-4f01-8e15-000000000001',
    '25a02513-f002-4f01-8e15-000000000001', 'ActiveIncidentsChange90d', 'Change (90d)', 4, 'Y');

  PERFORM pg_temp.saw025_field('23a02314-c0d4-4f01-8e15-000000000001',
    '25a02514-f001-4f01-8e15-000000000001', 'PeriodShifts', 'Shifts (Current Period)', 2, 'N');
  PERFORM pg_temp.saw025_field('23a02314-c0d4-4f01-8e15-000000000001',
    '25a02514-f002-4f01-8e15-000000000001', 'PeriodShiftsChange90d', 'vs 90d Period Avg', 4, 'Y');

  PERFORM pg_temp.saw025_field('23a02315-c0d4-4f01-8e15-000000000001',
    '25a02515-f001-4f01-8e15-000000000001', 'TotalDocuments', 'Total Documents', 2, 'N');
  PERFORM pg_temp.saw025_field('23a02315-c0d4-4f01-8e15-000000000001',
    '25a02515-f002-4f01-8e15-000000000001', 'TotalDocumentsChange90d', 'Change (90d)', 4, 'Y');
END $$;

-- Seed today's population onto latest active snapshots so Change (90d) has a baseline going forward
UPDATE aberp_compliancesnapshot s SET
  populationcount = CASE s.compliancecategory
    WHEN 'W' THEN (
      SELECT COUNT(*) FROM ad_user u
      JOIN c_bpartner bp ON bp.c_bpartner_id = u.c_bpartner_id
      WHERE u.ad_client_id = s.ad_client_id AND u.isactive='Y' AND bp.isactive='Y' AND bp.isemployee='Y')
    WHEN 'P' THEN (
      SELECT COUNT(*) FROM c_bpartner bp
      WHERE bp.ad_client_id = s.ad_client_id AND bp.isactive='Y' AND bp.iscustomer='Y')
    WHEN 'I' THEN (
      SELECT COUNT(*) FROM aberp_incident i
      LEFT JOIN aberp_incident_status st ON st.aberp_incident_status_id = i.aberp_incident_status_id
      WHERE i.ad_client_id = s.ad_client_id AND i.isactive='Y'
        AND COALESCE(st.name,'') NOT ILIKE '%closed%')
    WHEN 'R' THEN (
      SELECT COUNT(*) FROM aberp_rostered_shift rs
      JOIN aberp_pr_period p ON p.ad_client_id = rs.ad_client_id AND p.isactive='Y'
        AND CURRENT_DATE BETWEEN p.startdate::date AND p.enddate::date
      WHERE rs.ad_client_id = s.ad_client_id AND rs.isactive='Y'
        AND COALESCE(rs.aberp_isshiftrosteredtemplate,'N')='N'
        AND rs.startdate::date BETWEEN p.startdate::date AND p.enddate::date)
    WHEN 'D' THEN (
      SELECT COUNT(*) FROM aberp_credentialassignment ca
      WHERE ca.ad_client_id = s.ad_client_id AND ca.isactive='Y')
    ELSE s.populationcount
  END,
  updated = NOW()
WHERE s.isactive = 'Y'
  AND s.aberp_support_location_id IS NULL
  AND s.snapshotdate = (
    SELECT MAX(s2.snapshotdate) FROM aberp_compliancesnapshot s2
    WHERE s2.isactive='Y' AND s2.aberp_support_location_id IS NULL
      AND s2.ad_client_id = s.ad_client_id
  );

SELECT 'SAW025 population summary installed' AS status;
