-- =============================================================================
-- SAW023 — stub dashboard VIEW + AD registration
-- View table UU: 23a02304-c0d4-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

CREATE OR REPLACE VIEW aberp_compliancedashboard AS
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
    MAX(s.snapshotdate) AS snapshotdate
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
)
SELECT
  c.ad_client_id AS aberp_compliancedashboard_id,
  c.ad_client_id,
  0::numeric(10) AS ad_org_id,
  'Y'::character(1) AS isactive,
  NOW() AS created,
  100::numeric(10) AS createdby,
  NOW() AS updated,
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
    - COALESCE((SELECT totalitems FROM prev WHERE ad_client_id = c.ad_client_id AND compliancecategory='D'),0))::numeric AS docchange
FROM clients c;


-- AD registration for view
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_table_id),0)+1 FROM ad_table))
WHERE name='AD_Table' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw023_col(
  p_table_id INTEGER, p_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_ref INTEGER, p_ref_value INTEGER, p_mandatory CHAR, p_updateable CHAR,
  p_seqno INTEGER, p_fieldlength INTEGER,
  p_iskey CHAR DEFAULT 'N', p_isparent CHAR DEFAULT 'N', p_isidentifier CHAR DEFAULT 'N'
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
      '23a023e1-0000-4000-8000-' || lpad(substr(md5(p_columnname), 1, 12), 12, '0')
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
      ad_reference_id, ad_reference_value_id,
      fieldlength, iskey, isparent, ismandatory, isupdateable,
      isidentifier, seqno, istranslated, isencrypted, isselectioncolumn,
      ad_element_id, issyncdatabase, isalwaysupdateable,
      isallowcopy, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, 0, 'Ab_ERP', p_columnname, p_table_id,
      p_ref, p_ref_value,
      p_fieldlength, p_iskey, p_isparent, p_mandatory, p_updateable,
      p_isidentifier, p_seqno, 'N', 'N', 'N',
      v_el, 'Y', 'N',
      'N', p_uu
    );
  ELSE
    UPDATE ad_column SET
      name = p_name,
      ad_reference_id = p_ref,
      ad_reference_value_id = p_ref_value,
      fieldlength = p_fieldlength,
      ismandatory = p_mandatory,
      isupdateable = p_updateable,
      isidentifier = p_isidentifier,
      iskey = p_iskey,
      entitytype = 'Ab_ERP',
      ad_column_uu = COALESCE(ad_column_uu, p_uu),
      updated = NOW()
    WHERE ad_column_id = v_col_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_dash_uu CONSTANT TEXT := '23a02304-c0d4-4f01-8e15-000000000001';
  v_dash_id INTEGER;
  v_tl INTEGER;
  r RECORD;
