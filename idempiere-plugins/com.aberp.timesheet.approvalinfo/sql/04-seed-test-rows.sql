-- SAW010 staging seed: extra timesheet rows for WebUI validation.
-- Idempotent via fixed UUs. Safe on AbilityERP seed/dev only — review before client use.

SET search_path TO adempiere;

DO $$
DECLARE
  v_client NUMERIC := 1000002;
  v_org NUMERIC := 0;
  v_user_emp NUMERIC := 1000107; -- Ella Williams (employee)
  v_user_agency NUMERIC;
  v_shift_type NUMERIC;
  v_doctype NUMERIC := 1000054;
  v_id NUMERIC;
BEGIN
  -- Prefer a non-employee user contact for agency-style row
  SELECT u.ad_user_id INTO v_user_agency
  FROM ad_user u
  JOIN c_bpartner bp ON bp.c_bpartner_id = u.c_bpartner_id
  WHERE u.isactive = 'Y'
    AND u.ad_client_id = v_client
    AND bp.isemployee = 'N'
    AND u.ad_user_id <> v_user_emp
  ORDER BY u.ad_user_id
  LIMIT 1;

  IF v_user_agency IS NULL THEN
    v_user_agency := v_user_emp;
    RAISE NOTICE 'No non-employee user found; agency seed will reuse employee user %', v_user_emp;
  END IF;

  SELECT aberp_shift_type_id INTO v_shift_type
  FROM aberp_shift_type
  WHERE isactive = 'Y'
  ORDER BY aberp_shift_type_id
  LIMIT 1;

  -- Row without breaks (employee)
  IF NOT EXISTS (
    SELECT 1 FROM aberp_timesheetandexpenses
    WHERE aberp_timesheetandexpenses_uu = 'e1a2b3c4-d5e6-4789-a012-111100000001'
  ) THEN
    v_id := nextid(
      (SELECT ad_sequence_id::integer FROM ad_sequence
       WHERE name = 'AbERP_TimesheetAndExpenses' AND istableid = 'Y' LIMIT 1),
      'N'::varchar
    );
    INSERT INTO aberp_timesheetandexpenses (
      aberp_timesheetandexpenses_id, ad_client_id, ad_org_id, aberp_timesheetandexpenses_uu,
      isactive, created, createdby, updated, updatedby,
      aberp_user_contact_id, startdate, enddate,
      aberp_break_start, aberp_break_end, aberp_shift_type_id,
      c_doctype_id, aberp_claimable, processed, documentno
    ) VALUES (
      v_id, v_client, v_org, 'e1a2b3c4-d5e6-4789-a012-111100000001',
      'Y', NOW(), 100, NOW(), 100,
      v_user_emp, TIMESTAMP '2024-11-01 09:00:00', TIMESTAMP '2024-11-01 17:00:00',
      NULL, NULL, v_shift_type,
      v_doctype, 'N', 'N', 'SAW010-NOBRK'
    );
    RAISE NOTICE 'Seeded no-break timesheet id=%', v_id;
  END IF;

  -- Agency-style row with breaks
  IF NOT EXISTS (
    SELECT 1 FROM aberp_timesheetandexpenses
    WHERE aberp_timesheetandexpenses_uu = 'e1a2b3c4-d5e6-4789-a012-111100000002'
  ) THEN
    v_id := nextid(
      (SELECT ad_sequence_id::integer FROM ad_sequence
       WHERE name = 'AbERP_TimesheetAndExpenses' AND istableid = 'Y' LIMIT 1),
      'N'::varchar
    );
    INSERT INTO aberp_timesheetandexpenses (
      aberp_timesheetandexpenses_id, ad_client_id, ad_org_id, aberp_timesheetandexpenses_uu,
      isactive, created, createdby, updated, updatedby,
      aberp_user_contact_id, startdate, enddate,
      aberp_break_start, aberp_break_end, aberp_shift_type_id,
      c_doctype_id, aberp_claimable, processed, documentno, description
    ) VALUES (
      v_id, v_client, v_org, 'e1a2b3c4-d5e6-4789-a012-111100000002',
      'Y', NOW(), 100, NOW(), 100,
      v_user_agency, TIMESTAMP '2024-11-02 08:00:00', TIMESTAMP '2024-11-02 16:00:00',
      TIMESTAMP '2024-11-02 12:00:00', TIMESTAMP '2024-11-02 12:30:00', v_shift_type,
      v_doctype, 'N', 'N', 'SAW010-AGENCY', 'SAW010 agency seed'
    );
    RAISE NOTICE 'Seeded agency timesheet id=% user=%', v_id, v_user_agency;
  END IF;
END $$;

SELECT aberp_timesheetandexpenses_id, documentno, aberp_user_contact_id,
       startdate, aberp_break_start, aberp_break_end, aberp_timesheetandexpenses_uu
FROM aberp_timesheetandexpenses
WHERE aberp_timesheetandexpenses_uu IN (
        'e1a2b3c4-d5e6-4789-a012-111100000001',
        'e1a2b3c4-d5e6-4789-a012-111100000002'
      )
   OR aberp_timesheetandexpenses_id = 1000095
ORDER BY startdate;
