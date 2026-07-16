-- =============================================================================
-- SAW023 Phase 3 — seed Employee (Workforce) compliance rules
-- Source table: AbERP_CredentialAssignment (aberp_expirydate)
-- Rules UU: 23a02350 / 23a02351 / 23a02352
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_table_id INTEGER;
  v_window_id INTEGER;
  v_rule_id INTEGER;
  r RECORD;
BEGIN
  SELECT ad_table_id INTO v_table_id
  FROM ad_table
  WHERE tablename = 'AbERP_CredentialAssignment'
  LIMIT 1;
  IF v_table_id IS NULL THEN
    RAISE EXCEPTION 'SAW023: AbERP_CredentialAssignment AD table missing';
  END IF;

  SELECT ad_window_id INTO v_window_id
  FROM ad_window
  WHERE name = 'Credential Assignment' AND isactive = 'Y'
  ORDER BY ad_window_id
  LIMIT 1;

  FOR r IN
    SELECT * FROM (VALUES
      (
        '23a02350-c0d4-4f01-8e15-000000000001',
        'Employee credential expired',
        'Active credential assignment where AbERP_ExpiryDate is before today.',
        'W', 'HIGH', 3::numeric, NULL::numeric
      ),
      (
        '23a02351-c0d4-4f01-8e15-000000000001',
        'Credential expires within 30 days',
        'Active credential assignment expiring within DaysBeforeExpiry (default 30).',
        'W', 'MED', 2::numeric, 30::numeric
      ),
      (
        '23a02352-c0d4-4f01-8e15-000000000001',
        'Worker screening expired',
        'Expired NDIS Worker Screening / Working with Children credential assignments.',
        'W', 'CRIT', 5::numeric, NULL::numeric
      )
    ) AS t(uu, name, description, category, severity, weight, days_before)
  LOOP
    SELECT aberp_compliancerule_id INTO v_rule_id
    FROM aberp_compliancerule
    WHERE aberp_compliancerule_uu = r.uu
    LIMIT 1;
    IF v_rule_id IS NULL THEN
      SELECT aberp_compliancerule_id INTO v_rule_id
      FROM aberp_compliancerule
      WHERE name = r.name AND ad_client_id = 0
      LIMIT 1;
    END IF;

    IF v_rule_id IS NULL THEN
      INSERT INTO aberp_compliancerule (
        aberp_compliancerule_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby,
        aberp_compliancerule_uu, name, description,
        compliancecategory, severity, weight, daysbeforeexpiry,
        ad_window_id, ad_infowindow_id, ad_table_id
      ) VALUES (
        nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AbERP_ComplianceRule' AND istableid = 'Y')::integer, 'N'),
        0, 0, 'Y',
        NOW(), 100, NOW(), 100,
        r.uu, r.name, r.description,
        r.category, r.severity, r.weight, r.days_before,
        v_window_id, NULL, v_table_id
      );
    ELSE
      UPDATE aberp_compliancerule SET
        name = r.name,
        description = r.description,
        compliancecategory = r.category,
        severity = r.severity,
        weight = r.weight,
        daysbeforeexpiry = r.days_before,
        ad_table_id = v_table_id,
        ad_window_id = COALESCE(v_window_id, ad_window_id),
        isactive = 'Y',
        aberp_compliancerule_uu = COALESCE(aberp_compliancerule_uu, r.uu),
        updated = NOW(),
        updatedby = 100
      WHERE aberp_compliancerule_id = v_rule_id;
    END IF;
  END LOOP;

  RAISE NOTICE 'SAW023 Employee rules seeded (Credential Assignment table=%)', v_table_id;
END $$;

SELECT aberp_compliancerule_uu, name, compliancecategory, severity, weight, daysbeforeexpiry, ad_table_id
FROM aberp_compliancerule
WHERE aberp_compliancerule_uu LIKE '23a0235%'
ORDER BY name;
