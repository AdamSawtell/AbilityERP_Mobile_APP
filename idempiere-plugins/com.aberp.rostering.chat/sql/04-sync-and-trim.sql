SET search_path TO adempiere;

-- Re-type legacy mobile chat threads so they appear in Rostering Chat window
UPDATE r_request r
SET r_requesttype_id = rt.r_requesttype_id,
    updated = NOW(),
    updatedby = 100
FROM r_requesttype rt, r_requesttype old
WHERE rt.name = 'Rostering Chat' AND rt.isactive = 'Y'
  AND old.r_requesttype_id = r.r_requesttype_id
  AND r.isactive = 'Y'
  AND r.aberp_rostered_shift_id IS NULL
  AND r.r_requesttype_id <> rt.r_requesttype_id
  AND (
    r.summary = 'Message to Rostering'
    OR old.name IN ('Action', 'Request')
    OR (r.isselfservice = 'Y' AND r.ad_role_id = 1000012)
  );

-- Trim iDempiere header to essential fields
UPDATE ad_field f
SET isdisplayed = 'N',
    isdisplayedgrid = 'N',
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND t.tablevel = 0
  AND c.columnname IN (
    'Summary', 'C_BPartner_ID', 'Created', 'Updated',
    'SalesRep_ID', 'DateLastAction', 'LastResult', 'DocumentNo'
  );

UPDATE ad_field f
SET isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    isreadonly = 'Y',
    seqno = CASE c.columnname
      WHEN 'AD_User_ID' THEN 10
      WHEN 'R_Status_ID' THEN 20
      ELSE f.seqno
    END,
    name = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Worker'
      ELSE f.name
    END,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND c.columnname IN ('AD_User_ID', 'R_Status_ID');

SELECT rt.name AS request_type, count(*) AS threads
FROM r_request r
JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
WHERE r.isactive = 'Y' AND r.aberp_rostered_shift_id IS NULL
GROUP BY rt.name
ORDER BY count DESC;
