-- SAW014: verify contact ColumnSQL no longer uses @SQL=
SELECT c.columnname, c.ad_column_uu, c.columnsql,
       CASE WHEN c.columnsql LIKE '@SQL=%' THEN 'FAIL still @SQL=' ELSE 'OK subquery' END AS status
FROM ad_column c
WHERE c.ad_column_uu IN (
  'bd54d23d-44b6-42d7-b8c8-30b3e7b826e6',
  '5f9a40e5-248b-48bd-848f-532ae4601006',
  'f41c821a-90fb-4b8b-95c6-8bf2f181f8e7',
  '21b6490e-5aea-4035-b64c-c45c7cc05161',
  'a77b2962-807c-464b-a8f5-1871ffd9fd1c'
)
ORDER BY c.columnname;

-- Spot-check: subquery returns contact for rows that have it
SELECT sl.aberp_support_location_id, sl.name,
  (SELECT Email FROM C_BPartner_Location WHERE C_BPartner_Location_ID=sl.C_BPartner_Location_ID) AS email,
  (SELECT Phone FROM C_BPartner_Location WHERE C_BPartner_Location_ID=sl.C_BPartner_Location_ID) AS phone,
  (SELECT Phone2 FROM C_BPartner_Location WHERE C_BPartner_Location_ID=sl.C_BPartner_Location_ID) AS phone2
FROM aberp_support_location sl
WHERE sl.isactive = 'Y'
  AND sl.c_bpartner_location_id IS NOT NULL
ORDER BY sl.aberp_support_location_id
LIMIT 20;
