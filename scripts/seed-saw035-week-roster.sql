-- =============================================================================
-- SAW035 — Full week roster for 5 Support Workers (this calendar week)
-- =============================================================================
-- Target: AbilityERP staging EC2 (54.206.8.250)
-- Prefix: SAW035 Week Roster %
-- Creates Mon–Sun day shifts (09:00–15:00), Published, filled staff line each.
-- Idempotent: deletes previous SAW035 Week Roster rows then recreates.
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
  v_shift_type numeric := 1000000; -- Service Delivery - Direct
  v_loc    numeric := 1000014;     -- Rover Road
  v_status numeric := 1000040;     -- Published
  v_price  numeric := 1000000;

  -- week containing CURRENT_DATE (Mon..Sun)
  v_monday date := date_trunc('week', CURRENT_DATE)::date; -- ISO Monday
  v_day date;
  v_start timestamp;
  v_end timestamp;
  v_dow text;

  v_shift numeric;
  v_doc text;
  v_staff numeric;
  v_name text;
  i int;
  e int;

  v_users numeric[] := ARRAY[1000107, 1000157, 1000004, 1000194, 1000158];
  v_bps   numeric[] := ARRAY[1000155, 1000185, 1000002, 1000226, 1000186];
  v_names text[]    := ARRAY['Ella Williams', 'Gabriela Wilson', 'Isla Robinson', 'Mary Reid', 'Oliver Williams'];
BEGIN
  IF NOT EXISTS (SELECT 1 FROM r_status WHERE r_status_id = v_status AND isactive='Y') THEN
    SELECT r_status_id INTO v_status FROM r_status
    WHERE name ILIKE 'Publish%' AND isactive='Y' ORDER BY 1 LIMIT 1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM aberp_shift_type WHERE aberp_shift_type_id = v_shift_type) THEN
    SELECT aberp_shift_type_id INTO v_shift_type
    FROM aberp_shift_type WHERE ad_client_id IN (0, v_client) AND isactive='Y' ORDER BY 1 LIMIT 1;
  END IF;
  IF v_status IS NULL OR v_shift_type IS NULL THEN
    RAISE EXCEPTION 'Missing Published status or shift type';
  END IF;

  -- Cleanup prior seed
  DELETE FROM aberp_rostered_shiftstaff
  WHERE aberp_rostered_shift_id IN (
    SELECT aberp_rostered_shift_id FROM aberp_rostered_shift WHERE name LIKE 'SAW035 Week Roster%'
  );
  DELETE FROM aberp_rostered_shiftreceiver
  WHERE aberp_rostered_shift_id IN (
    SELECT aberp_rostered_shift_id FROM aberp_rostered_shift WHERE name LIKE 'SAW035 Week Roster%'
  );
  DELETE FROM aberp_rostered_shift WHERE name LIKE 'SAW035 Week Roster%';

  RAISE NOTICE 'SAW035 week Monday = %', v_monday;

  FOR e IN 1..5 LOOP
    FOR i IN 0..6 LOOP
      v_day := v_monday + i;
      v_start := v_day + time '09:00';
      v_end   := v_day + time '15:00';
      v_dow := trim(to_char(v_day, 'Day'));
      v_name := format('SAW035 Week Roster - %s - %s %s',
        v_names[e], v_dow, to_char(v_day, 'DD Mon'));

      v_shift := pg_temp.next_seq('AbERP_Rostered_Shift');
      v_doc := pg_temp.next_seq('DocumentNo_AbERP_Rostered_Shift')::text;
      v_staff := pg_temp.next_seq('AbERP_Rostered_ShiftStaff');

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
        v_doc, v_name, 'SAW035 full week round for PWA / WebUI roster testing',
        v_start, v_end, v_start, v_end,
        v_dow, v_dow,
        v_shift_type, v_loc, v_status,
        'N', 'N',
        'N', 'N', 'N',
        'N', 0, 6.00, 'N',
        'N', 'N'
      );

      INSERT INTO aberp_rostered_shiftstaff (
        aberp_rostered_shiftstaff_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, line,
        aberp_rostered_shift_id, m_pricelist_id,
        c_bpartner_staff_id, aberp_user_contact_id,
        aberp_units, aberp_listprice, aberp_estimatedcost,
        aberp_clockin, aberp_clockout,
        aberp_clockincreatedby, aberp_clockoutcreatedby,
        aberp_clockinupdatedby, aberp_clockoutupdatedby
      ) VALUES (
        v_staff, v_client, v_org, 'Y',
        NOW(), v_user, NOW(), v_user, 10,
        v_shift, v_price,
        v_bps[e], v_users[e],
        0, 0, 0,
        'N', 'N',
        v_user, v_user, v_user, v_user
      );
    END LOOP;
  END LOOP;

  RAISE NOTICE 'SAW035 created 35 shifts (5 employees x 7 days)';
END $$;

-- Verify
SELECT bp.name AS employee,
       COUNT(*) AS shifts,
       MIN(s.startdate)::date AS first_day,
       MAX(s.startdate)::date AS last_day
FROM aberp_rostered_shift s
JOIN aberp_rostered_shiftstaff ss ON ss.aberp_rostered_shift_id = s.aberp_rostered_shift_id AND ss.isactive='Y'
JOIN c_bpartner bp ON bp.c_bpartner_id = ss.c_bpartner_staff_id
WHERE s.name LIKE 'SAW035 Week Roster%'
GROUP BY bp.name
ORDER BY 1;

SELECT COUNT(*) AS total_shifts
FROM aberp_rostered_shift
WHERE name LIKE 'SAW035 Week Roster%';
