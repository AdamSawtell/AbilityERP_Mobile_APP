SET search_path TO adempiere;

-- Officer reply on Ella's current open Rostering Chat thread
INSERT INTO r_requestupdate (
  r_requestupdate_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  r_request_id, result, confidentialtypeentry
)
SELECT
  (SELECT COALESCE(MAX(r_requestupdate_id), 0) + 1 FROM r_requestupdate),
  r.ad_client_id, 0, 'Y',
  NOW(), 100, NOW(), 100,
  r.r_request_id,
  'Officer reply test — please confirm you can see this in the app.',
  'C'
FROM r_request r
JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
WHERE rt.name = 'Rostering Chat'
  AND r.isactive = 'Y'
  AND r.r_status_id <> 102
  AND r.ad_user_id = (SELECT ad_user_id FROM ad_user WHERE name = 'Ella Williams' LIMIT 1)
ORDER BY r.datelastaction DESC NULLS LAST
LIMIT 1;

UPDATE r_request r
SET lastresult = 'Officer reply test — please confirm you can see this in the app.',
    ad_role_id = 0,
    aberp_rosteringreply = NULL,
    datelastaction = NOW(),
    updated = NOW(),
    updatedby = 100
FROM r_requesttype rt
WHERE rt.r_requesttype_id = r.r_requesttype_id
  AND rt.name = 'Rostering Chat'
  AND r.isactive = 'Y'
  AND r.r_status_id <> 102
  AND r.ad_user_id = (SELECT ad_user_id FROM ad_user WHERE name = 'Ella Williams' LIMIT 1);

SELECT r.r_request_id, LEFT(r.lastresult, 60) AS lastresult,
       CASE WHEN COALESCE(r.ad_role_id,0)=1000012 THEN 'Awaiting Rostering' ELSE 'Awaiting Worker' END AS awaiting
FROM r_request r
JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
WHERE rt.name = 'Rostering Chat' AND r.ad_user_id = (SELECT ad_user_id FROM ad_user WHERE name = 'Ella Williams' LIMIT 1)
  AND r.r_status_id <> 102;

SELECT ru.r_request_id, ru.r_requestupdate_id, LEFT(ru.result, 70) AS result, u.name AS author
FROM r_requestupdate ru
LEFT JOIN ad_user u ON u.ad_user_id = ru.createdby
WHERE ru.r_request_id IN (
  SELECT r.r_request_id FROM r_request r
  JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
  WHERE rt.name = 'Rostering Chat' AND r.r_status_id <> 102
    AND r.ad_user_id = (SELECT ad_user_id FROM ad_user WHERE name = 'Ella Williams' LIMIT 1)
)
ORDER BY ru.created DESC
LIMIT 6;
