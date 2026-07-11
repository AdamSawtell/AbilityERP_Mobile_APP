-- Verify Paid filter on Notification SR Invoice Send Info (1000032)

SET search_path TO adempiere;

\echo '=== INFO WINDOW ==='
SELECT ad_infowindow_id, ad_infowindow_uu, name, fromclause, isvalid
FROM ad_infowindow
WHERE ad_infowindow_uu = '8fb1cd46-ed81-4cb9-8b83-7662caed9e62';

\echo '=== PAID INFO COLUMNS ==='
SELECT seqnoselection, seqno, ad_infocolumn_uu, columnname, name, selectclause,
       isquerycriteria, isdisplayed, ismandatory, ad_reference_id, ad_reference_value_id,
       defaultvalue, queryoperator, isactive
FROM ad_infocolumn
WHERE ad_infowindow_id = (
  SELECT ad_infowindow_id FROM ad_infowindow
  WHERE ad_infowindow_uu = '8fb1cd46-ed81-4cb9-8b83-7662caed9e62'
)
  AND columnname = 'IsPaid'
ORDER BY seqno;

\echo '=== CRITERIA ORDER ==='
SELECT seqnoselection, columnname, name, isquerycriteria, ad_reference_id, defaultvalue
FROM ad_infocolumn
WHERE ad_infowindow_id = (
  SELECT ad_infowindow_id FROM ad_infowindow
  WHERE ad_infowindow_uu = '8fb1cd46-ed81-4cb9-8b83-7662caed9e62'
)
  AND isquerycriteria = 'Y'
  AND isactive = 'Y'
ORDER BY seqnoselection;

\echo '=== SAMPLE FILTER SQL (IsPaid values) ==='
SELECT ispaid, COUNT(*) AS invoices
FROM c_invoice
WHERE isactive = 'Y' AND docstatus = 'CO'
GROUP BY ispaid
ORDER BY ispaid;
