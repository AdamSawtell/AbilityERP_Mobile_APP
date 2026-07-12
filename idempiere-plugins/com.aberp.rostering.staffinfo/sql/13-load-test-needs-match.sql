-- Load / correctness test for Staff Rostering Info filters
-- (leave + overlap + Related Rostering Needs with shift-window credential validity)
SET search_path TO adempiere;

\echo === Shift under test: 1000490 (DocumentNo 1000459) ===
SELECT documentno, startdate, enddate,
       (SELECT count(*) FROM aberp_related_rostering_needs_v rv
         WHERE rv.aberp_rostered_shift_id = s.aberp_rostered_shift_id AND rv.aberp_needtype='CRD') AS crd_needs
FROM aberp_rostered_shift s
WHERE aberp_rostered_shift_id = 1000490;

\echo === Matched staff (needs + shift-window cred validity) ===
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT au.ad_user_id, au.name
FROM ad_user au
INNER JOIN c_bpartner bp ON (bp.c_bpartner_id = au.c_bpartner_id AND bp.isactive = 'Y')
LEFT JOIN c_job jb ON (jb.c_job_id = bp.c_job_id AND jb.isactive = 'Y')
WHERE au.isactive = 'Y'
  AND bp.isemployee = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM aberp_unavailability_leave ul
    WHERE ul.aberp_user_contact_id = au.ad_user_id AND ul.isactive = 'Y'
      AND UPPER(COALESCE(ul.aberp_approverstatus,'')) = 'AP'
      AND ul.startdate <= TIMESTAMP '2026-07-13 15:00:00'
      AND ul.enddate >= TIMESTAMP '2026-07-13 09:00:00'
  )
  AND NOT EXISTS (
    SELECT 1 FROM aberp_rostered_shiftstaff rss
    INNER JOIN aberp_rostered_shift rs ON (
      rs.aberp_rostered_shift_id = rss.aberp_rostered_shift_id
      AND rs.isactive = 'Y' AND COALESCE(rs.aberp_isshiftrosteredtemplate,'N') = 'N')
    WHERE rss.aberp_user_contact_id = au.ad_user_id AND rss.isactive = 'Y'
      AND rs.startdate <= TIMESTAMP '2026-07-13 15:00:00'
      AND rs.enddate >= TIMESTAMP '2026-07-13 09:00:00'
      AND rs.aberp_rostered_shift_id <> 1000490
  )
  AND NOT EXISTS (
    SELECT 1 FROM aberp_related_rostering_needs_v rv
    WHERE rv.aberp_rostered_shift_id = 1000490
      AND rv.isactive = 'Y' AND rv.aberp_needtype = 'CRD'
      AND COALESCE(rv.aberp_credentials_id,0) > 0
      AND NOT EXISTS (
        SELECT 1 FROM aberp_credentialassignment ca
        WHERE ca.isactive = 'Y'
          AND ca.aberp_credentials_id = rv.aberp_credentials_id
          AND (ca.aberp_user_contact_id = au.ad_user_id OR ca.c_bpartner_staff_id = bp.c_bpartner_id)
          AND (ca.startdate IS NULL OR ca.startdate <= TIMESTAMP '2026-07-13 09:00:00')
          AND (ca.aberp_expirydate IS NULL OR ca.aberp_expirydate >= TIMESTAMP '2026-07-13 15:00:00')
      )
  )
ORDER BY au.name
LIMIT 50;

