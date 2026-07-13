-- SAW017 preflight
SET search_path TO adempiere;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ad_table WHERE tablename = 'AbERP_BookingGenerator') THEN
    RAISE EXCEPTION 'Missing table AbERP_BookingGenerator';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM ad_window
    WHERE ad_window_uu = 'de336034-bd4e-4445-b018-9c762c98d847' OR name = 'Booking Generator'
  ) THEN
    RAISE EXCEPTION 'Missing window Booking Generator';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM ad_process
    WHERE ad_process_uu = '6482f6b8-eaa3-4e7b-a8f6-4e263d44909b' OR value = 'Generate Bookings'
  ) THEN
    RAISE WARNING 'Generate Bookings AD process not found — bulk will error until Flamingo generator is installed';
  END IF;
END $$;

SELECT 'preflight ok' AS status;
