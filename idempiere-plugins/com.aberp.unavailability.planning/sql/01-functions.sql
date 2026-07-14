-- =============================================================================
-- SAW021 — DB helpers (AccessSqlParser-safe display + summaries)
-- =============================================================================
SET search_path TO adempiere;

CREATE OR REPLACE FUNCTION aberp_up_primary_support_location(p_user_id numeric)
RETURNS character varying
LANGUAGE sql
STABLE
AS $fn$
  SELECT sl.Name
  FROM AbERP_Rostered_ShiftStaff ss
  INNER JOIN AbERP_Rostered_Shift rs
    ON (rs.AbERP_Rostered_Shift_ID = ss.AbERP_Rostered_Shift_ID AND rs.IsActive = 'Y')
  INNER JOIN AbERP_MasterLocation ml
    ON (ml.AbERP_MasterLocation_ID = rs.AbERP_MasterLocation_ID)
  INNER JOIN AbERP_Support_Location sl
    ON (sl.C_BPartner_Location_ID = ml.C_BPartner_Location_ID AND sl.IsActive = 'Y')
  WHERE ss.AbERP_User_Contact_ID = p_user_id
    AND ss.IsActive = 'Y'
  GROUP BY sl.Name
  ORDER BY COUNT(*) DESC
  LIMIT 1
$fn$;

COMMENT ON FUNCTION aberp_up_primary_support_location(numeric) IS
  'SAW021: primary Support Location name for Unavailability Planning Info grid';

CREATE OR REPLACE FUNCTION aberp_up_unavailable_pattern(p_ongoing_id numeric)
RETURNS text
LANGUAGE sql
STABLE
AS $fn$
  SELECT string_agg(x.piece, '; ' ORDER BY x.ord, x.piece)
  FROM (
    SELECT d.aberp_unavailabledays_id AS ord,
           COALESCE(
             NULLIF(TRIM(
               COALESCE(d.aberp_rosterstartday::text, '')
               || CASE
                    WHEN d.aberp_rosterendday IS NOT NULL
                     AND d.aberp_rosterendday IS DISTINCT FROM d.aberp_rosterstartday
                    THEN '-' || d.aberp_rosterendday::text
                    ELSE ''
                  END
             ), ''),
             '?'
           )
           || CASE
                WHEN d.starttime IS NOT NULL OR d.endtime IS NOT NULL THEN
                  ' '
                  || COALESCE(to_char(d.starttime::time, 'HH24:MI'), '??:??')
                  || '-'
                  || COALESCE(to_char(d.endtime::time, 'HH24:MI'), '??:??')
                ELSE ''
              END AS piece
    FROM aberp_unavailabledays d
    WHERE d.aberp_ongoingunavailability_id = p_ongoing_id
      AND d.isactive = 'Y'
  ) x
$fn$;

COMMENT ON FUNCTION aberp_up_unavailable_pattern(numeric) IS
  'SAW021: compact Unavailable Days pattern (roster day + time) for Info grid';

DROP FUNCTION IF EXISTS aberp_up_info_summary_by_status(timestamp, timestamp, numeric, text, numeric, numeric);
DROP FUNCTION IF EXISTS aberp_up_info_summary_by_status(timestamp, timestamp, numeric, text, numeric);
DROP FUNCTION IF EXISTS aberp_up_info_summary_day_lines(timestamp, timestamp, numeric, text, numeric);
DROP FUNCTION IF EXISTS aberp_up_info_summary_by_type(timestamp, timestamp, numeric, text, numeric, numeric);

CREATE OR REPLACE FUNCTION aberp_up_loc_match(p_user_id numeric, p_loc numeric)
RETURNS boolean
LANGUAGE sql
STABLE
AS $fn$
  SELECT p_loc IS NULL
      OR EXISTS (
           SELECT 1
           FROM AbERP_Rostered_ShiftStaff ss
           INNER JOIN AbERP_Rostered_Shift rs
             ON (rs.AbERP_Rostered_Shift_ID = ss.AbERP_Rostered_Shift_ID AND rs.IsActive = 'Y')
           INNER JOIN AbERP_MasterLocation ml
             ON (ml.AbERP_MasterLocation_ID = rs.AbERP_MasterLocation_ID)
           WHERE ss.AbERP_User_Contact_ID = p_user_id
             AND ss.IsActive = 'Y'
             AND ml.C_BPartner_Location_ID = p_loc
         );
