-- SAW036: attach Support Receivers (clients) to SAW035 week roster shifts
-- so workers can open client details from Schedule / Clients.
-- Clients (rich care plans first): Benjamin, Bernadette, Amelia, Jennifer, David
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
  v_org numeric := 1000002;
  v_user numeric := 100;
  v_clients numeric[] := ARRAY[1000055, 1000049, 1000156, 1000058, 1000054]; -- Ben, Bern, Amelia, Jen, David
  r record;
  i int := 0;
  v_bp numeric;
  v_recv numeric;
BEGIN
  DELETE FROM aberp_rostered_shiftreceiver
  WHERE aberp_rostered_shift_id IN (
    SELECT aberp_rostered_shift_id FROM aberp_rostered_shift WHERE name LIKE 'SAW035 Week Roster%'
  );

  FOR r IN
    SELECT aberp_rostered_shift_id
    FROM aberp_rostered_shift
    WHERE name LIKE 'SAW035 Week Roster%' AND isactive='Y'
    ORDER BY aberp_rostered_shift_id
  LOOP
    i := i + 1;
    v_bp := v_clients[((i - 1) % array_length(v_clients, 1)) + 1];
    v_recv := pg_temp.next_seq('AbERP_Rostered_ShiftReceiver');
    INSERT INTO aberp_rostered_shiftreceiver (
      aberp_rostered_shiftreceiver_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby, aberp_rostered_shiftreceiver_uu,
      aberp_rostered_shift_id, c_bpartner_id, line
    ) VALUES (
      v_recv, v_client, v_org, 'Y',
      NOW(), v_user, NOW(), v_user, md5(random()::text || clock_timestamp()::text),
      r.aberp_rostered_shift_id, v_bp, 10
    );
  END LOOP;

  RAISE NOTICE 'SAW036 attached receivers to % SAW035 shifts', i;
END $$;

SELECT bp.name AS client, COUNT(*) AS shifts
FROM aberp_rostered_shiftreceiver r
JOIN aberp_rostered_shift s ON s.aberp_rostered_shift_id = r.aberp_rostered_shift_id
JOIN c_bpartner bp ON bp.c_bpartner_id = r.c_bpartner_id
WHERE s.name LIKE 'SAW035 Week Roster%'
GROUP BY bp.name
ORDER BY 1;
