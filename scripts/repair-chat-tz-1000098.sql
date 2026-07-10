SET search_path TO adempiere;

-- Fix the one worker row written under UTC session (sorts before officer "hi Adam")
UPDATE r_requestupdate
SET created = TIMESTAMP '2026-07-11 08:34:41.702093',
    updated = TIMESTAMP '2026-07-11 08:34:41.702093'
WHERE r_requestupdate_id = 1000106
  AND r_request_id = 1000098;

UPDATE r_request
SET lastresult = 'Worker timeline fix 1783724681690',
    ad_role_id = 1000012,
    datelastaction = TIMESTAMP '2026-07-11 08:34:41.702093'
WHERE r_request_id = 1000098;

SELECT r_requestupdate_id, LEFT(result,40) AS body, created
FROM r_requestupdate
WHERE r_request_id = 1000098 AND isactive = 'Y'
ORDER BY created ASC, r_requestupdate_id ASC;

SELECT r_request_id, LEFT(lastresult,60) AS last_message, ad_role_id, datelastaction
FROM r_request WHERE r_request_id = 1000098;
