SELECT documentno, left(summary,80) AS summary, aberp_requestsubmitted,
       r_status_id,
       (SELECT name FROM r_status WHERE r_status_id = sc.r_status_id) AS status_name,
       isactive
FROM aberp_shiftchange sc
WHERE documentno IN ('1003729','1003753');
