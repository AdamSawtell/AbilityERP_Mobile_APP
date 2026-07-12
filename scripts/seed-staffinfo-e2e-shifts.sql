-- =============================================================================
-- Staff Info E2E seed: 24 dummy shifts + receivers + complete needs + leave
-- =============================================================================
-- Prefix: StaffInfo Seed %
-- Client/Org: AbilityERP 1000002 / 1000002
-- Idempotent: deletes previous StaffInfo Seed rows then recreates.
--
-- Scenarios (name suffix):
--   01 Baseline vacant (no needs)
--   02 RS Rover Road CRD
--   03 RS First Aid CRD
--   04 RS GDR Male
--   05 RS GDR Female
--   06 RS Rover + Male
--   07 RS EMP exclude Ella
--   08 SR Amelia complete (Diabetes + Female + EMP Jack)
--   09 SR Rose Ni Male GDR
--   10 SR Amelia + Jennifer (Female pack on both)
--   11 RS 3-cred pack (Rover + First Aid + NDIS Screening)
--   12 Leave-overlap vacant (Ella AP leave covers window)
--   13 Leave-after vacant (Ella leave day after — should still list Ella)
--   14 Overlap-morning filled Blake
--   15 Overlap-afternoon vacant same day (Blake hidden)
--   16 Hard CRD unmatched smoke (Rover only)
--   17 Diabetes expiry edge (Theo expired)
--   18 Published + vacant second staff line
--   19 Multi vacant staff lines + Rover
--   20 SR Benjamin complete pack (Rover+Male+NDIS) — seeded SR rules
--   21 Past-window control (+30d Rover)
--   22 Female + Diabetes via Amelia (match intersection)
--   23 Male Rover NDIS via RS
--   24 Open available no needs (PWA-like)
-- =============================================================================

SET search_path TO adempiere;

CREATE OR REPLACE FUNCTION pg_temp.next_seq(seq_name text) RETURNS numeric LANGUAGE sql AS $$
  UPDATE ad_sequence
  SET currentnext = currentnext + incrementno
  WHERE name = seq_name
  RETURNING (currentnext - incrementno)::numeric;
$$;

DO $$
DECLARE
  v_client numeric := 1000002;
  v_org    numeric := 1000002;
  v_user   numeric := 100;
  v_shift_type numeric;
  v_loc_rover numeric := 1000014;
  v_loc_clean numeric := 1000254; -- Head Office (no LOC needs)
  v_status_draft numeric := 1000039;
  v_status_pub numeric := 1000040;
  v_price numeric := 1000000;

  -- credentials
  v_cred_rover numeric := 1000019;
  v_cred_fa    numeric := 1000001;
  v_cred_diab  numeric := 1000007;
  v_cred_ndis  numeric := 1000006;

  -- gender
  v_male numeric := 1000000;
  v_female numeric := 1000001;

  -- staff
  v_ella numeric := 1000107;   v_ella_bp numeric := 1000155;
  v_blake numeric := 1000162;  v_blake_bp numeric := 1000190;
  v_robert numeric := 1000193; v_robert_bp numeric := 1000225;
  v_mary numeric := 1000194;   v_mary_bp numeric := 1000226;
  v_oliver numeric := 1000158; v_oliver_bp numeric := 1000186;
  v_jack numeric := 1000005;

  -- support receivers
  v_amelia numeric := 1000156;
  v_rose_ni numeric := 1000193;
  v_jennifer numeric := 1000058;
  v_benjamin numeric := 1000055;

  v_leave_type numeric := 1000001; -- Annual Leave

  v_base date := CURRENT_DATE + 10;
  v_d date;
  v_shift numeric;
  v_doc text;
  v_staff numeric;
  v_recv numeric;
  v_need numeric;
  v_leave numeric;
  v_ca numeric;
  i int;
  v_name text;
  v_start timestamp;
  v_end timestamp;
  v_shift_morning numeric;
  v_doc_morning text;
