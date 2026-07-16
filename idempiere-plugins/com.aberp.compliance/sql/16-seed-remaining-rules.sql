-- =============================================================================
-- SAW023 Phase 3b — seed Client / Incidents / Rostering / Documentation rules
-- UUs 23a02353 … 23a02359
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_rule_id INTEGER;
  v_table_id INTEGER;
  v_window_id INTEGER;
  r RECORD;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      -- Client (P)
      ('23a02353-c0d4-4f01-8e15-000000000001',
       'Risk assessment overdue',
       'Active AbERP_Risks where ValidTo is before today.',
       'P', 'HIGH', 3::numeric, NULL::numeric,
       'AbERP_Risks', 'Risks'),
      ('23a02354-c0d4-4f01-8e15-000000000001',
       'Missing active Service Agreement',
       'Skipped when AbERP_Service_Agreement has no usable date model / zero rows for the client.',
       'P', 'HIGH', 3::numeric, NULL::numeric,
       'AbERP_Service_Agreement', NULL),
      -- Incidents (I)
      ('23a02355-c0d4-4f01-8e15-000000000001',
       'Incident investigation overdue',
       'Active incidents with Due Date before today and status not Closed.',
       'I', 'HIGH', 3::numeric, NULL::numeric,
       'AbERP_Incident', 'Incident Report'),
      ('23a02356-c0d4-4f01-8e15-000000000001',
       'Outstanding incident actions',
       'HCO Incident Actions that are active and not complete.',
       'I', 'MED', 2::numeric, NULL::numeric,
       'HCO_Incident_Actions', 'Incident Actions'),
      -- Rostering (R)
      ('23a02357-c0d4-4f01-8e15-000000000001',
       'Upcoming shift unfilled',
       'Active rostered shifts in the next 14 days with no assigned staff contact.',
       'R', 'CRIT', 4::numeric, 14::numeric,
       'AbERP_Rostered_Shift', NULL),
      ('23a02358-c0d4-4f01-8e15-000000000001',
       'Staff assigned without required credential',
       'Assigned shift staff missing an active matching CRD need credential (next 14 days).',
       'R', 'HIGH', 3::numeric, 14::numeric,
       'AbERP_Rostered_ShiftStaff', NULL),
      -- Documentation (D)
      ('23a02359-c0d4-4f01-8e15-000000000001',
       'Onboarding documentation expired',
       'Expired credential assignments in Onboarding Documentation category.',
       'D', 'MED', 2::numeric, NULL::numeric,
       'AbERP_CredentialAssignment', 'Credential Assignment')
    ) AS t(uu, name, description, category, severity, weight, days_before, tablename, winname)
  LOOP
    SELECT ad_table_id INTO v_table_id FROM ad_table WHERE tablename = r.tablename LIMIT 1;
    IF v_table_id IS NULL THEN
      RAISE NOTICE 'SAW023 skip rule % — table % missing', r.name, r.tablename;
      CONTINUE;
    END IF;

    v_window_id := NULL;
    IF r.winname IS NOT NULL THEN
      SELECT ad_window_id INTO v_window_id
      FROM ad_window WHERE name = r.winname AND isactive = 'Y'
      ORDER BY ad_window_id LIMIT 1;
    END IF;

    SELECT aberp_compliancerule_id INTO v_rule_id
    FROM aberp_compliancerule WHERE aberp_compliancerule_uu = r.uu LIMIT 1;
    IF v_rule_id IS NULL THEN
      SELECT aberp_compliancerule_id INTO v_rule_id
      FROM aberp_compliancerule WHERE name = r.name AND ad_client_id = 0 LIMIT 1;
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
        0, 0, 'Y', NOW(), 100, NOW(), 100,
        r.uu, r.name, r.description,
        r.category, r.severity, r.weight, r.days_before,
        v_window_id, NULL, v_table_id
      );
    ELSE
      UPDATE aberp_compliancerule SET
        name = r.name, description = r.description,
        compliancecategory = r.category, severity = r.severity,
        weight = r.weight, daysbeforeexpiry = r.days_before,
        ad_table_id = v_table_id,
        ad_window_id = COALESCE(v_window_id, ad_window_id),
        isactive = 'Y',
        aberp_compliancerule_uu = COALESCE(aberp_compliancerule_uu, r.uu),
        updated = NOW(), updatedby = 100
      WHERE aberp_compliancerule_id = v_rule_id;
    END IF;
  END LOOP;

  RAISE NOTICE 'SAW023 Phase 3b rules seeded';
END $$;

SELECT aberp_compliancerule_uu, name, compliancecategory, severity
FROM aberp_compliancerule
WHERE aberp_compliancerule_uu LIKE '23a0235%'
ORDER BY compliancecategory, name;
