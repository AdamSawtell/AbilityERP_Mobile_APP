SET search_path TO adempiere;
EXPLAIN ANALYZE
SELECT
  (SELECT r.R_Status_ID FROM R_Request r WHERE r.R_Request_ID=(
     SELECT MAX(r2.R_Request_ID) FROM R_Request r2
     WHERE r2.AD_Table_ID=1000195
       AND r2.Record_ID=sc.AbERP_ShiftChange_ID
       AND r2.IsActive='Y')) AS status_id,
  (SELECT CASE WHEN EXISTS (
     SELECT 1 FROM R_Request r
     WHERE r.AD_Table_ID=1000195
       AND r.Record_ID=sc.AbERP_ShiftChange_ID
       AND r.IsActive='Y') THEN 'Y' ELSE 'N' END) AS submitted
FROM aberp_shiftchange sc
WHERE sc.documentno='1003753';
