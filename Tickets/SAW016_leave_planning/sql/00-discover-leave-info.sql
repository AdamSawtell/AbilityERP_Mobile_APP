\echo === BP Employee Leave Info ===
SELECT iw.*, t.tablename FROM ad_infowindow iw
JOIN ad_table t ON t.ad_table_id=iw.ad_table_id
WHERE iw.ad_infowindow_uu='ab948aa9-728b-4cac-9aaf-aabf6de95c1b';

SELECT ic.seqno, ic.columnname, ic.name, ic.isquerycriteria, ic.isdisplayed, ic.ad_reference_id,
       ic.ad_reference_value_id, left(coalesce(ic.selectclause,''),100) AS sel,
       left(coalesce(ic.queryoperator,''),20) AS op
FROM ad_infocolumn ic
WHERE ad_infowindow_id=1000044
ORDER BY seqno;

\echo === View definition ===
SELECT pg_get_viewdef('adempiere.aberp_leaveandavailability_v'::regclass, true);

\echo === FromClause of leave info ===
SELECT fromclause FROM ad_infowindow WHERE ad_infowindow_id=1000044;

\echo === Menu for BP Employee Leave ===
SELECT m.name, m.action, m.ad_infowindow_id, m.ad_menu_uu FROM ad_menu m
WHERE m.ad_infowindow_id=1000044 OR m.name ILIKE '%employee leave%';
