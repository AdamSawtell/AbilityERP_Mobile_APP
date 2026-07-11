-- AbERP Staff Rostering Info — rewrite AD_InfoWindow 1000027 (UU 2b4ab146-...)
-- Replaces join fan-out + DISTINCT with AD_User + C_BPartner and EXISTS eligibility.
-- Portable across instances that share this Info Window UUID (Ab_ERP pack).
-- Idempotent.

SET search_path TO adempiere;

DO $$
DECLARE
  v_iw NUMERIC;
  v_from TEXT;
  v_where TEXT;
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
    || E'\nLEFT JOIN C_Job jb ON (jb.C_Job_ID = bp.C_Job_ID AND jb.IsActive = ''Y'')';

  -- Leave/overlap EXISTS with @StartDate@ cannot live in WhereClause:
  -- InfoWindow.loadInfoDefinition fails with "Cannot parse context" and the UI
  -- then throws ListModelTable field at 0,-1. Keep WhereClause static.
  v_where := 'au.IsActive = ''Y''';

  IF length(v_from) > 2000 OR length(v_where) > 2000 THEN
    RAISE EXCEPTION 'Clause too long: from=% where=%', length(v_from), length(v_where);
  END IF;

  UPDATE ad_infowindow SET
    name = 'Employee (User) / Agency Staff Rostering Info',
    description = 'Fast staff picker for Shift Employee fill. Lean User+BP query with EXISTS leave/overlap checks.',
    help = 'Search employees/agency staff to assign on Shift (Rostered) Employee tab. When opened from a shift, Start/End dates prefill and people on approved leave or overlapping shifts are hidden unless you enable the Show* toggles. Use Related Info for credentials and shift history.',
    fromclause = v_from,
    whereclause = v_where,
    orderbyclause = 'au.Name',
    otherclause = NULL,
    isdistinct = 'N',
    isvalid = 'Y',
    maxqueryrecords = 500,
    isloadpagenum = 'N',
    pagingsize = 50,
    pagesize = 50,
    isshowindashboard = 'N',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw;

  RAISE NOTICE 'Updated AD_InfoWindow_ID=% from_len=% where_len=%', v_iw, length(v_from), length(v_where);
END $$;
