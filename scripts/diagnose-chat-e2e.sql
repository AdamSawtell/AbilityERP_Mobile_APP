SET search_path TO adempiere;

-- Latest Ella threads + updates
SELECT r.r_request_id, rs.name AS status, r.ad_role_id,
       LEFT(r.lastresult, 50) AS lastresult, r.datelastaction, r.updated
FROM r_request r
JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
LEFT JOIN r_status rs ON rs.r_status_id = r.r_status_id
WHERE rt.name = 'Rostering Chat'
  AND r.ad_user_id = (SELECT ad_user_id FROM ad_user WHERE name = 'Ella Williams' LIMIT 1)
ORDER BY r.updated DESC
LIMIT 5;

SELECT ru.r_request_id, ru.r_requestupdate_id, LEFT(ru.result, 60) AS result,
       u.name AS author, ru.created
FROM r_requestupdate ru
LEFT JOIN ad_user u ON u.ad_user_id = ru.createdby
WHERE ru.r_request_id IN (
  SELECT r.r_request_id FROM r_request r
  JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
  WHERE rt.name = 'Rostering Chat'
    AND r.ad_user_id = (SELECT ad_user_id FROM ad_user WHERE name = 'Ella Williams' LIMIT 1)
  ORDER BY r.updated DESC LIMIT 3
)
ORDER BY ru.created DESC
LIMIT 20;

-- Process failures
SELECT pi.ad_pinstance_id, p.value, pi.created, pi.result, LEFT(pi.errormsg, 200) AS err
FROM ad_pinstance pi
JOIN ad_process p ON p.ad_process_id = pi.ad_process_id
WHERE p.value IN ('ROSTERING_CHAT_REPLY', 'ROSTERING_CHAT_CLOSE')
ORDER BY pi.created DESC
LIMIT 8;

-- Updates tab link
SELECT t.name, t.ad_column_id, t.parent_column_id, t.whereclause, t.isreadonly,
       c.columnname AS child_col, pc.columnname AS parent_col
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
LEFT JOIN ad_column c ON c.ad_column_id = t.ad_column_id
LEFT JOIN ad_column pc ON pc.ad_column_id = t.parent_column_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Updates';

-- Reply field flags
SELECT f.name, f.isreadonly, f.isupdateable, f.isdisplayed, c.isupdateable, c.isalwaysupdateable
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname IN ('AbERP_RosteringReply', 'AbERP_SendRosteringReply', 'LastResult');
