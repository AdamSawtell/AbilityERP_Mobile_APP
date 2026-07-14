-- How Timesheet Approval / similar Info Windows are defined
SELECT iw.name, iw.ad_infowindow_uu, iw.ad_table_id, t.tablename, iw.fromclause IS NOT NULL AS has_from,
       iw.otherclause, iw.isvalid, iw.ad_infowindow_id
FROM ad_infowindow iw
LEFT JOIN ad_table t ON t.ad_table_id=iw.ad_table_id
WHERE iw.name ILIKE '%timesheet%approv%' OR iw.name ILIKE '%rostering%info%' OR iw.name ILIKE '%leave%'
ORDER BY iw.name;

SELECT ic.seqno, ic.columnname, ic.name, ic.isquerycriteria, ic.isdisplayed, ic.ad_reference_id, ic.queryfunction, left(ic.selectclause,80) AS sel
FROM ad_infocolumn ic
JOIN ad_infowindow iw ON iw.ad_infowindow_id=ic.ad_infowindow_id
WHERE iw.ad_infowindow_uu='40d6a2d7-3bbc-431e-940c-ce75829a68e4'
ORDER BY ic.seqno
LIMIT 40;

-- Chosen multiple on info columns
SELECT iw.name, ic.columnname, ic.ad_reference_id, ic.ad_reference_value_id, ic.fieldlength, ic.isquerycriteria
FROM ad_infocolumn ic
JOIN ad_infowindow iw ON iw.ad_infowindow_id=ic.ad_infowindow_id
WHERE ic.ad_reference_id IN (200161,200162,200163)
ORDER BY iw.name
LIMIT 20;
