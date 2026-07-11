-- Functional check: Paid filter semantics against C_Invoice.IsPaid
SET search_path TO adempiere;

\echo '=== Paid = Yes (IsPaid=Y) ==='
SELECT i.c_invoice_id, i.documentno, i.ispaid, i.docstatus
FROM c_invoice i
WHERE i.isactive = 'Y' AND i.docstatus = 'CO' AND i.ispaid = 'Y'
ORDER BY i.documentno;

\echo '=== Paid = No (IsPaid=N) ==='
SELECT i.c_invoice_id, i.documentno, i.ispaid, i.docstatus
FROM c_invoice i
WHERE i.isactive = 'Y' AND i.docstatus = 'CO' AND i.ispaid = 'N'
ORDER BY i.documentno;

\echo '=== No Paid filter (both) ==='
SELECT i.ispaid, COUNT(*)
FROM c_invoice i
WHERE i.isactive = 'Y' AND i.docstatus = 'CO'
GROUP BY i.ispaid
ORDER BY i.ispaid;

\echo '=== AD columns present ==='
SELECT COUNT(*) AS paid_infocolumns
FROM ad_infocolumn
WHERE ad_infocolumn_uu IN (
  'a8f3c2e1-9b47-4d6a-8e15-2c7f9a1b4d03',
  'b7e4d3f2-0c58-4e7b-9f26-3d8a0b2c5e14'
)
  AND isactive = 'Y'
  AND selectclause = 'i.IsPaid';
