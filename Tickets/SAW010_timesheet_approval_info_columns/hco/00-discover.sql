SET search_path TO adempiere;

-- Info window
SELECT ad_infowindow_id, ad_infowindow_uu, name, isvalid,
       left(coalesce(fromclause,''),160) AS from_snip
FROM ad_infowindow
WHERE ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4'
   OR name ILIKE '%Timesheet Approval%';

-- columns of interest
SELECT c.ad_infocolumn_id, c.ad_infocolumn_uu, c.columnname, c.name,
       c.isdisplayed, c.isquerycriteria, c.seqno, c.selectclause
FROM ad_infocolumn c
JOIN ad_infowindow iw ON iw.ad_infowindow_id = c.ad_infowindow_id
WHERE iw.ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4'
   OR iw.name ILIKE '%Timesheet Approval%'
ORDER BY c.seqno, c.columnname;

-- process link
SELECT p.name, p.ad_process_uu, ip.ad_infocolumn_id, ic.columnname
FROM ad_infoprocess ip
JOIN ad_process p ON p.ad_process_id = ip.ad_process_id
JOIN ad_infowindow iw ON iw.ad_infowindow_id = ip.ad_infowindow_id
LEFT JOIN ad_infocolumn ic ON ic.ad_infocolumn_id = ip.ad_infocolumn_id
WHERE iw.ad_infowindow_uu = '40d6a2d7-3bbc-431e-940c-ce75829a68e4'
   OR p.ad_process_uu = '3a3c2c41-995c-41ba-9fde-caeaacee1d75';

-- break physical cols
SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='aberp_timesheetandexpenses'
  AND column_name IN ('aberp_break_start','aberp_break_end');
