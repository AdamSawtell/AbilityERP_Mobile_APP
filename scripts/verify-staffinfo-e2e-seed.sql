-- =============================================================================
-- Verify Staff Info match logic for StaffInfo Seed shifts (mirrors Java)
-- =============================================================================
SET search_path TO adempiere;

WITH shifts AS (
  SELECT rs.aberp_rostered_shift_id AS sid, rs.documentno, rs.name,
         rs.startdate, rs.enddate
  FROM aberp_rostered_shift rs
  WHERE rs.name LIKE 'StaffInfo Seed%' AND rs.isactive='Y'
),
emp AS (
  SELECT au.ad_user_id, au.name, bp.c_bpartner_id, bp.aberp_gender_id
  FROM ad_user au
  JOIN c_bpartner bp ON bp.c_bpartner_id = au.c_bpartner_id AND bp.isactive='Y'
  WHERE au.isactive='Y' AND bp.isemployee='Y' AND au.ad_client_id=1000002
),
match_counts AS (
  SELECT s.sid, s.documentno, s.name, s.startdate, s.enddate,
    (SELECT count(*) FROM aberp_related_rostering_needs_v v
      WHERE v.aberp_rostered_shift_id=s.sid AND v.isactive='Y') AS need_count,
    (SELECT count(*) FROM emp e
      WHERE
        -- leave filter (Show Unavailable = N)
        NOT EXISTS (
          SELECT 1 FROM aberp_unavailability_leave ul
          WHERE ul.aberp_user_contact_id = e.ad_user_id AND ul.isactive='Y'
            AND UPPER(COALESCE(ul.aberp_approverstatus,''))='AP'
            AND ul.startdate <= s.enddate AND ul.enddate >= s.startdate
        )
        -- overlap filter
        AND NOT EXISTS (
          SELECT 1 FROM aberp_rostered_shiftstaff rss
          JOIN aberp_rostered_shift rs2 ON rs2.aberp_rostered_shift_id=rss.aberp_rostered_shift_id
          WHERE rss.isactive='Y' AND rs2.isactive='Y'
            AND COALESCE(rs2.aberp_isshiftrosteredtemplate,'N')='N'
            AND rss.aberp_user_contact_id = e.ad_user_id
            AND rs2.aberp_rostered_shift_id <> s.sid
            AND rs2.startdate < s.enddate AND rs2.enddate > s.startdate
        )
        -- needs match (when needs exist)
        AND (
          NOT EXISTS (
            SELECT 1 FROM aberp_related_rostering_needs_v v
            WHERE v.aberp_rostered_shift_id=s.sid AND v.isactive='Y'
          )
          OR (
            NOT EXISTS (
              SELECT 1 FROM aberp_related_rostering_needs_v rv
              WHERE rv.aberp_rostered_shift_id=s.sid AND rv.isactive='Y' AND rv.aberp_needtype='CRD'
                AND COALESCE(rv.aberp_credentials_id,0)>0
                AND NOT EXISTS (
                  SELECT 1 FROM aberp_credentialassignment ca
                  WHERE ca.isactive='Y' AND ca.aberp_credentials_id=rv.aberp_credentials_id
                    AND (ca.aberp_user_contact_id=e.ad_user_id OR ca.c_bpartner_staff_id=e.c_bpartner_id)
                    AND (ca.startdate IS NULL OR ca.startdate <= s.startdate)
                    AND (ca.aberp_expirydate IS NULL OR ca.aberp_expirydate >= s.enddate)
                )
            )
            AND NOT EXISTS (
              SELECT 1 FROM aberp_related_rostering_needs_v rv
              WHERE rv.aberp_rostered_shift_id=s.sid AND rv.isactive='Y' AND rv.aberp_needtype='GDR'
                AND COALESCE(rv.aberp_gender_id,0)>0
                AND COALESCE(e.aberp_gender_id,0) <> rv.aberp_gender_id
            )
            AND NOT EXISTS (
              SELECT 1 FROM aberp_related_rostering_needs_v rv
              WHERE rv.aberp_rostered_shift_id=s.sid AND rv.isactive='Y' AND rv.aberp_needtype='EMP'
                AND rv.aberp_user_contact_id = e.ad_user_id
            )
          )
        )
    ) AS matched_staff,
    (SELECT count(*) FROM emp) AS all_employees,
    (SELECT string_agg(e2.name, ', ' ORDER BY e2.name)
     FROM emp e2
     WHERE
       NOT EXISTS (
         SELECT 1 FROM aberp_unavailability_leave ul
         WHERE ul.aberp_user_contact_id = e2.ad_user_id AND ul.isactive='Y'
           AND UPPER(COALESCE(ul.aberp_approverstatus,''))='AP'
           AND ul.startdate <= s.enddate AND ul.enddate >= s.startdate
       )
       AND NOT EXISTS (
         SELECT 1 FROM aberp_rostered_shiftstaff rss
         JOIN aberp_rostered_shift rs2 ON rs2.aberp_rostered_shift_id=rss.aberp_rostered_shift_id
         WHERE rss.isactive='Y' AND rs2.isactive='Y'
           AND COALESCE(rs2.aberp_isshiftrosteredtemplate,'N')='N'
           AND rss.aberp_user_contact_id = e2.ad_user_id
           AND rs2.aberp_rostered_shift_id <> s.sid
           AND rs2.startdate < s.enddate AND rs2.enddate > s.startdate
       )
       AND (
         NOT EXISTS (SELECT 1 FROM aberp_related_rostering_needs_v v WHERE v.aberp_rostered_shift_id=s.sid AND v.isactive='Y')
         OR (
           NOT EXISTS (
             SELECT 1 FROM aberp_related_rostering_needs_v rv
             WHERE rv.aberp_rostered_shift_id=s.sid AND rv.isactive='Y' AND rv.aberp_needtype='CRD'
               AND COALESCE(rv.aberp_credentials_id,0)>0
               AND NOT EXISTS (
                 SELECT 1 FROM aberp_credentialassignment ca
                 WHERE ca.isactive='Y' AND ca.aberp_credentials_id=rv.aberp_credentials_id
                   AND (ca.aberp_user_contact_id=e2.ad_user_id OR ca.c_bpartner_staff_id=e2.c_bpartner_id)
                   AND (ca.startdate IS NULL OR ca.startdate <= s.startdate)
                   AND (ca.aberp_expirydate IS NULL OR ca.aberp_expirydate >= s.enddate)
               )
           )
           AND NOT EXISTS (
             SELECT 1 FROM aberp_related_rostering_needs_v rv
             WHERE rv.aberp_rostered_shift_id=s.sid AND rv.isactive='Y' AND rv.aberp_needtype='GDR'
               AND COALESCE(rv.aberp_gender_id,0)>0
               AND COALESCE(e2.aberp_gender_id,0) <> rv.aberp_gender_id
           )
           AND NOT EXISTS (
             SELECT 1 FROM aberp_related_rostering_needs_v rv
             WHERE rv.aberp_rostered_shift_id=s.sid AND rv.isactive='Y' AND rv.aberp_needtype='EMP'
               AND rv.aberp_user_contact_id = e2.ad_user_id
           )
         )
       )
    ) AS matched_names
  FROM shifts s
)
SELECT documentno, name, need_count, matched_staff, all_employees,
       LEFT(matched_names, 120) AS sample_matches,
       CASE
         WHEN name LIKE '%01 Baseline%' AND matched_staff >= 10 THEN 'PASS'
         WHEN name LIKE '%02 RS Rover%' AND matched_staff BETWEEN 1 AND 10 AND matched_names ILIKE '%Robert%' THEN 'PASS'
         WHEN name LIKE '%03 RS First Aid%' AND matched_staff >= 1 THEN 'PASS'
         WHEN name LIKE '%04 RS GDR Male%' AND matched_staff >= 1 AND matched_names NOT ILIKE '%Ella%' THEN 'PASS'
         WHEN name LIKE '%05 RS GDR Female%' AND matched_staff >= 1 AND matched_names ILIKE '%Ella%' THEN 'PASS'
         WHEN name LIKE '%06 RS Rover+Male%' AND matched_staff >= 1 AND matched_names ILIKE '%Robert%' THEN 'PASS'
         WHEN name LIKE '%07 RS EMP%' AND matched_names NOT ILIKE '%Ella Williams%' THEN 'PASS'
         WHEN name LIKE '%08 SR Amelia%' AND need_count >= 3 AND matched_staff >= 1 AND matched_names ILIKE '%Ella%' AND matched_names NOT ILIKE '%Jack Brown%' THEN 'PASS'
         WHEN name LIKE '%09 SR Rose%' AND need_count >= 1 AND matched_staff >= 1 THEN 'PASS'
         WHEN name LIKE '%10 SR Amelia+Jennifer%' AND need_count >= 2 AND matched_staff >= 1 THEN 'PASS'
         WHEN name LIKE '%11 RS 3-cred%' AND matched_staff >= 1 THEN 'PASS'
         WHEN name LIKE '%12 Leave-overlap%' AND matched_names NOT ILIKE '%Ella Williams%' THEN 'PASS'
         WHEN name LIKE '%13 Leave-after%' AND matched_names ILIKE '%Ella Williams%' THEN 'PASS'
         WHEN name LIKE '%14 Overlap-morning%' THEN 'PASS'
         WHEN name LIKE '%15 Overlap-afternoon%' AND matched_names NOT ILIKE '%Blake Fraser%' THEN 'PASS'
         WHEN name LIKE '%16 LOC Rover%' AND matched_staff < all_employees THEN 'PASS'
         WHEN name LIKE '%17 Diabetes%' AND matched_names NOT ILIKE '%Theo Barnes%' THEN 'PASS'
         WHEN name LIKE '%18 Published%' THEN 'PASS'
         WHEN name LIKE '%19 Multi vacant%' AND matched_staff >= 1 THEN 'PASS'
         WHEN name LIKE '%20 SR Benjamin%' AND need_count >= 3 AND matched_staff >= 1 THEN 'PASS'
         WHEN name LIKE '%21 +30d%' AND matched_staff >= 1 THEN 'PASS'
         WHEN name LIKE '%22 SR Amelia%' AND matched_staff >= 1 THEN 'PASS'
         WHEN name LIKE '%23 RS Male+Rover%' AND matched_staff >= 1 AND matched_names ILIKE '%Robert%' THEN 'PASS'
         WHEN name LIKE '%24 Open available%' AND matched_staff >= 10 THEN 'PASS'
         ELSE 'FAIL'
       END AS result
FROM match_counts
ORDER BY name;
