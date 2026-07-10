SET search_path TO adempiere;
SELECT r.r_request_id, r.lastresult, r.aberp_rosteringreply, r.ad_user_id, r.ad_role_id, r.datelastaction
FROM r_request r
WHERE r.r_request_id = 1000088;

SELECT ru.r_requestupdate_id, ru.result, ru.created
FROM r_requestupdate ru
WHERE ru.r_request_id = 1000088
ORDER BY ru.created DESC
LIMIT 3;
