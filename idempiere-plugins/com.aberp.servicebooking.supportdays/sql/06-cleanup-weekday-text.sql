-- SAW031: null leftover weekday text in Support Start/End Day (invalid after SAW009 List).
-- Then re-backfill from AbERP_ServicePattern where linked.
SET search_path TO adempiere;

UPDATE c_orderline
SET aberp_support_start_day = NULL,
    updated = NOW(),
    updatedby = 100
WHERE aberp_support_start_day IS NOT NULL
  AND aberp_support_start_day !~ '^[0-9]+$';

UPDATE c_orderline
SET aberp_support_end_day = NULL,
    updated = NOW(),
    updatedby = 100
WHERE aberp_support_end_day IS NOT NULL
  AND aberp_support_end_day !~ '^[0-9]+$';

UPDATE c_orderline ol
SET
  aberp_support_start_day = sp.aberp_rosterstartday,
  aberp_support_end_day = sp.aberp_rosterendday,
  updated = NOW(),
  updatedby = 100
FROM aberp_servicepattern sp
WHERE sp.aberp_servicepattern_id = ol.aberp_servicepattern_id
  AND ol.aberp_servicepattern_id IS NOT NULL
  AND (
    ol.aberp_support_start_day IS NULL
    OR ol.aberp_support_end_day IS NULL
    OR ol.aberp_support_start_day IS DISTINCT FROM sp.aberp_rosterstartday
    OR ol.aberp_support_end_day IS DISTINCT FROM sp.aberp_rosterendday
  );
