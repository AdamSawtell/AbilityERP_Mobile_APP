SELECT 'WITH' AS kind, sc.aberp_shiftchange_id, sc.documentno,
       sc.aberp_requestsubmitted, s.name AS status_name
FROM aberp_shiftchange sc
LEFT JOIN r_status s ON s.r_status_id = sc.r_status_id
WHERE sc.aberp_requestsubmitted = 'Y' AND sc.isactive = 'Y'
ORDER BY sc.aberp_shiftchange_id DESC
LIMIT 1;

SELECT 'WITHOUT' AS kind, sc.aberp_shiftchange_id, sc.documentno,
       COALESCE(sc.aberp_requestsubmitted, 'N') AS submitted, LEFT(sc.summary, 40) AS summary
FROM aberp_shiftchange sc
WHERE sc.isactive = 'Y'
  AND COALESCE(sc.aberp_requestsubmitted, 'N') = 'N'
  AND NOT EXISTS (
    SELECT 1 FROM r_request r
    WHERE r.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_ShiftChange')
      AND r.record_id = sc.aberp_shiftchange_id
      AND r.isactive = 'Y'
  )
ORDER BY sc.aberp_shiftchange_id DESC
LIMIT 1;