BEGIN
  SELECT ad_reference_id INTO v_tl FROM ad_reference
  WHERE ad_reference_uu = '23a02323-c0d4-4f01-8e15-000000000001' OR name = 'AbERP_TrafficLight' LIMIT 1;

  SELECT ad_table_id INTO v_dash_id FROM ad_table WHERE ad_table_uu = v_dash_uu;
  IF v_dash_id IS NULL THEN
    SELECT ad_table_id INTO v_dash_id FROM ad_table WHERE tablename = 'AbERP_ComplianceDashboard';
  END IF;

  IF v_dash_id IS NULL THEN
    INSERT INTO ad_table (
      ad_table_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, tablename,
      isview, accesslevel, entitytype, issecurityenabled,
      isdeleteable, ishighvolume, importtable, ischangelog,
      replicationtype, ad_table_uu, iscentrallymaintained
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Table' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Compliance Dashboard',
      'Pivoted latest compliance snapshot (read-only)',
      'AbERP_ComplianceDashboard',
      'Y', '3', 'Ab_ERP', 'N',
      'N', 'N', 'N', 'N',
      'L', v_dash_uu, 'Y'
    ) RETURNING ad_table_id INTO v_dash_id;
  ELSE
    UPDATE ad_table SET
      name = 'Compliance Dashboard',
      tablename = 'AbERP_ComplianceDashboard',
      isview = 'Y',
      isdeleteable = 'N',
      entitytype = 'Ab_ERP',
      ad_table_uu = COALESCE(ad_table_uu, v_dash_uu),
      updated = NOW()
    WHERE ad_table_id = v_dash_id;
  END IF;

  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c001-4f01-8e15-000000000001','AbERP_ComplianceDashboard_ID','Compliance Dashboard',13,NULL,'Y','N',0,10,'Y','N','Y');
  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c002-4f01-8e15-000000000001','AD_Client_ID','Client',19,NULL,'Y','N',10,10);
  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c003-4f01-8e15-000000000001','AD_Org_ID','Organization',19,NULL,'Y','N',20,10);
  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c004-4f01-8e15-000000000001','IsActive','Active',20,NULL,'Y','N',30,1);
  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c005-4f01-8e15-000000000001','Created','Created',16,NULL,'Y','N',40,7);
  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c006-4f01-8e15-000000000001','CreatedBy','Created By',18,110,'Y','N',50,10);
  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c007-4f01-8e15-000000000001','Updated','Updated',16,NULL,'Y','N',60,7);
  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c008-4f01-8e15-000000000001','UpdatedBy','Updated By',18,110,'Y','N',70,10);
  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c009-4f01-8e15-000000000001','AbERP_ComplianceDashboard_UU','Immutable Universally Unique Identifier',10,NULL,'N','N',80,36);

  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c010-4f01-8e15-000000000001','OverallScore','Audit Readiness Score',22,NULL,'N','N',100,10);
  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c011-4f01-8e15-000000000001','OverallTrafficLight','Traffic Light',17,v_tl,'N','N',110,2);
  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c012-4f01-8e15-000000000001','TotalItems','Total Items',11,NULL,'N','N',120,10);
  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c013-4f01-8e15-000000000001','TotalCompliant','Compliant',11,NULL,'N','N',130,10);
  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c014-4f01-8e15-000000000001','TotalWarning','Warning',11,NULL,'N','N',140,10);
  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c015-4f01-8e15-000000000001','TotalNonCompliant','Non-Compliant',11,NULL,'N','N',150,10);
  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c016-4f01-8e15-000000000001','TotalCritical','Critical',11,NULL,'N','N',160,10);
  PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-c017-4f01-8e15-000000000001','LastRefreshed','Last Refreshed',16,NULL,'N','N',170,7);

  FOR r IN
    SELECT * FROM (VALUES
      ('Employee','Employee',30),
      ('Client','Client',40),
      ('Incident','Incidents',50),
      ('Roster','Rostering',60),
      ('Doc','Documentation',70)
    ) AS t(prefix, label, base)
  LOOP
    PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-'||lpad(r.base::text,4,'0')||'-0001-8e15-000000000001', r.prefix||'Total', r.label||' Total',11,NULL,'N','N',200,10);
    PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-'||lpad(r.base::text,4,'0')||'-0002-8e15-000000000001', r.prefix||'Compliant', r.label||' Compliant',11,NULL,'N','N',210,10);
    PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-'||lpad(r.base::text,4,'0')||'-0003-8e15-000000000001', r.prefix||'Warning', r.label||' Warning',11,NULL,'N','N',220,10);
    PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-'||lpad(r.base::text,4,'0')||'-0004-8e15-000000000001', r.prefix||'NonCompliant', r.label||' Non-Compliant',11,NULL,'N','N',230,10);
    PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-'||lpad(r.base::text,4,'0')||'-0005-8e15-000000000001', r.prefix||'Critical', r.label||' Critical',11,NULL,'N','N',240,10);
    PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-'||lpad(r.base::text,4,'0')||'-0006-8e15-000000000001', r.prefix||'Overdue', r.label||' Overdue',11,NULL,'N','N',250,10);
    PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-'||lpad(r.base::text,4,'0')||'-0007-8e15-000000000001', r.prefix||'AtRisk', r.label||' At Risk',11,NULL,'N','N',260,10);
    PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-'||lpad(r.base::text,4,'0')||'-0008-8e15-000000000001', r.prefix||'OnTrack', r.label||' On Track',11,NULL,'N','N',270,10);
    PERFORM pg_temp.saw023_col(v_dash_id,'23a02304-'||lpad(r.base::text,4,'0')||'-0009-8e15-000000000001', r.prefix||'Change', r.label||' Change (90d)',11,NULL,'N','N',280,10);
  END LOOP;

  RAISE NOTICE 'SAW023 dashboard view AD table id=%', v_dash_id;
END $$;
