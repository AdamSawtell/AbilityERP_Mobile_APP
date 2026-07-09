-- Seed available rostered shifts with pending REQ response log rows for Accept Shift testing.
-- Run: sudo -u postgres psql -d idempiere -f seed-accept-shift-test-data.sql
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
  v_org numeric := 0;
  v_user numeric := 100;
  v_shift_type numeric := 1000000;
  v_location numeric := 1000014;
  v_status_drafted numeric := 1000039;
  v_price_list numeric := 1000000;

  v_shift1 numeric;
  v_shift2 numeric;
  v_shift3 numeric;
  v_shift4 numeric;
  v_doc1 text;
  v_doc2 text;
  v_doc3 text;
  v_doc4 text;
  v_staff1 numeric;
  v_staff2 numeric;
  v_staff3 numeric;
  v_staff4 numeric;
  v_log1 numeric;
  v_log2 numeric;
  v_log3 numeric;
  v_log4 numeric;

  -- Support workers
  v_ella_user numeric := 1000107;
  v_gabriela_user numeric := 1000157;
  v_oliver_user numeric := 1000158;
BEGIN
  v_shift1 := pg_temp.next_seq('AbERP_Rostered_Shift');
  v_shift2 := pg_temp.next_seq('AbERP_Rostered_Shift');
  v_shift3 := pg_temp.next_seq('AbERP_Rostered_Shift');
  v_shift4 := pg_temp.next_seq('AbERP_Rostered_Shift');
  v_doc1 := pg_temp.next_seq('DocumentNo_AbERP_Rostered_Shift')::text;
  v_doc2 := pg_temp.next_seq('DocumentNo_AbERP_Rostered_Shift')::text;
  v_doc3 := pg_temp.next_seq('DocumentNo_AbERP_Rostered_Shift')::text;
  v_doc4 := pg_temp.next_seq('DocumentNo_AbERP_Rostered_Shift')::text;
  v_staff1 := pg_temp.next_seq('AbERP_Rostered_ShiftStaff');
  v_staff2 := pg_temp.next_seq('AbERP_Rostered_ShiftStaff');
  v_staff3 := pg_temp.next_seq('AbERP_Rostered_ShiftStaff');
  v_staff4 := pg_temp.next_seq('AbERP_Rostered_ShiftStaff');
  v_log1 := pg_temp.next_seq('AbERP_RosteredResponseLog');
  v_log2 := pg_temp.next_seq('AbERP_RosteredResponseLog');
  v_log3 := pg_temp.next_seq('AbERP_RosteredResponseLog');
  v_log4 := pg_temp.next_seq('AbERP_RosteredResponseLog');

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
  ) VALUES
  (v_shift1, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user,
   v_doc1, 'Accept Test - Ella REQ', 'Seeded REQ for Accept Shift button test',
   '2026-07-10 09:00:00', '2026-07-10 15:00:00', '2026-07-10 09:00:00', '2026-07-10 15:00:00',
   'Thursday', 'Thursday', v_shift_type, v_location, v_status_drafted,
   'N', 'Y', 'N', 'N', 'N', 'N', 0, 6.00, 'N', 'Y', 'N'),
  (v_shift2, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user,
   v_doc2, 'Accept Test - Multi REQ', 'Seeded with two pending REQ workers',
   '2026-07-11 10:00:00', '2026-07-11 16:00:00', '2026-07-11 10:00:00', '2026-07-11 16:00:00',
   'Friday', 'Friday', v_shift_type, v_location, v_status_drafted,
   'N', 'Y', 'N', 'N', 'N', 'N', 0, 6.00, 'N', 'Y', 'N'),
  (v_shift3, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user,
   v_doc3, 'Accept Test - Oliver REQ', 'Seeded REQ for Oliver Williams',
   '2026-07-12 08:00:00', '2026-07-12 14:00:00', '2026-07-12 08:00:00', '2026-07-12 14:00:00',
   'Saturday', 'Saturday', v_shift_type, v_location, v_status_drafted,
   'N', 'Y', 'N', 'N', 'N', 'N', 0, 6.00, 'N', 'Y', 'N'),
  (v_shift4, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user,
   v_doc4, 'Accept Test - Open Available', 'Available shift with no requests yet',
   '2026-07-13 09:00:00', '2026-07-13 15:00:00', '2026-07-13 09:00:00', '2026-07-13 15:00:00',
   'Sunday', 'Sunday', v_shift_type, v_location, v_status_drafted,
   'N', 'Y', 'N', 'N', 'N', 'N', 0, 6.00, 'N', 'N', 'N');

  INSERT INTO aberp_rostered_shiftstaff (
    aberp_rostered_shiftstaff_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby, line,
    aberp_rostered_shift_id, m_pricelist_id,
    aberp_units, aberp_listprice, aberp_estimatedcost,
    aberp_clockin, aberp_clockout,
    aberp_clockincreatedby, aberp_clockoutcreatedby,
    aberp_clockinupdatedby, aberp_clockoutupdatedby
  ) VALUES
  (v_staff1, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, 10, v_shift1, v_price_list, 0, 0, 0, 'N', 'N', v_user, v_user, v_user, v_user),
  (v_staff2, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, 10, v_shift2, v_price_list, 0, 0, 0, 'N', 'N', v_user, v_user, v_user, v_user),
  (v_staff3, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, 10, v_shift3, v_price_list, 0, 0, 0, 'N', 'N', v_user, v_user, v_user, v_user),
  (v_staff4, v_client, v_org, 'Y', NOW(), v_user, NOW(), v_user, 10, v_shift4, v_price_list, 0, 0, 0, 'N', 'N', v_user, v_user, v_user, v_user);

  INSERT INTO aberp_rosteredresponselog (
    aberp_rosteredresponselog_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby,
    aberp_user_contact_id, aberp_rosteredresponse, aberp_rostered_shift_id,
    issuperseded, isreviewed
  ) VALUES
  (v_log1, v_client, v_org, 'Y', NOW(), v_ella_user, NOW(), v_ella_user,
   v_ella_user, 'REQ', v_shift1, 'N', 'N'),
  (v_log2, v_client, v_org, 'Y', NOW(), v_ella_user, NOW(), v_ella_user,
   v_ella_user, 'REQ', v_shift2, 'N', 'N'),
  (v_log3, v_client, v_org, 'Y', NOW(), v_gabriela_user, NOW(), v_gabriela_user,
   v_gabriela_user, 'REQ', v_shift2, 'N', 'N'),
  (v_log4, v_client, v_org, 'Y', NOW(), v_oliver_user, NOW(), v_oliver_user,
   v_oliver_user, 'REQ', v_shift3, 'N', 'N');

  RAISE NOTICE 'Created shifts: % (doc %), % (doc %), % (doc %), % (doc %)',
    v_shift1, v_doc1, v_shift2, v_doc2, v_shift3, v_doc3, v_shift4, v_doc4;
  RAISE NOTICE 'REQ logs: % Ella on %, % Ella + % Gabriela on %, % Oliver on %',
    v_log1, v_shift1, v_log2, v_log3, v_shift2, v_log4, v_shift3;
