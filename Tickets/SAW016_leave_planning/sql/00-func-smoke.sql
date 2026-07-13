-- Functional overlap + summary ColumnSQL smoke
INSERT INTO aberp_leave_planning (
  aberp_leave_planning_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby, aberp_leave_planning_uu,
  name, startdate, enddate, isalllocations
) VALUES (
  1000000, 1000003, 1000003, 'Y',
  NOW(), 100, NOW(), 100, '16a016te-0000-4000-8000-000000000001',
  'SAW016 smoke Jan 2027', '2027-01-01', '2027-01-31', 'Y'
) ON CONFLICT DO NOTHING;

SELECT name, startdate::date, enddate::date, isalllocations,
  (SELECT COUNT(*) FROM aberp_unavailability_leave ul
   WHERE ul.isactive='Y'
     AND ul.startdate::date <= p.enddate::date
     AND ul.enddate::date >= p.startdate::date) AS overlap_cnt
FROM aberp_leave_planning p WHERE aberp_leave_planning_id=1000000;

-- Evaluate summary columnsql by selecting via AD expression pattern
SELECT
(
SELECT COALESCE(string_agg(x.line, E'\n' ORDER BY x.ord), 'No matching leave')
FROM (
  SELECT CASE COALESCE(ul.AbERP_ApproverStatus,'')
           WHEN 'RV' THEN 1 WHEN 'AP' THEN 2 WHEN 'DC' THEN 3 ELSE 9 END AS ord,
         CASE COALESCE(ul.AbERP_ApproverStatus,'')
           WHEN 'RV' THEN 'Reviewing' WHEN 'AP' THEN 'Approved' WHEN 'DC' THEN 'Declined'
           WHEN '' THEN '(Blank)' ELSE COALESCE(ul.AbERP_ApproverStatus,'')
         END || ': ' || COUNT(*)::text AS line
  FROM AbERP_Unavailability_Leave ul
  JOIN AD_User u ON u.AD_User_ID = ul.AbERP_User_Contact_ID
  WHERE ul.IsActive='Y'
    AND ul.StartDate::date <= p.EndDate::date
    AND ul.EndDate::date >= p.StartDate::date
    AND p.IsAllLocations = 'Y'
  GROUP BY ul.AbERP_ApproverStatus
) x
) AS summary_status
FROM aberp_leave_planning p WHERE aberp_leave_planning_id=1000000;

-- Date check constraint
DO $$
BEGIN
  BEGIN
    INSERT INTO aberp_leave_planning (
      aberp_leave_planning_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, startdate, enddate, isalllocations
    ) VALUES (
      1000001, 1000003, 1000003, 'Y', NOW(), 100, NOW(), 100,
      'bad dates', '2027-02-01', '2027-01-01', 'Y'
    );
    RAISE EXCEPTION 'CHECK should have failed';
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'Date CHECK OK (rejected End < Start)';
  END;
END $$;

SELECT whereclause FROM ad_tab t
JOIN ad_window w ON w.ad_window_id=t.ad_window_id
WHERE w.name='Leave Planning' AND t.name='Leave Records';
