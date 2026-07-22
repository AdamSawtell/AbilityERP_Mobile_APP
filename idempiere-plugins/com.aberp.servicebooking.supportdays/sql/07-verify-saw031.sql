-- SAW031 verify: no weekday text remains; model factory JAR is a separate OSGi check.
SET search_path TO adempiere;

SELECT COUNT(*) AS leftover_weekday_start
FROM c_orderline
WHERE aberp_support_start_day IS NOT NULL
  AND aberp_support_start_day !~ '^[0-9]+$';

SELECT COUNT(*) AS leftover_weekday_end
FROM c_orderline
WHERE aberp_support_end_day IS NOT NULL
  AND aberp_support_end_day !~ '^[0-9]+$';

SELECT o.documentno, ol.c_orderline_id, ol.line,
       ol.aberp_support_start_day, ol.aberp_support_end_day,
       ol.aberp_isvalidated, ol.aberp_ready_claim
FROM c_order o
JOIN c_orderline ol ON ol.c_order_id = o.c_order_id
WHERE o.documentno IN ('53179', '53175')
  AND COALESCE(ol.aberp_isvalidated, 'N') = 'N'
ORDER BY o.documentno, ol.line
LIMIT 15;
