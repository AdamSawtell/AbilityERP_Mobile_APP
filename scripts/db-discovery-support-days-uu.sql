SET search_path TO adempiere;
SELECT e.ad_element_uu, e.columnname FROM ad_element e
WHERE e.columnname IN ('AbERP_Support_Start_Day','AbERP_Support_End_Day');
SELECT t.ad_table_id, t.ad_table_uu FROM ad_table t WHERE t.tablename='C_OrderLine';
SELECT MAX(f.seqno) AS max_seq FROM ad_field f
JOIN ad_tab tab ON tab.ad_tab_id=f.ad_tab_id
WHERE tab.ad_tab_uu='8b044105-bc30-4f81-b0d6-a45835d82f98' AND f.isdisplayed='Y';
SELECT c.ad_column_uu, c.columnname FROM ad_column c
JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE t.tablename='C_OrderLine' AND c.columnname='AbERP_ServicePattern_ID';
