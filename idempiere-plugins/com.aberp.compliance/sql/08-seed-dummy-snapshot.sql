-- =============================================================================
-- SAW023 — seed dummy org-wide snapshots so Summary tabs show numbers
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_client INTEGER;
  v_now TIMESTAMP := NOW();
  r RECORD;
  v_id INTEGER;
  v_clients INTEGER[];
BEGIN
  SELECT ARRAY_AGG(ad_client_id) INTO v_clients
  FROM ad_client
  WHERE name IN ('AbilityERP', 'HCO - Disability and Community Services')
     OR ad_client_id IN (1000002, 1000003);

  IF v_clients IS NULL OR array_length(v_clients, 1) IS NULL THEN
    v_clients := ARRAY[1000002, 1000003];
  END IF;

  DELETE FROM aberp_compliancesnapshot
  WHERE aberp_compliancesnapshot_uu LIKE '23a02380-%';

  FOREACH v_client IN ARRAY v_clients
  LOOP
    FOR r IN
      SELECT * FROM (VALUES
        ('W', 412, 389, 15, 8, 5, 3, 12, 389, 87.00, 'G'),
        ('P', 520, 480, 25, 10, 5, 8, 20, 480, 85.00, 'G'),
        ('I', 134, 100, 20, 10, 4, 6, 8, 100, 72.00, 'A'),
        ('R', 98, 72, 10, 8, 8, 10, 5, 72, 48.00, 'R'),
        ('D', 70, 55, 10, 3, 2, 4, 8, 55, 90.00, 'G')
      ) AS t(cat, total, comp, warn, nc, crit, overdue, atrisk, ontrack, score, tl)
    LOOP
      v_id := nextidfunc(
        (SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AbERP_ComplianceSnapshot' AND istableid = 'Y')::integer,
        'N'
      );
      INSERT INTO aberp_compliancesnapshot (
        aberp_compliancesnapshot_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby,
        aberp_compliancesnapshot_uu, snapshotdate, aberp_support_location_id,
        compliancecategory, totalitems, compliant, warning, noncompliant, critical,
        overdue, atrisk, ontrack, auditreadinessscore, trafficlight, lastcalculated
      ) VALUES (
        v_id, v_client, 0, 'Y',
        v_now, 100, v_now, 100,
        '23a02380-' || CASE r.cat
          WHEN 'W' THEN '0001'
          WHEN 'P' THEN '0002'
          WHEN 'I' THEN '0003'
          WHEN 'R' THEN '0004'
          WHEN 'D' THEN '0005'
        END || '-4f01-8e15-' || lpad(v_client::text, 12, '0'), v_now, NULL,
        r.cat, r.total, r.comp, r.warn, r.nc, r.crit,
        r.overdue, r.atrisk, r.ontrack, r.score, r.tl, v_now
      );
    END LOOP;
  END LOOP;

  RAISE NOTICE 'SAW023 seeded snapshots for clients %', v_clients;
END $$;

-- Smoke the view
SELECT overallscore, overalltrafficlight, totalitems,
       employeetotal, clienttotal, incidenttotal, rostertotal, doctotal
FROM aberp_compliancedashboard;
