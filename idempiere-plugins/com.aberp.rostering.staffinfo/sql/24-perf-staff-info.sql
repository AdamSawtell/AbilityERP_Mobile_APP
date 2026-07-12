-- SAW003 perf: Staff Rostering Info ReQuery on large HCO datasets.
-- 1) Composite index for credential match (credentials_id + user).
-- 2) Gender join in FROM (avoid per-row scalar subquery); Position uses existing C_Job join.
-- Safe to re-run. Does not change any *_UU.
SET search_path TO adempiere;

CREATE INDEX IF NOT EXISTS aberp_credassign_cred_user_active
  ON aberp_credentialassignment (aberp_credentials_id, aberp_user_contact_id)
  WHERE isactive = 'Y'
    AND COALESCE(aberp_user_contact_id, 0) > 0
    AND COALESCE(aberp_credentials_id, 0) > 0;

CREATE INDEX IF NOT EXISTS aberp_unavail_leave_user_status_dates
  ON aberp_unavailability_leave (aberp_user_contact_id, startdate, enddate)
  WHERE isactive = 'Y' AND aberp_approverstatus = 'AP';

DO $$
DECLARE
  v_iw NUMERIC;
  v_from TEXT;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf';
  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'AD_InfoWindow UU 2b4ab146-0809-47c6-96f3-8b841d60a6bf not found';
  END IF;

  v_from :=
    'AD_User au'
    || E'\nINNER JOIN C_BPartner bp ON (bp.C_BPartner_ID = au.C_BPartner_ID AND bp.IsActive = ''Y'')'
    || E'\nLEFT JOIN C_Job jb ON (jb.C_Job_ID = bp.C_Job_ID AND jb.IsActive = ''Y'')'
    || E'\nLEFT JOIN AbERP_Gender g ON (g.AbERP_Gender_ID = bp.AbERP_Gender_ID)';

  UPDATE ad_infowindow SET
    fromclause = v_from,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw;

  -- Gender / Position: use joins (String display), not correlated subselects
  UPDATE ad_infocolumn SET
    ad_reference_id = 10,
    selectclause = 'g.Name',
    isquerycriteria = 'N',
    seqnoselection = 0,
    queryoperator = NULL,
    defaultvalue = NULL,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infocolumn_uu = '22426da0-28ec-4047-8eff-0cb186e556b6';

  UPDATE ad_infocolumn SET
    ad_reference_id = 10,
    selectclause = 'jb.Name',
    isquerycriteria = 'N',
    seqnoselection = 0,
    queryoperator = NULL,
    defaultvalue = NULL,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infocolumn_uu = 'b70b7e4e-23f7-45e1-92b2-7b40e4e3c908';

  RAISE NOTICE '24-perf-staff-info applied on AD_InfoWindow_ID=%', v_iw;
END $$;
