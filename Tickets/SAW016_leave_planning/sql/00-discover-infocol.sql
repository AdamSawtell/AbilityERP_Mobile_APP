-- ad_infocolumn columns available
SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='ad_infocolumn'
ORDER BY ordinal_position;

-- sample Chosen Multiple info column if any
SELECT iw.name, ic.columnname, ic.ad_reference_id, ic.queryoperator, ic.selectclause
FROM ad_infocolumn ic JOIN ad_infowindow iw ON iw.ad_infowindow_id=ic.ad_infowindow_id
WHERE ic.ad_reference_id IN (200161,200162,200163) LIMIT 15;
