SELECT documentno, summary, r_requesttype_id,
       (SELECT name FROM r_requesttype WHERE r_requesttype_id = sc.r_requesttype_id) AS rtype,
       aberp_requestsubmitted, r_status_id, updated
FROM aberp_shiftchange sc
WHERE documentno IN ('1003753','1003729');

-- why might Summary be RO: check field isupdateable column if exists
SELECT column_name FROM information_schema.columns
WHERE table_name='ad_field' AND column_name ILIKE '%update%';