BEGIN
  -- Resolve drafted status if hardcoded missing
  IF NOT EXISTS (SELECT 1 FROM r_status WHERE r_status_id = v_status_draft) THEN
    SELECT r_status_id INTO v_status_draft FROM r_status
    WHERE name ILIKE 'Draft%' AND isactive='Y' ORDER BY 1 LIMIT 1;
  END IF;
  SELECT aberp_shift_type_id INTO v_shift_type
  FROM aberp_shift_type WHERE ad_client_id IN (0, v_client) AND isactive='Y'
  ORDER BY 1 LIMIT 1;

  IF v_shift_type IS NULL OR v_status_draft IS NULL THEN
    RAISE EXCEPTION 'Missing shift type or draft status';
  END IF;

  ------------------------------------------------------------------
  -- Cleanup previous seed
  ------------------------------------------------------------------
  DELETE FROM aberp_credentialassignment
  WHERE description = 'StaffInfo Seed cred';

  DELETE FROM aberp_unavailability_leave
  WHERE note = 'StaffInfo Seed leave';

  DELETE FROM aberp_sr_needs_rules
  WHERE comments = 'StaffInfo Seed need'
     OR aberp_rostered_shift_id IN (
          SELECT aberp_rostered_shift_id FROM aberp_rostered_shift WHERE name LIKE 'StaffInfo Seed%'
        );

  -- Jennifer/Benjamin seed SR packs (association SR, keyed by BP)
  DELETE FROM aberp_sr_needs_rules
  WHERE comments = 'StaffInfo Seed SR pack';

  DELETE FROM aberp_rostered_shiftreceiver
  WHERE aberp_rostered_shift_id IN (
    SELECT aberp_rostered_shift_id FROM aberp_rostered_shift WHERE name LIKE 'StaffInfo Seed%'
  );

  DELETE FROM aberp_rostered_shiftstaff
  WHERE aberp_rostered_shift_id IN (
    SELECT aberp_rostered_shift_id FROM aberp_rostered_shift WHERE name LIKE 'StaffInfo Seed%'
  );

  DELETE FROM aberp_rostered_shift WHERE name LIKE 'StaffInfo Seed%';

  ------------------------------------------------------------------
  -- Ensure seed SR packs on Jennifer (Female + Diabetes) and Benjamin (Male + Rover + NDIS)
  ------------------------------------------------------------------
  -- Jennifer: GDR Female + CRD Diabetes
  v_need := pg_temp.next_seq('AbERP_SR_Needs_Rules');
  INSERT INTO aberp_sr_needs_rules (
    aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
    aberp_needtype, aberp_needsassociation, aberp_gender_id, c_bpartner_id, comments
  ) VALUES (
    v_need, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
    'GDR', 'SR', v_female, v_jennifer, 'StaffInfo Seed SR pack'
  );
  v_need := pg_temp.next_seq('AbERP_SR_Needs_Rules');
  INSERT INTO aberp_sr_needs_rules (
    aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
    aberp_needtype, aberp_needsassociation, aberp_credentials_id, c_bpartner_id, comments
  ) VALUES (
    v_need, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
    'CRD', 'SR', v_cred_diab, v_jennifer, 'StaffInfo Seed SR pack'
  );

  -- Amelia: active Female GDR (production GDR expired 2023-11-01)
  v_need := pg_temp.next_seq('AbERP_SR_Needs_Rules');
  INSERT INTO aberp_sr_needs_rules (
    aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
    aberp_needtype, aberp_needsassociation, aberp_gender_id, c_bpartner_id, comments
  ) VALUES (
    v_need, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
    'GDR', 'SR', v_female, v_amelia, 'StaffInfo Seed SR pack'
  );

  -- Benjamin: GDR Male + Rover + NDIS
  v_need := pg_temp.next_seq('AbERP_SR_Needs_Rules');
  INSERT INTO aberp_sr_needs_rules (
    aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
    aberp_needtype, aberp_needsassociation, aberp_gender_id, c_bpartner_id, comments
  ) VALUES (
    v_need, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
    'GDR', 'SR', v_male, v_benjamin, 'StaffInfo Seed SR pack'
  );
  v_need := pg_temp.next_seq('AbERP_SR_Needs_Rules');
  INSERT INTO aberp_sr_needs_rules (
    aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
    aberp_needtype, aberp_needsassociation, aberp_credentials_id, c_bpartner_id, comments
  ) VALUES (
    v_need, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
    'CRD', 'SR', v_cred_rover, v_benjamin, 'StaffInfo Seed SR pack'
  );
  v_need := pg_temp.next_seq('AbERP_SR_Needs_Rules');
  INSERT INTO aberp_sr_needs_rules (
    aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
    aberp_needtype, aberp_needsassociation, aberp_credentials_id, c_bpartner_id, comments
  ) VALUES (
    v_need, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
    'CRD', 'SR', v_cred_ndis, v_benjamin, 'StaffInfo Seed SR pack'
  );

  -- Extend Rover Road for Blake/Robert/Mary covering seed windows (Jul–Sep 2026-ish)
  FOREACH v_ca IN ARRAY ARRAY[v_blake, v_robert, v_mary, v_oliver]
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM aberp_credentialassignment
      WHERE aberp_user_contact_id = v_ca AND aberp_credentials_id = v_cred_rover
        AND isactive='Y'
        AND (aberp_expirydate IS NULL OR aberp_expirydate >= (v_base + 40))
        AND (startdate IS NULL OR startdate <= v_base)
    ) THEN
      INSERT INTO aberp_credentialassignment (
        aberp_credentialassignment_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_credentialassignment_uu,
        aberp_credentials_id, aberp_user_contact_id,
        c_bpartner_staff_id, startdate, aberp_expirydate, description, name
      ) VALUES (
        pg_temp.next_seq('AbERP_CredentialAssignment'), v_client, v_org, 'Y',
        NOW(), v_user, NOW(), v_user, md5(random()::text),
        v_cred_rover, v_ca,
        CASE v_ca
          WHEN v_blake THEN v_blake_bp
          WHEN v_robert THEN v_robert_bp
          WHEN v_oliver THEN v_oliver_bp
          ELSE v_mary_bp
        END,
        v_base - 30, v_base + 120, 'StaffInfo Seed cred', 'StaffInfo Seed Rover'
      );
    END IF;
  END LOOP;

  -- Helper inline via repeated block: create shift
  -- We'll loop scenarios 1..24

  FOR i IN 1..24 LOOP
    v_d := v_base + ((i - 1) % 14);
    -- special same-day for 14/15
    IF i = 14 OR i = 15 THEN
      v_d := v_base + 3;
    END IF;

    IF i = 14 THEN
      v_start := v_d + time '08:00';
      v_end   := v_d + time '14:00'; -- overlaps afternoon
    ELSIF i = 15 THEN
      v_start := v_d + time '12:00';
      v_end   := v_d + time '17:00';
    ELSE
      v_start := v_d + time '09:00';
      v_end   := v_d + time '15:00';
    END IF;

    v_name := CASE i
      WHEN 1 THEN 'StaffInfo Seed 01 Baseline vacant'
      WHEN 2 THEN 'StaffInfo Seed 02 RS Rover CRD'
      WHEN 3 THEN 'StaffInfo Seed 03 RS First Aid CRD'
      WHEN 4 THEN 'StaffInfo Seed 04 RS GDR Male'
      WHEN 5 THEN 'StaffInfo Seed 05 RS GDR Female'
      WHEN 6 THEN 'StaffInfo Seed 06 RS Rover+Male'
      WHEN 7 THEN 'StaffInfo Seed 07 RS EMP exclude Ella'
      WHEN 8 THEN 'StaffInfo Seed 08 SR Amelia complete'
      WHEN 9 THEN 'StaffInfo Seed 09 SR Rose Ni Male'
      WHEN 10 THEN 'StaffInfo Seed 10 SR Amelia+Jennifer'
      WHEN 11 THEN 'StaffInfo Seed 11 RS 3-cred pack'
      WHEN 12 THEN 'StaffInfo Seed 12 Leave-overlap Ella'
      WHEN 13 THEN 'StaffInfo Seed 13 Leave-after Ella'
      WHEN 14 THEN 'StaffInfo Seed 14 Overlap-morning Blake filled'
      WHEN 15 THEN 'StaffInfo Seed 15 Overlap-afternoon vacant'
      WHEN 16 THEN 'StaffInfo Seed 16 LOC Rover unmatched smoke'
      WHEN 17 THEN 'StaffInfo Seed 17 Diabetes expiry edge'
      WHEN 18 THEN 'StaffInfo Seed 18 Published + vacant line'
      WHEN 19 THEN 'StaffInfo Seed 19 Multi vacant lines + Rover'
      WHEN 20 THEN 'StaffInfo Seed 20 SR Benjamin complete'
      WHEN 21 THEN 'StaffInfo Seed 21 +30d Rover window'
      WHEN 22 THEN 'StaffInfo Seed 22 SR Amelia Female+Diabetes'
      WHEN 23 THEN 'StaffInfo Seed 23 RS Male+Rover+NDIS'
      WHEN 24 THEN 'StaffInfo Seed 24 Open available no needs'
    END;

    IF i = 21 THEN
      v_start := (v_base + 30) + time '09:00';
      v_end   := (v_base + 30) + time '15:00';
      v_d := v_base + 30;
    END IF;

    v_shift := pg_temp.next_seq('AbERP_Rostered_Shift');
    v_doc := pg_temp.next_seq('DocumentNo_AbERP_Rostered_Shift')::text;

    INSERT INTO aberp_rostered_shift (
      aberp_rostered_shift_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      documentno, name, description,
      startdate, enddate, starttime, endtime,
      aberp_support_start_day, aberp_support_end_day,
      aberp_shift_type_id, aberp_masterlocation_id, r_status_id,
      aberp_isshiftrosteredtemplate, aberp_isshowingasavailable,
      aberp_transport_required, aberp_claimable, aberp_manual_cost_comp,
      aberp_isvalidated, aberp_shift_cost, aberp_timebasedqty, processed,
      aberp_isresponselogreviewrequired, iscancelled
    ) VALUES (
      v_shift, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user,
      v_doc, v_name, 'E2E Staff Info scenario ' || i,
      v_start, v_end, v_start, v_end,
      to_char(v_d, 'Day'), to_char(v_d, 'Day'),
      v_shift_type, CASE WHEN i IN (16, 21) THEN v_loc_rover ELSE v_loc_clean END,
      CASE WHEN i = 18 THEN v_status_pub ELSE v_status_draft END,
      'N', CASE WHEN i = 24 THEN 'Y' ELSE 'N' END,
      'N', 'N', 'N', 'N', 0, 6.00, 'N', 'N', 'N'
    );

    IF i = 14 THEN
      v_shift_morning := v_shift;
      v_doc_morning := v_doc;
    END IF;

    -- Staff line(s)
    v_staff := pg_temp.next_seq('AbERP_Rostered_ShiftStaff');
    INSERT INTO aberp_rostered_shiftstaff (
      aberp_rostered_shiftstaff_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby, line,
      aberp_rostered_shift_id, m_pricelist_id,
      aberp_units, aberp_listprice, aberp_estimatedcost,
      aberp_clockin, aberp_clockout,
      aberp_clockincreatedby, aberp_clockoutcreatedby,
      aberp_clockinupdatedby, aberp_clockoutupdatedby,
      aberp_user_contact_id, c_bpartner_staff_id
    ) VALUES (
      v_staff, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, 10,
      v_shift, v_price, 0, 0, 0, 'N', 'N', v_user, v_user, v_user, v_user,
      CASE WHEN i = 14 THEN v_blake ELSE NULL END,
      CASE WHEN i = 14 THEN v_blake_bp ELSE NULL END
    );

    IF i = 18 OR i = 19 THEN
      -- second vacant line
      v_staff := pg_temp.next_seq('AbERP_Rostered_ShiftStaff');
      INSERT INTO aberp_rostered_shiftstaff (
        aberp_rostered_shiftstaff_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, line,
        aberp_rostered_shift_id, m_pricelist_id,
        aberp_units, aberp_listprice, aberp_estimatedcost,
        aberp_clockin, aberp_clockout,
        aberp_clockincreatedby, aberp_clockoutcreatedby,
        aberp_clockinupdatedby, aberp_clockoutupdatedby
      ) VALUES (
        v_staff, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, 20,
        v_shift, v_price, 0, 0, 0, 'N', 'N', v_user, v_user, v_user, v_user
      );
      IF i = 18 THEN
        -- first line filled with Robert on published shift
        UPDATE aberp_rostered_shiftstaff
        SET aberp_user_contact_id = v_robert, c_bpartner_staff_id = v_robert_bp
        WHERE aberp_rostered_shift_id = v_shift AND line = 10;
      END IF;
    END IF;

    -- Receivers
    IF i IN (8, 10, 22) THEN
      v_recv := pg_temp.next_seq('AbERP_Rostered_ShiftReceiver');
      INSERT INTO aberp_rostered_shiftreceiver (
        aberp_rostered_shiftreceiver_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_rostered_shiftreceiver_uu,
        aberp_rostered_shift_id, c_bpartner_id, line
      ) VALUES (
        v_recv, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
        v_shift, v_amelia, 10
      );
    END IF;
    IF i = 9 THEN
      v_recv := pg_temp.next_seq('AbERP_Rostered_ShiftReceiver');
      INSERT INTO aberp_rostered_shiftreceiver (
        aberp_rostered_shiftreceiver_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_rostered_shiftreceiver_uu,
        aberp_rostered_shift_id, c_bpartner_id, line
      ) VALUES (
        v_recv, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
        v_shift, v_rose_ni, 10
      );
    END IF;
    IF i = 10 THEN
      v_recv := pg_temp.next_seq('AbERP_Rostered_ShiftReceiver');
      INSERT INTO aberp_rostered_shiftreceiver (
        aberp_rostered_shiftreceiver_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_rostered_shiftreceiver_uu,
        aberp_rostered_shift_id, c_bpartner_id, line
      ) VALUES (
        v_recv, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
        v_shift, v_jennifer, 20
      );
    END IF;
    IF i = 20 THEN
      v_recv := pg_temp.next_seq('AbERP_Rostered_ShiftReceiver');
      INSERT INTO aberp_rostered_shiftreceiver (
        aberp_rostered_shiftreceiver_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_rostered_shiftreceiver_uu,
        aberp_rostered_shift_id, c_bpartner_id, line
      ) VALUES (
        v_recv, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
        v_shift, v_benjamin, 10
      );
    END IF;

    -- RS needs (16 uses LOC Rover induction from location; still add nothing extra)
    IF i = 2 OR i = 19 OR i = 21 THEN
      INSERT INTO aberp_sr_needs_rules (
        aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
        aberp_needtype, aberp_needsassociation, aberp_credentials_id,
        aberp_rostered_shift_id, comments
      ) VALUES (
        pg_temp.next_seq('AbERP_SR_Needs_Rules'), v_client, v_org, 'Y',
        NOW(), v_user, NOW(), v_user, md5(random()::text),
        'CRD', 'RS', v_cred_rover, v_shift, 'StaffInfo Seed need'
      );
    END IF;
    IF i = 3 THEN
      INSERT INTO aberp_sr_needs_rules (
        aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
        aberp_needtype, aberp_needsassociation, aberp_credentials_id,
        aberp_rostered_shift_id, comments
      ) VALUES (
        pg_temp.next_seq('AbERP_SR_Needs_Rules'), v_client, v_org, 'Y',
        NOW(), v_user, NOW(), v_user, md5(random()::text),
        'CRD', 'RS', v_cred_fa, v_shift, 'StaffInfo Seed need'
      );
    END IF;
    IF i = 4 THEN
      INSERT INTO aberp_sr_needs_rules (
        aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
        aberp_needtype, aberp_needsassociation, aberp_gender_id,
        aberp_rostered_shift_id, comments
      ) VALUES (
        pg_temp.next_seq('AbERP_SR_Needs_Rules'), v_client, v_org, 'Y',
        NOW(), v_user, NOW(), v_user, md5(random()::text),
        'GDR', 'RS', v_male, v_shift, 'StaffInfo Seed need'
      );
    END IF;
    IF i = 5 THEN
      INSERT INTO aberp_sr_needs_rules (
        aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
        aberp_needtype, aberp_needsassociation, aberp_gender_id,
        aberp_rostered_shift_id, comments
      ) VALUES (
        pg_temp.next_seq('AbERP_SR_Needs_Rules'), v_client, v_org, 'Y',
        NOW(), v_user, NOW(), v_user, md5(random()::text),
        'GDR', 'RS', v_female, v_shift, 'StaffInfo Seed need'
      );
    END IF;
    IF i = 6 THEN
      INSERT INTO aberp_sr_needs_rules (
        aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
        aberp_needtype, aberp_needsassociation, aberp_credentials_id,
        aberp_rostered_shift_id, comments
      ) VALUES (
        pg_temp.next_seq('AbERP_SR_Needs_Rules'), v_client, v_org, 'Y',
        NOW(), v_user, NOW(), v_user, md5(random()::text),
        'CRD', 'RS', v_cred_rover, v_shift, 'StaffInfo Seed need'
      );
      INSERT INTO aberp_sr_needs_rules (
        aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
        aberp_needtype, aberp_needsassociation, aberp_gender_id,
        aberp_rostered_shift_id, comments
      ) VALUES (
        pg_temp.next_seq('AbERP_SR_Needs_Rules'), v_client, v_org, 'Y',
        NOW(), v_user, NOW(), v_user, md5(random()::text),
        'GDR', 'RS', v_male, v_shift, 'StaffInfo Seed need'
      );
    END IF;
    IF i = 7 THEN
      INSERT INTO aberp_sr_needs_rules (
        aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
        aberp_needtype, aberp_needsassociation, aberp_user_contact_id,
        aberp_rostered_shift_id, comments
      ) VALUES (
        pg_temp.next_seq('AbERP_SR_Needs_Rules'), v_client, v_org, 'Y',
        NOW(), v_user, NOW(), v_user, md5(random()::text),
        'EMP', 'RS', v_ella, v_shift, 'StaffInfo Seed need'
      );
    END IF;
    IF i = 11 THEN
      INSERT INTO aberp_sr_needs_rules (
        aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
        aberp_needtype, aberp_needsassociation, aberp_credentials_id,
        aberp_rostered_shift_id, comments
      ) VALUES
      (pg_temp.next_seq('AbERP_SR_Needs_Rules'), v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
       'CRD', 'RS', v_cred_rover, v_shift, 'StaffInfo Seed need'),
      (pg_temp.next_seq('AbERP_SR_Needs_Rules'), v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
       'CRD', 'RS', v_cred_fa, v_shift, 'StaffInfo Seed need'),
      (pg_temp.next_seq('AbERP_SR_Needs_Rules'), v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
       'CRD', 'RS', v_cred_ndis, v_shift, 'StaffInfo Seed need');
    END IF;
    IF i = 23 THEN
      INSERT INTO aberp_sr_needs_rules (
        aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
        aberp_needtype, aberp_needsassociation, aberp_credentials_id,
        aberp_rostered_shift_id, comments
      ) VALUES
      (pg_temp.next_seq('AbERP_SR_Needs_Rules'), v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
       'CRD', 'RS', v_cred_rover, v_shift, 'StaffInfo Seed need'),
      (pg_temp.next_seq('AbERP_SR_Needs_Rules'), v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
       'CRD', 'RS', v_cred_ndis, v_shift, 'StaffInfo Seed need');
      INSERT INTO aberp_sr_needs_rules (
        aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
        aberp_needtype, aberp_needsassociation, aberp_gender_id,
        aberp_rostered_shift_id, comments
      ) VALUES (
        pg_temp.next_seq('AbERP_SR_Needs_Rules'), v_client, v_org, 'Y',
        NOW(), v_user, NOW(), v_user, md5(random()::text),
        'GDR', 'RS', v_male, v_shift, 'StaffInfo Seed need'
      );
    END IF;
    IF i = 17 THEN
      INSERT INTO aberp_sr_needs_rules (
        aberp_sr_needs_rules_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_sr_needs_rules_uu,
        aberp_needtype, aberp_needsassociation, aberp_credentials_id,
        aberp_rostered_shift_id, comments
      ) VALUES (
        pg_temp.next_seq('AbERP_SR_Needs_Rules'), v_client, v_org, 'Y',
        NOW(), v_user, NOW(), v_user, md5(random()::text),
        'CRD', 'RS', v_cred_diab, v_shift, 'StaffInfo Seed need'
      );
    END IF;

    RAISE NOTICE 'Created % doc=% id=%', v_name, v_doc, v_shift;
  END LOOP;

  -- Ella approved leave covering scenario 12 window (v_base + 11 days? i=12 -> v_base+11)
  -- i=12: v_d = v_base + 11
  v_leave := pg_temp.next_seq('AbERP_Unavailability_Leave');
  INSERT INTO aberp_unavailability_leave (
    aberp_unavailability_leave_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, aberp_unavailability_leave_uu,
    c_bpartner_staff_id, aberp_user_contact_id,
    aberp_unavailability_type_id, startdate, enddate,
    aberp_approverstatus, aberp_submitterstatus, note, processed
  ) VALUES (
    v_leave, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
    v_ella_bp, v_ella, v_leave_type,
    (v_base + 11) + time '00:00', (v_base + 11) + time '23:59',
    'AP', 'AP', 'StaffInfo Seed leave', 'N'
  );

  -- Leave day after scenario 13 (i=13 -> v_base+12)
  v_leave := pg_temp.next_seq('AbERP_Unavailability_Leave');
  INSERT INTO aberp_unavailability_leave (
    aberp_unavailability_leave_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, aberp_unavailability_leave_uu,
    c_bpartner_staff_id, aberp_user_contact_id,
    aberp_unavailability_type_id, startdate, enddate,
    aberp_approverstatus, aberp_submitterstatus, note, processed
  ) VALUES (
    v_leave, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, md5(random()::text),
    v_ella_bp, v_ella, v_leave_type,
    (v_base + 13) + time '00:00', (v_base + 13) + time '23:59',
    'AP', 'AP', 'StaffInfo Seed leave', 'N'
  );

  RAISE NOTICE 'StaffInfo Seed complete. Morning overlap shift doc=% id=%', v_doc_morning, v_shift_morning;
END $$;

-- Catalogue
SELECT rs.documentno, rs.aberp_rostered_shift_id, rs.name,
       rs.startdate, rs.enddate,
       (SELECT count(*) FROM aberp_rostered_shiftreceiver r WHERE r.aberp_rostered_shift_id=rs.aberp_rostered_shift_id) AS receivers,
       (SELECT count(*) FROM aberp_related_rostering_needs_v v WHERE v.aberp_rostered_shift_id=rs.aberp_rostered_shift_id AND v.isactive='Y') AS needs,
       (SELECT string_agg(DISTINCT v.aberp_needtype, ',') FROM aberp_related_rostering_needs_v v WHERE v.aberp_rostered_shift_id=rs.aberp_rostered_shift_id AND v.isactive='Y') AS need_types
FROM aberp_rostered_shift rs
WHERE rs.name LIKE 'StaffInfo Seed%'
ORDER BY rs.name;
