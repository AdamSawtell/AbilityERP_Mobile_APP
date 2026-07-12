-- SAW014 discover: Email/Phone + all ColumnSQL on AbERP_Support_Location
SELECT c.ad_column_id, c.columnname, c.name, c.ad_column_uu,
       c.ad_reference_id, c.fieldlength, c.isactive, c.isupdateable,
       c.columnsql, c.entitytype, c.ad_element_id
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'AbERP_Support_Location'
  AND (
    c.columnname ILIKE '%email%'
    OR c.columnname ILIKE '%phone%'
    OR COALESCE(c.columnsql,'') ILIKE '%email%'
    OR COALESCE(c.columnsql,'') ILIKE '%phone%'
    OR c.name ILIKE '%email%'
    OR c.name ILIKE '%phone%'
  )
ORDER BY c.columnname;

\echo '--- ALL columns with ColumnSQL ---'
SELECT c.ad_column_id, c.columnname, c.name, c.ad_column_uu,
       c.columnsql,
       c.isupdateable, c.entitytype
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'AbERP_Support_Location'
  AND c.columnsql IS NOT NULL AND trim(c.columnsql) <> ''
ORDER BY c.columnname;

\echo '--- physical table columns Email/Phone ---'
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'adempiere'
  AND table_name = 'aberp_support_location'
  AND (column_name ILIKE '%email%' OR column_name ILIKE '%phone%' OR column_name ILIKE '%user%' OR column_name ILIKE '%partner%' OR column_name ILIKE '%contact%')
ORDER BY ordinal_position;

\echo '--- fields on main Support Location tab ---'
SELECT f.ad_field_id, f.name, f.ad_field_uu, f.isdisplayed, f.isdisplayedgrid,
       f.seqno, f.seqnogrid, c.columnname, left(COALESCE(c.columnsql,''),120) AS columnsql
FROM ad_field f
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE t.ad_tab_uu = '32dd99e4-ed10-43f2-a287-0ef43f0c3544'
  AND (c.columnname ILIKE '%email%' OR c.columnname ILIKE '%phone%' OR f.name ILIKE '%email%' OR f.name ILIKE '%phone%')
ORDER BY f.seqnogrid NULLS LAST, f.seqno;
