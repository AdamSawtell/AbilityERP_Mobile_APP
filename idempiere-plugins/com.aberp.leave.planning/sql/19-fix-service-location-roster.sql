-- =============================================================================
-- SAW016 — Fix Service Location mismatch
-- Criteria lookup = Support Locations, but grid/filter used AD_User home Partner
-- Location (Mount Barker, etc.) — zero leave rows match Support Location BPLs.
-- Real link: Rostered Shift → MasterLocation → Support Location (same BPL).
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_iw INTEGER;
  v_display TEXT :=
    '(SELECT string_agg(DISTINCT sl.Name, '', '' ORDER BY sl.Name)'
    || ' FROM AbERP_Rostered_ShiftStaff ss'
    || ' INNER JOIN AbERP_Rostered_Shift rs ON (rs.AbERP_Rostered_Shift_ID=ss.AbERP_Rostered_Shift_ID AND rs.IsActive=''Y'')'
    || ' INNER JOIN AbERP_MasterLocation ml ON (ml.AbERP_MasterLocation_ID=rs.AbERP_MasterLocation_ID)'
    || ' INNER JOIN AbERP_Support_Location sl ON (sl.C_BPartner_Location_ID=ml.C_BPartner_Location_ID AND sl.IsActive=''Y'')'
    || ' WHERE ss.AbERP_User_Contact_ID=u.AD_User_ID AND ss.IsActive=''Y'')';
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001';
  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'SAW016: Leave Planning Info Window missing';
  END IF;

  -- Grid: Support Locations from rostered shifts (not home Partner Location)
  UPDATE ad_infocolumn SET
    name = 'Service Location',
    description = 'Support Locations where this employee is rostered (from shifts)',
    help = 'Distinct active Support Locations linked via Rostered Shift → Contract/Master Location. Not the employee home address.',
    selectclause = v_display,
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '16a016ic-0010-4f01-8e15-000000000001';

  -- Criteria help: filter is applied in LeavePlanningInfoWindow via shift EXISTS
  UPDATE ad_infocolumn SET
    description = 'Optional. Active Support Locations; blank = all. Filters staff rostered at that site.',
    help = 'Lists active Support Locations. Search keeps leave for employees who have rostered shifts at the selected site (Master Location sharing that Partner Location).',
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu = '16a016ic-0003-4f01-8e15-000000000001';

  UPDATE ad_infowindow SET
    help = 'Set Planning Start/End, optional Support Location (blank = all), then Search. '
      || 'Service Location filter uses rostered shifts at that Support Location — not the employee home address. '
      || 'Zoom a leave row to submit/approve.',
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw;

  RAISE NOTICE 'SAW016: Service Location display → rostered Support Locations';
END $$;

-- Summary helpers: p_loc = Support Location C_BPartner_Location_ID via shifts
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
             AND (p_loc IS NULL OR EXISTS (
               SELECT 1 FROM aberp_rostered_shiftstaff ss
               JOIN aberp_rostered_shift rs ON rs.aberp_rostered_shift_id = ss.aberp_rostered_shift_id AND rs.isactive = 'Y'
               JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = rs.aberp_masterlocation_id
               WHERE ss.aberp_user_contact_id = u.ad_user_id AND ss.isactive = 'Y'
                 AND ml.c_bpartner_location_id = p_loc
             ))
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
      AND (p_loc IS NULL OR EXISTS (
        SELECT 1 FROM aberp_rostered_shiftstaff ss
        JOIN aberp_rostered_shift rs ON rs.aberp_rostered_shift_id = ss.aberp_rostered_shift_id AND rs.isactive = 'Y'
        JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = rs.aberp_masterlocation_id
        WHERE ss.aberp_user_contact_id = u.ad_user_id AND ss.isactive = 'Y'
          AND ml.c_bpartner_location_id = p_loc
      ))
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
      AND (p_loc IS NULL OR EXISTS (
        SELECT 1 FROM aberp_rostered_shiftstaff ss
        JOIN aberp_rostered_shift rs ON rs.aberp_rostered_shift_id = ss.aberp_rostered_shift_id AND rs.isactive = 'Y'
        JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = rs.aberp_masterlocation_id
        WHERE ss.aberp_user_contact_id = u.ad_user_id AND ss.isactive = 'Y'
          AND ml.c_bpartner_location_id = p_loc
      ))
      AND (p_approver IS NULL OR p_approver = '' OR ul.aberp_approverstatus = p_approver)
      AND (p_type IS NULL OR ul.aberp_unavailability_type_id = p_type)
      AND (p_user IS NULL OR ul.aberp_user_contact_id = p_user)
    GROUP BY ul.aberp_approverstatus, ut.name
  ) x;
$$;

SELECT selectclause
FROM ad_infocolumn ic
JOIN ad_infowindow iw ON iw.ad_infowindow_id = ic.ad_infowindow_id
WHERE iw.ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001'
  AND ic.columnname = 'AbERP_LP_ServiceLocation';
