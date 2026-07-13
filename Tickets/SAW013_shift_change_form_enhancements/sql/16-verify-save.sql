SELECT documentno, aberp_requestsubmitted, r_status_id,
       (SELECT name FROM r_status WHERE r_status_id = sc.r_status_id) AS status_name,
       updated, updatedby
FROM aberp_shiftchange sc
WHERE documentno IN ('1003753','1003753E2E');
