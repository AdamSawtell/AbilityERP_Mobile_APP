SET search_path TO adempiere;

-- Pick an active order line and attach a service pattern; trigger should copy days
UPDATE c_orderline
SET aberp_servicepattern_id = 1000000,
    updated = NOW(),
    updatedby = 100
WHERE c_orderline_id = (
  SELECT c_orderline_id FROM c_orderline WHERE isactive = 'Y' ORDER BY c_orderline_id DESC LIMIT 1
)
RETURNING c_orderline_id, aberp_servicepattern_id, aberp_support_start_day, aberp_support_end_day;

-- Resolve display names
SELECT ol.c_orderline_id, ol.aberp_support_start_day, rs.name AS start_display,
       ol.aberp_support_end_day, re.name AS end_display
FROM c_orderline ol
LEFT JOIN ad_ref_list rs ON rs.ad_reference_id = 1001957 AND rs.value = ol.aberp_support_start_day
LEFT JOIN ad_ref_list re ON re.ad_reference_id = 1001957 AND re.value = ol.aberp_support_end_day
WHERE ol.aberp_servicepattern_id = 1000000
LIMIT 5;

-- Distinguish Monday day 2 vs day 9
SELECT value, name FROM ad_ref_list
WHERE ad_reference_id = 1001957 AND value IN ('2','9')
ORDER BY value::int;
