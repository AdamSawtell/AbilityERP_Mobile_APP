-- AbERP Staff Rostering Info — verify rewrite + query cost
SET search_path TO adempiere;
SET statement_timeout = '15s';

SELECT ad_infowindow_id, name, isdistinct, maxqueryrecords, isloadpagenum, pagingsize, pagesize,
       isshowindashboard, length(fromclause) AS from_len, length(whereclause) AS where_len,
       orderbyclause, isvalid
FROM ad_infowindow
WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf';

SELECT fromclause FROM ad_infowindow
WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf';

SELECT seqnoselection, seqno, columnname, name, selectclause, isquerycriteria, isdisplayed, iskey, isactive
FROM ad_infocolumn
WHERE ad_infowindow_id = (
  SELECT ad_infowindow_id FROM ad_infowindow
  WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
)
ORDER BY isactive DESC, COALESCE(seqnoselection, 9999), seqno;

-- Lean query shape (mirrors new FROM; no context dates => no leave/overlap filter)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT au.AD_User_ID, au.Name, bp.Value, bp.Name AS bp_name, bp.IsEmployee, au.AbERP_isagencystaff
FROM AD_User au
INNER JOIN C_BPartner bp ON (bp.C_BPartner_ID = au.C_BPartner_ID AND bp.IsActive = 'Y')
LEFT JOIN C_Job jb ON (jb.C_Job_ID = bp.C_Job_ID AND jb.IsActive = 'Y')
WHERE au.IsActive = 'Y'
  AND bp.IsEmployee = 'Y'
ORDER BY au.Name
LIMIT 50;
