-- SAW025-36 — Fix Active Clients (support receivers) + working 90d change
-- Clients: C_BPartner.AbERP_IsSupport_Receiver='Y' AND IsActive='Y' (matches Client window)
-- Change (90d): current − baseline; baseline prefers snapshot ≤90d ago, else members Created ≤ today−90
SET search_path TO adempiere;

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
  SELECT bp.ad_client_id,
         COUNT(*)::numeric AS n,
         COUNT(*) FILTER (WHERE u.created::date <= (CURRENT_DATE - 90))::numeric AS n90
  FROM ad_user u
  JOIN c_bpartner bp ON bp.c_bpartner_id = u.c_bpartner_id
  WHERE u.isactive = 'Y' AND bp.isactive = 'Y' AND bp.isemployee = 'Y'
  GROUP BY bp.ad_client_id
),
live_cli AS (
  SELECT bp.ad_client_id,
         COUNT(*)::numeric AS n,
         COUNT(*) FILTER (WHERE bp.created::date <= (CURRENT_DATE - 90))::numeric AS n90
  FROM c_bpartner bp
  WHERE bp.isactive = 'Y' AND COALESCE(bp.aberp_issupport_receiver, 'N') = 'Y'
  GROUP BY bp.ad_client_id
),
live_inc AS (
  SELECT i.ad_client_id,
         COUNT(*)::numeric AS n,
         COUNT(*) FILTER (WHERE i.created::date <= (CURRENT_DATE - 90))::numeric AS n90
  FROM aberp_incident i
  LEFT JOIN aberp_incident_status s ON s.aberp_incident_status_id = i.aberp_incident_status_id
  WHERE i.isactive = 'Y'
    AND COALESCE(s.name, '') NOT ILIKE '%closed%'
  GROUP BY i.ad_client_id
),
live_doc AS (
  SELECT ca.ad_client_id,
         COUNT(*)::numeric AS n,
         COUNT(*) FILTER (WHERE ca.created::date <= (CURRENT_DATE - 90))::numeric AS n90
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

  -- SAW025 population (36: support-receiver clients + live 90d baseline fallback)
  COALESCE((SELECT n FROM live_emp WHERE ad_client_id = c.ad_client_id), 0)::numeric AS activeemployees,
  (COALESCE((SELECT n FROM live_emp WHERE ad_client_id = c.ad_client_id), 0)
    - COALESCE(
        (SELECT populationcount FROM pop90 WHERE ad_client_id = c.ad_client_id AND compliancecategory = 'W'),
        (SELECT n90 FROM live_emp WHERE ad_client_id = c.ad_client_id),
        0
      ))::numeric AS activeemployeeschange90d,

  COALESCE((SELECT n FROM live_cli WHERE ad_client_id = c.ad_client_id), 0)::numeric AS activeclients,
  (COALESCE((SELECT n FROM live_cli WHERE ad_client_id = c.ad_client_id), 0)
    - COALESCE(
        (SELECT populationcount FROM pop90 WHERE ad_client_id = c.ad_client_id AND compliancecategory = 'P'),
        (SELECT n90 FROM live_cli WHERE ad_client_id = c.ad_client_id),
        0
      ))::numeric AS activeclientschange90d,

  COALESCE((SELECT n FROM live_inc WHERE ad_client_id = c.ad_client_id), 0)::numeric AS activeincidents,
  (COALESCE((SELECT n FROM live_inc WHERE ad_client_id = c.ad_client_id), 0)
    - COALESCE(
        (SELECT populationcount FROM pop90 WHERE ad_client_id = c.ad_client_id AND compliancecategory = 'I'),
        (SELECT n90 FROM live_inc WHERE ad_client_id = c.ad_client_id),
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
        (SELECT n90 FROM live_doc WHERE ad_client_id = c.ad_client_id),
        0
      ))::numeric AS totaldocumentschange90d,

  NULL::character(1) AS aberp_refreshcompliance
FROM clients c;

-- Reseed latest snapshot populations with corrected client definition
UPDATE aberp_compliancesnapshot s SET
  populationcount = CASE s.compliancecategory
    WHEN 'W' THEN (
      SELECT COUNT(*) FROM ad_user u
      JOIN c_bpartner bp ON bp.c_bpartner_id = u.c_bpartner_id
      WHERE u.ad_client_id = s.ad_client_id AND u.isactive='Y' AND bp.isactive='Y' AND bp.isemployee='Y')
    WHEN 'P' THEN (
      SELECT COUNT(*) FROM c_bpartner bp
      WHERE bp.ad_client_id = s.ad_client_id AND bp.isactive='Y'
        AND COALESCE(bp.aberp_issupport_receiver,'N')='Y')
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

-- Clarify Change (90d) field names on tabs (description)
UPDATE ad_field SET
  description = 'Current population minus members that already existed 90 days ago (or last snapshot ≤90d when available)',
  help = 'Positive = net additions still in the population over 90 days. Rostering uses current period vs average of completed periods in the last 90 days.',
  updated = NOW()
WHERE ad_field_uu IN (
  '25a02511-f002-4f01-8e15-000000000001',
  '25a02512-f002-4f01-8e15-000000000001',
  '25a02513-f002-4f01-8e15-000000000001',
  '25a02514-f002-4f01-8e15-000000000001',
  '25a02515-f002-4f01-8e15-000000000001'
);

UPDATE ad_field SET
  description = 'Active NDIS clients (Business Partners with Support Receiver = Yes)',
  help = 'Matches the Client window: AbERP_IsSupport_Receiver = Y and Active.',
  updated = NOW()
WHERE ad_field_uu = '25a02512-f001-4f01-8e15-000000000001';

SELECT activeemployees, activeemployeeschange90d,
       activeclients, activeclientschange90d,
       activeincidents, activeincidentschange90d,
       periodshifts, periodshiftschange90d,
       totaldocuments, totaldocumentschange90d
FROM aberp_compliancedashboard WHERE ad_client_id = 1000003;
