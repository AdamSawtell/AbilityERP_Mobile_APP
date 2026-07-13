SELECT documentno, isactive, aberp_requestsubmitted, r_status_id,
       (SELECT name FROM r_status WHERE r_status_id = sc.r_status_id) AS status_name,
       updated, now() AS db_now
FROM aberp_shiftchange sc
WHERE documentno = '1003753';
