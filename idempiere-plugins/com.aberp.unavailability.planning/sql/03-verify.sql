-- SAW021 verify
SET search_path TO adempiere;

SELECT iw.name, iw.ad_infowindow_uu, iw.isvalid, iw.fromclause
FROM ad_infowindow iw
WHERE iw.ad_infowindow_uu = '21a021iw-c0d4-4f01-8e15-000000000001';

SELECT COUNT(*) AS columns
FROM ad_infocolumn c
JOIN ad_infowindow iw ON iw.ad_infowindow_id = c.ad_infowindow_id
WHERE iw.ad_infowindow_uu = '21a021iw-c0d4-4f01-8e15-000000000001';

SELECT m.name, m.action, m.ad_menu_uu
FROM ad_menu m
WHERE m.ad_menu_uu = '21a02105-c0d4-4f01-8e15-000000000001';

SELECT COUNT(*) AS jan2027
FROM aberp_ongoingunavailability ou
WHERE ou.isactive = 'Y'
  AND ou.enddate::date >= DATE '2027-01-01'
  AND ou.startdate::date <= DATE '2027-01-31';

SELECT aberp_up_info_summary_by_status(TIMESTAMP '2027-01-01', TIMESTAMP '2027-01-31', NULL, NULL, NULL);
SELECT aberp_up_info_summary_day_lines(TIMESTAMP '2027-01-01', TIMESTAMP '2027-01-31', NULL, NULL, NULL);

SELECT LEFT(aberp_up_unavailable_pattern(1000070), 120) AS sample_pattern;
