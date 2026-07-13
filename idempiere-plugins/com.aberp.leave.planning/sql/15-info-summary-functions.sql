-- =============================================================================
-- SAW016 — Leave Planning Info summary helpers (criteria-driven, not planning header)
-- Used by LeavePlanningInfoWindow banner after Search.
-- =============================================================================
SET search_path TO adempiere;

CREATE OR REPLACE FUNCTION aberp_lp_info_summary_by_status(
  p_start timestamp,
  p_end timestamp,
  p_loc numeric DEFAULT NULL,
  p_approver text DEFAULT NULL,
  p_type numeric DEFAULT NULL,
  p_user numeric DEFAULT NULL
)
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(string_agg(x.line, ' | ' ORDER BY x.ord), 'No matching leave')
         || '  |  Total: ' || COALESCE((
           SELECT COUNT(*)::text
           FROM aberp_unavailability_leave ul
           JOIN ad_user u ON u.ad_user_id = ul.aberp_user_contact_id
           WHERE ul.isactive = 'Y'
             AND ul.enddate::date >= p_start::date
             AND ul.startdate::date <= p_end::date
             AND (p_loc IS NULL OR u.c_bpartner_location_id = p_loc)
             AND (p_approver IS NULL OR p_approver = '' OR ul.aberp_approverstatus = p_approver)
             AND (p_type IS NULL OR ul.aberp_unavailability_type_id = p_type)
             AND (p_user IS NULL OR ul.aberp_user_contact_id = p_user)
         ), '0')
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
    WHERE ul.isactive = 'Y'
      AND ul.enddate::date >= p_start::date
      AND ul.startdate::date <= p_end::date
      AND (p_loc IS NULL OR u.c_bpartner_location_id = p_loc)
      AND (p_approver IS NULL OR p_approver = '' OR ul.aberp_approverstatus = p_approver)
      AND (p_type IS NULL OR ul.aberp_unavailability_type_id = p_type)
      AND (p_user IS NULL OR ul.aberp_user_contact_id = p_user)
    GROUP BY ul.aberp_approverstatus
  ) x;
$$;

CREATE OR REPLACE FUNCTION aberp_lp_info_summary_by_type(
  p_start timestamp,
  p_end timestamp,
  p_loc numeric DEFAULT NULL,
  p_approver text DEFAULT NULL,
  p_type numeric DEFAULT NULL,
  p_user numeric DEFAULT NULL
)
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(string_agg(x.line, ' | ' ORDER BY x.ord, x.tname), 'No type breakdown')
  FROM (
    SELECT CASE COALESCE(ul.aberp_approverstatus, '')
             WHEN 'RV' THEN 1 WHEN 'AP' THEN 2 WHEN 'DC' THEN 3 ELSE 9 END AS ord,
           COALESCE(ut.name, '(No type)') AS tname,
           CASE COALESCE(ul.aberp_approverstatus, '')
             WHEN 'RV' THEN 'Reviewing'
             WHEN 'AP' THEN 'Approved'
             WHEN 'DC' THEN 'Declined'
             WHEN '' THEN '(Blank)'
             ELSE COALESCE(ul.aberp_approverstatus, '')
           END || ' / ' || COALESCE(ut.name, '(No type)') || ': ' || COUNT(*)::text AS line
    FROM aberp_unavailability_leave ul
    JOIN ad_user u ON u.ad_user_id = ul.aberp_user_contact_id
    LEFT JOIN aberp_unavailability_type ut
      ON ut.aberp_unavailability_type_id = ul.aberp_unavailability_type_id
    WHERE ul.isactive = 'Y'
      AND ul.enddate::date >= p_start::date
      AND ul.startdate::date <= p_end::date
      AND (p_loc IS NULL OR u.c_bpartner_location_id = p_loc)
      AND (p_approver IS NULL OR p_approver = '' OR ul.aberp_approverstatus = p_approver)
      AND (p_type IS NULL OR ul.aberp_unavailability_type_id = p_type)
      AND (p_user IS NULL OR ul.aberp_user_contact_id = p_user)
    GROUP BY ul.aberp_approverstatus, ut.name
  ) x;
$$;
