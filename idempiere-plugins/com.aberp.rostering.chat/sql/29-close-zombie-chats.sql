SET search_path TO adempiere, public;

-- Close zombie Rostering Chat threads that have a close note but are still Open
UPDATE r_request r
SET r_status_id = COALESCE(
      (
        SELECT rs.r_status_id
        FROM r_status rs
        JOIN r_requesttype rt ON rt.r_statuscategory_id = rs.r_statuscategory_id
        WHERE rt.r_requesttype_id = r.r_requesttype_id
          AND rs.isactive = 'Y' AND rs.isclosed = 'Y'
        ORDER BY rs.seqno NULLS LAST, rs.r_status_id
        LIMIT 1
      ),
      1000002
    ),
    ad_role_id = 0,
    aberp_chatawaitingreply = 'Closed',
    lastresult = COALESCE(NULLIF(btrim(r.lastresult), ''), 'Chat closed by rostering'),
    datelastaction = COALESCE(r.datelastaction, NOW()),
    updated = NOW(),
    updatedby = 100
FROM r_requesttype rt, r_status rs
WHERE r.r_requesttype_id = rt.r_requesttype_id
  AND rt.name = 'Rostering Chat'
  AND rs.r_status_id = r.r_status_id
  AND COALESCE(rs.isclosed, 'N') <> 'Y'
  AND (
    btrim(COALESCE(r.lastresult, '')) = 'Chat closed by rostering'
    OR EXISTS (
      SELECT 1 FROM r_requestupdate u
      WHERE u.r_request_id = r.r_request_id
        AND u.isactive = 'Y'
        AND btrim(u.result) = 'Chat closed by rostering'
        AND COALESCE(u.confidentialtypeentry, 'A') = 'A'
    )
  );

SELECT r.r_request_id, r.aberp_chatawaitingreply, rs.isclosed, LEFT(r.lastresult,40)
FROM r_request r
JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
LEFT JOIN r_status rs ON rs.r_status_id = r.r_status_id
WHERE rt.name = 'Rostering Chat' AND r.ad_user_id = 1000107
  AND btrim(COALESCE(r.lastresult,'')) = 'Chat closed by rostering'
ORDER BY r.r_request_id DESC
LIMIT 10;