$fn$;

CREATE OR REPLACE FUNCTION aberp_up_info_summary_by_status(
  p_start timestamp,
  p_end timestamp,
  p_loc numeric DEFAULT NULL,
  p_approver text DEFAULT NULL,
  p_user numeric DEFAULT NULL
)
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(string_agg(x.line, ' | ' ORDER BY x.ord), 'No matching unavailability')
         || '  |  Total: ' || COALESCE((
           SELECT COUNT(*)::text
           FROM aberp_ongoingunavailability ou
           JOIN ad_user u ON u.ad_user_id = ou.aberp_user_contact_id
           WHERE ou.isactive = 'Y'
             AND ou.enddate::date >= p_start::date
             AND ou.startdate::date <= p_end::date
             AND aberp_up_loc_match(u.ad_user_id, p_loc)
             AND (p_approver IS NULL OR p_approver = '' OR ou.aberp_approverstatus = p_approver)
             AND (p_user IS NULL OR ou.aberp_user_contact_id = p_user)
         ), '0')
  FROM (
    SELECT CASE COALESCE(ou.aberp_approverstatus, '')
             WHEN 'RV' THEN 1 WHEN 'AP' THEN 2 WHEN 'DC' THEN 3 ELSE 9 END AS ord,
           CASE COALESCE(ou.aberp_approverstatus, '')
             WHEN 'RV' THEN 'Reviewing'
             WHEN 'AP' THEN 'Approved'
             WHEN 'DC' THEN 'Declined'
             WHEN '' THEN '(Blank)'
             ELSE COALESCE(ou.aberp_approverstatus, '')
           END || ': ' || COUNT(*)::text AS line
    FROM aberp_ongoingunavailability ou
    JOIN ad_user u ON u.ad_user_id = ou.aberp_user_contact_id
    WHERE ou.isactive = 'Y'
      AND ou.enddate::date >= p_start::date
      AND ou.startdate::date <= p_end::date
      AND aberp_up_loc_match(u.ad_user_id, p_loc)
      AND (p_approver IS NULL OR p_approver = '' OR ou.aberp_approverstatus = p_approver)
      AND (p_user IS NULL OR ou.aberp_user_contact_id = p_user)
    GROUP BY ou.aberp_approverstatus
  ) x;
$$;

CREATE OR REPLACE FUNCTION aberp_up_info_summary_day_lines(
  p_start timestamp,
  p_end timestamp,
  p_loc numeric DEFAULT NULL,
  p_approver text DEFAULT NULL,
  p_user numeric DEFAULT NULL
)
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT 'Headers: ' || COUNT(DISTINCT ou.aberp_ongoingunavailability_id)::text
         || '  |  Day lines: ' || COUNT(d.aberp_unavailabledays_id)::text
         || '  |  With pattern: ' || COUNT(DISTINCT ou.aberp_ongoingunavailability_id)
              FILTER (WHERE d.aberp_unavailabledays_id IS NOT NULL)::text
  FROM aberp_ongoingunavailability ou
  JOIN ad_user u ON u.ad_user_id = ou.aberp_user_contact_id
  LEFT JOIN aberp_unavailabledays d
    ON d.aberp_ongoingunavailability_id = ou.aberp_ongoingunavailability_id
   AND d.isactive = 'Y'
  WHERE ou.isactive = 'Y'
    AND ou.enddate::date >= p_start::date
    AND ou.startdate::date <= p_end::date
    AND aberp_up_loc_match(u.ad_user_id, p_loc)
    AND (p_approver IS NULL OR p_approver = '' OR ou.aberp_approverstatus = p_approver)
    AND (p_user IS NULL OR ou.aberp_user_contact_id = p_user);
$$;
