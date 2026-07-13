-- Table access?
SELECT COUNT(*) FROM ad_table_access WHERE ad_table_id=(SELECT ad_table_id FROM ad_table WHERE tablename='AbERP_Leave_Planning');

-- Compare physical vs AD columns
SELECT c.columnname, c.ad_reference_id, c.columnsql IS NOT NULL AS virt,
  EXISTS (
    SELECT 1 FROM information_schema.columns ic
    WHERE ic.table_schema='adempiere' AND ic.table_name='aberp_leave_planning'
      AND lower(ic.column_name)=lower(c.columnname)
  ) AS physical
FROM ad_column c
JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE t.tablename='AbERP_Leave_Planning'
ORDER BY c.seqno, c.columnname;

-- Field counts
SELECT tab.name, COUNT(f.*) 
FROM ad_field f JOIN ad_tab tab ON tab.ad_tab_id=f.ad_tab_id
JOIN ad_window w ON w.ad_window_id=tab.ad_window_id
WHERE w.name='Leave Planning'
GROUP BY tab.name;

-- Try open via recent - check window isactive
SELECT isactive, windowtype, issotrx FROM ad_window WHERE name='Leave Planning';
