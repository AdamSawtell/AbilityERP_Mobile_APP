-- Other WITHOUT-request docs for alternate type smoke
SELECT sc.documentno, rt.name AS request_type, sc.aberp_requestsubmitted
FROM aberp_shiftchange sc
LEFT JOIN r_requesttype rt ON rt.r_requesttype_id = sc.r_requesttype_id
WHERE sc.isactive='Y' AND COALESCE(sc.aberp_requestsubmitted,'N')='N'
  AND sc.r_requesttype_id IS NOT NULL
ORDER BY sc.updated DESC
LIMIT 15;
