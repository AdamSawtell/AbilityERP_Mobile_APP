-- Pick a WITHOUT-request doc for full Create E2E (prefer Additional Shift)
SELECT sc.aberp_shiftchange_id, sc.documentno, sc.r_requesttype_id, rt.name AS request_type,
       sc.aberp_requestsubmitted, sc.summary
FROM aberp_shiftchange sc
JOIN r_requesttype rt ON rt.r_requesttype_id = sc.r_requesttype_id
WHERE sc.isactive='Y' AND COALESCE(sc.aberp_requestsubmitted,'N')='N'
  AND rt.name = 'Additional Shift'
ORDER BY sc.updated DESC
LIMIT 5;
