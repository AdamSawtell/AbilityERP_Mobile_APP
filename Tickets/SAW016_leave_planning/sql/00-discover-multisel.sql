SELECT iw.name, ic.columnname, ic.name, ic.ismultiselectcriteria, ic.ad_reference_id, ic.queryoperator, left(ic.selectclause,60)
FROM ad_infocolumn ic
JOIN ad_infowindow iw ON iw.ad_infowindow_id=ic.ad_infowindow_id
WHERE ic.ismultiselectcriteria='Y'
ORDER BY iw.name, ic.seqno
LIMIT 30;

-- How InfoWindowAccess works
SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name LIKE 'ad_infowindow%'
ORDER BY table_name, ordinal_position;
