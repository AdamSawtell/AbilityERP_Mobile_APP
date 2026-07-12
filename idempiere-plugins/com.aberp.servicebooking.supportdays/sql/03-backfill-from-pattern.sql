-- SAW009: backfill Support Start/End Day from linked AbERP_ServicePattern only.
-- Does NOT invent a day number from weekday name alone.
SET search_path TO adempiere;

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
    ol.aberp_support_start_day IS DISTINCT FROM sp.aberp_rosterstartday
    OR ol.aberp_support_end_day IS DISTINCT FROM sp.aberp_rosterendday
  );