\echo === Result rows ===
SELECT au.name
FROM ad_user au
INNER JOIN c_bpartner bp ON (bp.c_bpartner_id = au.c_bpartner_id AND bp.isactive = 'Y')
WHERE au.isactive = 'Y' AND bp.isemployee = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM aberp_related_rostering_needs_v rv
    WHERE rv.aberp_rostered_shift_id = 1000490
      AND rv.isactive = 'Y' AND rv.aberp_needtype = 'CRD'
      AND COALESCE(rv.aberp_credentials_id,0) > 0
      AND NOT EXISTS (
        SELECT 1 FROM aberp_credentialassignment ca
        WHERE ca.isactive = 'Y'
          AND ca.aberp_credentials_id = rv.aberp_credentials_id
          AND (ca.aberp_user_contact_id = au.ad_user_id OR ca.c_bpartner_staff_id = bp.c_bpartner_id)
          AND (ca.startdate IS NULL OR ca.startdate <= TIMESTAMP '2026-07-13 09:00:00')
          AND (ca.aberp_expirydate IS NULL OR ca.aberp_expirydate >= TIMESTAMP '2026-07-13 15:00:00')
      )
  )
ORDER BY au.name;

\echo === Load burst: 50 identical filtered queries ===
DO $$
DECLARE
  i int;
  t0 timestamptz;
  t1 timestamptz;
  n int;
  total_ms numeric := 0;
  max_ms numeric := 0;
  ms numeric;
BEGIN
  FOR i IN 1..50 LOOP
    t0 := clock_timestamp();
    SELECT count(*) INTO n
    FROM ad_user au
    INNER JOIN c_bpartner bp ON (bp.c_bpartner_id = au.c_bpartner_id AND bp.isactive = 'Y')
    WHERE au.isactive = 'Y' AND bp.isemployee = 'Y'
      AND NOT EXISTS (
        SELECT 1 FROM aberp_unavailability_leave ul
        WHERE ul.aberp_user_contact_id = au.ad_user_id AND ul.isactive = 'Y'
          AND UPPER(COALESCE(ul.aberp_approverstatus,'')) = 'AP'
          AND ul.startdate <= TIMESTAMP '2026-07-13 15:00:00'
          AND ul.enddate >= TIMESTAMP '2026-07-13 09:00:00'
      )
      AND NOT EXISTS (
        SELECT 1 FROM aberp_rostered_shiftstaff rss
        INNER JOIN aberp_rostered_shift rs ON (
          rs.aberp_rostered_shift_id = rss.aberp_rostered_shift_id
          AND rs.isactive = 'Y' AND COALESCE(rs.aberp_isshiftrosteredtemplate,'N') = 'N')
        WHERE rss.aberp_user_contact_id = au.ad_user_id AND rss.isactive = 'Y'
          AND rs.startdate <= TIMESTAMP '2026-07-13 15:00:00'
          AND rs.enddate >= TIMESTAMP '2026-07-13 09:00:00'
          AND rs.aberp_rostered_shift_id <> 1000490
      )
      AND NOT EXISTS (
        SELECT 1 FROM aberp_related_rostering_needs_v rv
        WHERE rv.aberp_rostered_shift_id = 1000490
          AND rv.isactive = 'Y' AND rv.aberp_needtype = 'CRD'
          AND COALESCE(rv.aberp_credentials_id,0) > 0
          AND NOT EXISTS (
            SELECT 1 FROM aberp_credentialassignment ca
            WHERE ca.isactive = 'Y'
              AND ca.aberp_credentials_id = rv.aberp_credentials_id
              AND (ca.aberp_user_contact_id = au.ad_user_id OR ca.c_bpartner_staff_id = bp.c_bpartner_id)
              AND (ca.startdate IS NULL OR ca.startdate <= TIMESTAMP '2026-07-13 09:00:00')
              AND (ca.aberp_expirydate IS NULL OR ca.aberp_expirydate >= TIMESTAMP '2026-07-13 15:00:00')
          )
      );
    t1 := clock_timestamp();
    ms := EXTRACT(EPOCH FROM (t1 - t0)) * 1000;
    total_ms := total_ms + ms;
    IF ms > max_ms THEN max_ms := ms; END IF;
  END LOOP;
  RAISE NOTICE 'load_burst_50 avg_ms=% max_ms=% last_count=%',
    round(total_ms/50.0, 3), round(max_ms, 3), n;
END $$;
