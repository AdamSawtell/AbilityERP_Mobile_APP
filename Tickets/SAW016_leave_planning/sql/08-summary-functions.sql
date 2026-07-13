-- SAW016 — Summary via DB functions (avoid nested FROM in ColumnSQL for AccessSqlParser)
SET search_path TO adempiere;

CREATE OR REPLACE FUNCTION aberp_lp_summary_by_status(p_id numeric)
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(string_agg(x.line, chr(10) ORDER BY x.ord), 'No matching leave')
         || chr(10) || 'Total: ' || (
           SELECT COUNT(*)::text
           FROM aberp_unavailability_leave ul
           JOIN ad_user u ON u.ad_user_id = ul.aberp_user_contact_id
           JOIN aberp_leave_planning p ON p.aberp_leave_planning_id = p_id
           WHERE ul.isactive = 'Y'
             AND ul.startdate::date <= p.enddate::date
             AND ul.enddate::date >= p.startdate::date
             AND (
               p.isalllocations = 'Y'
               OR (
                 COALESCE(p.c_bpartner_location_ids, '') <> ''
                 AND u.c_bpartner_location_id = ANY (
                   string_to_array(regexp_replace(p.c_bpartner_location_ids, '[^0-9,]', '', 'g'), ',')::numeric[]
                 )
               )
             )
         )
  FROM (
    SELECT CASE COALESCE(ul.aberp_approverstatus, '')
             WHEN 'RV' THEN 1 WHEN 'AP' THEN 2 WHEN 'DC' THEN 3 ELSE 9 END AS ord,
           CASE COALESCE(ul.aberp_approverstatus, '')
             WHEN 'RV' THEN 'Reviewing'
             WHEN 'AP' THEN 'Approved'
             WHEN 'DC' THEN 'Declined'
             WHEN '' THEN '(Blank)'
             ELSE COALESCE(ul.aberp_approverstatus, '')
           END || ': ' || COUNT(*)::text AS line
    FROM aberp_unavailability_leave ul
    JOIN ad_user u ON u.ad_user_id = ul.aberp_user_contact_id
    JOIN aberp_leave_planning p ON p.aberp_leave_planning_id = p_id
    WHERE ul.isactive = 'Y'
      AND ul.startdate::date <= p.enddate::date
      AND ul.enddate::date >= p.startdate::date
      AND (
        p.isalllocations = 'Y'
        OR (
          COALESCE(p.c_bpartner_location_ids, '') <> ''
          AND u.c_bpartner_location_id = ANY (
            string_to_array(regexp_replace(p.c_bpartner_location_ids, '[^0-9,]', '', 'g'), ',')::numeric[]
          )
        )
      )
    GROUP BY ul.aberp_approverstatus
  ) x;
$$;

CREATE OR REPLACE FUNCTION aberp_lp_summary_by_type(p_id numeric)
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(string_agg(x.line, chr(10) ORDER BY x.ord, x.tname), 'No matching leave')
  FROM (
    SELECT CASE COALESCE(ul.aberp_approverstatus, '')
             WHEN 'RV' THEN 1 WHEN 'AP' THEN 2 WHEN 'DC' THEN 3 ELSE 9 END AS ord,
           ut.name AS tname,
           CASE COALESCE(ul.aberp_approverstatus, '')
             WHEN 'RV' THEN 'Reviewing'
             WHEN 'AP' THEN 'Approved'
             WHEN 'DC' THEN 'Declined'
             WHEN '' THEN '(Blank)'
             ELSE COALESCE(ul.aberp_approverstatus, '')
           END || ' — ' || ut.name || ': ' || COUNT(*)::text AS line
    FROM aberp_unavailability_leave ul
    JOIN ad_user u ON u.ad_user_id = ul.aberp_user_contact_id
    JOIN aberp_unavailability_type ut ON ut.aberp_unavailability_type_id = ul.aberp_unavailability_type_id
    JOIN aberp_leave_planning p ON p.aberp_leave_planning_id = p_id
    WHERE ul.isactive = 'Y'
      AND ul.startdate::date <= p.enddate::date
      AND ul.enddate::date >= p.startdate::date
      AND (
        p.isalllocations = 'Y'
        OR (
          COALESCE(p.c_bpartner_location_ids, '') <> ''
          AND u.c_bpartner_location_id = ANY (
            string_to_array(regexp_replace(p.c_bpartner_location_ids, '[^0-9,]', '', 'g'), ',')::numeric[]
          )
        )
      )
    GROUP BY ul.aberp_approverstatus, ut.name
  ) x;
$$;

UPDATE ad_column SET
  columnsql = 'aberp_lp_summary_by_status(AbERP_Leave_Planning.AbERP_Leave_Planning_ID)',
  updated = NOW(),
  updatedby = 100
WHERE ad_column_uu = '16a016c0-0017-4f01-8e15-000000000001'
   OR (columnname = 'AbERP_SummaryByStatus'
       AND ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_Leave_Planning'));

UPDATE ad_column SET
  columnsql = 'aberp_lp_summary_by_type(AbERP_Leave_Planning.AbERP_Leave_Planning_ID)',
  updated = NOW(),
  updatedby = 100
WHERE ad_column_uu = '16a016c0-0018-4f01-8e15-000000000001'
   OR (columnname = 'AbERP_SummaryByType'
       AND ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_Leave_Planning'));

-- Smoke
SELECT aberp_lp_summary_by_status(1000000);
SELECT aberp_lp_summary_by_type(1000000);
