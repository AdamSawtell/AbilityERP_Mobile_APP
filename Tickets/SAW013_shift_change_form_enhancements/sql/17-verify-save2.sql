SELECT documentno, length(documentno), aberp_requestsubmitted, r_status_id, updated
FROM aberp_shiftchange
WHERE documentno LIKE '1003753%' OR documentno LIKE '%E2E%';
SELECT now();