END $$;

-- Summary
SELECT rs.aberp_rostered_shift_id, rs.documentno, rs.name, rs.aberp_isshowingasavailable,
       rs.r_status_id, st.name AS status_name
FROM aberp_rostered_shift rs
LEFT JOIN r_status st ON st.r_status_id = rs.r_status_id
WHERE rs.name LIKE 'Accept Test%'
ORDER BY rs.aberp_rostered_shift_id;

SELECT rl.aberp_rosteredresponselog_id, rs.documentno, rs.name AS shift_name,
       u.name AS worker, rl.aberp_rosteredresponse, rl.isreviewed, rl.issuperseded
FROM aberp_rosteredresponselog rl
JOIN aberp_rostered_shift rs ON rs.aberp_rostered_shift_id = rl.aberp_rostered_shift_id
JOIN ad_user u ON u.ad_user_id = rl.aberp_user_contact_id
WHERE rs.name LIKE 'Accept Test%'
ORDER BY rs.documentno, rl.aberp_rosteredresponselog_id;

SELECT rs.documentno, COUNT(ss.aberp_rostered_shiftstaff_id) AS staff_lines,
       SUM(CASE WHEN COALESCE(ss.aberp_user_contact_id,0) > 0 THEN 1 ELSE 0 END) AS assigned
FROM aberp_rostered_shift rs
LEFT JOIN aberp_rostered_shiftstaff ss ON ss.aberp_rostered_shift_id = rs.aberp_rostered_shift_id AND ss.isactive = 'Y'
WHERE rs.name LIKE 'Accept Test%'
GROUP BY rs.documentno
ORDER BY rs.documentno;
