-- SAW014: sample data + verify subquery
\echo '--- sample ---'
SELECT sl.aberp_support_location_id, sl.name,
       sl.c_bpartner_location_id,
       bpl.email, bpl.phone, bpl.phone2, bpl.name AS bpl_name
FROM aberp_support_location sl
LEFT JOIN c_bpartner_location bpl ON bpl.c_bpartner_location_id = sl.c_bpartner_location_id
WHERE sl.isactive = 'Y'
ORDER BY sl.aberp_support_location_id
LIMIT 15;

\echo '--- proposed ColumnSQL works ---'
SELECT sl.aberp_support_location_id, sl.name,
  (SELECT Email FROM C_BPartner_Location WHERE C_BPartner_Location_ID = AbERP_Support_Location.C_BPartner_Location_ID) AS email,
  (SELECT Phone FROM C_BPartner_Location WHERE C_BPartner_Location_ID = AbERP_Support_Location.C_BPartner_Location_ID) AS phone,
  (SELECT Phone2 FROM C_BPartner_Location WHERE C_BPartner_Location_ID = AbERP_Support_Location.C_BPartner_Location_ID) AS phone2
FROM aberp_support_location AS AbERP_Support_Location
JOIN LATERAL (SELECT AbERP_Support_Location.aberp_support_location_id AS id) x ON true
WHERE AbERP_Support_Location.isactive = 'Y'
ORDER BY AbERP_Support_Location.aberp_support_location_id
LIMIT 10;

\echo '--- simpler alias ---'
SELECT sl.aberp_support_location_id, sl.name,
  (SELECT Email FROM C_BPartner_Location WHERE C_BPartner_Location_ID = sl.C_BPartner_Location_ID) AS email,
  (SELECT Phone FROM C_BPartner_Location WHERE C_BPartner_Location_ID = sl.C_BPartner_Location_ID) AS phone,
  (SELECT Phone2 FROM C_BPartner_Location WHERE C_BPartner_Location_ID = sl.C_BPartner_Location_ID) AS phone2
FROM aberp_support_location sl
WHERE sl.isactive = 'Y'
ORDER BY sl.aberp_support_location_id
LIMIT 15;

\echo '--- counts ---'
SELECT
  count(*) AS total,
  count(sl.c_bpartner_location_id) AS with_bpl,
  count(*) FILTER (WHERE coalesce(bpl.email,'') <> '') AS with_email,
  count(*) FILTER (WHERE coalesce(bpl.phone,'') <> '') AS with_phone,
  count(*) FILTER (WHERE coalesce(bpl.phone2,'') <> '') AS with_phone2,
  count(*) FILTER (WHERE sl.c_bpartner_location_id IS NULL) AS missing_bpl
FROM aberp_support_location sl
LEFT JOIN c_bpartner_location bpl ON bpl.c_bpartner_location_id = sl.c_bpartner_location_id
WHERE sl.isactive = 'Y';

\echo '--- grid-displayed @SQL= columns on tab ---'
SELECT c.columnname, f.isdisplayedgrid, left(c.columnsql,100) AS sql
FROM ad_field f
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE t.ad_tab_uu = '32dd99e4-ed10-43f2-a287-0ef43f0c3544'
  AND c.columnsql LIKE '@SQL=%'
ORDER BY f.seqnogrid;
