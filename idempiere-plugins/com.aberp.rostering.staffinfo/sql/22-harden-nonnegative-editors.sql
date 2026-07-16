-- Harden Staff Rostering Info against ZK "non-negative only".
-- 1) Deactivate leftover Search columns that are not needed for Related Info
--    (Status / Supervisor — ID editors). Partner Location is shown as suburb
--    String in the result grid (see also 26-show-partner-location-suburb.sql).
-- 2) Show Gender / Position as String names in the grid (no Table Direct Intbox).
-- 3) Clear leftover seqnoselection on non-criteria flags.
-- Keep C_BPartner_ID + AD_User_ID active for Related Info parent keys.
SET search_path TO adempiere;

DO $$
DECLARE
  v_iw NUMERIC;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf';
  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'AD_InfoWindow UU 2b4ab146-0809-47c6-96f3-8b841d60a6bf not found';
  END IF;

  UPDATE ad_infocolumn SET
    isactive = 'N',
    isquerycriteria = 'N',
    isdisplayed = 'N',
    seqnoselection = 0,
    defaultvalue = NULL,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND columnname IN ('R_Status_ID', 'Supervisor_ID')
    AND COALESCE(isquerycriteria, 'N') = 'N';

  -- Gender: display name, not Table Direct ID
  UPDATE ad_infocolumn SET
    ad_reference_id = 10, -- String
    selectclause = '(SELECT g.Name FROM AbERP_Gender g WHERE g.AbERP_Gender_ID = bp.AbERP_Gender_ID)',
    isquerycriteria = 'N',
    seqnoselection = 0,
    queryoperator = NULL,
    defaultvalue = NULL,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infocolumn_uu = '22426da0-28ec-4047-8eff-0cb186e556b6';

  -- Position: display job name, not Table Direct ID
  UPDATE ad_infocolumn SET
    ad_reference_id = 10, -- String
    selectclause = '(SELECT j.Name FROM C_Job j WHERE j.C_Job_ID = bp.C_Job_ID)',
    isquerycriteria = 'N',
    seqnoselection = 0,
    queryoperator = NULL,
    defaultvalue = NULL,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infocolumn_uu = 'b70b7e4e-23f7-45e1-92b2-7b40e4e3c908';

  -- Partner Location: suburb text in results only (not ID Search criteria)
  UPDATE ad_infocolumn SET
    isactive = 'Y',
    isdisplayed = 'Y',
    isquerycriteria = 'N',
    ishideinfocolumn = 'N',
    seqnoselection = 0,
    defaultvalue = NULL,
    queryoperator = NULL,
    queryfunction = NULL,
    ad_reference_id = 10, -- String
    ad_reference_value_id = NULL,
    name = 'Partner Location',
    description = 'Staff partner location suburb (City) for search results. Not a filter.',
    selectclause = '(SELECT COALESCE(NULLIF(TRIM(l.City), ''''), bpl.Name) FROM C_BPartner_Location bpl LEFT JOIN C_Location l ON (l.C_Location_ID = bpl.C_Location_ID) WHERE bpl.C_BPartner_Location_ID = au.C_BPartner_Location_ID)',
    updated = NOW(),
    updatedby = 100
  WHERE ad_infocolumn_uu = '904ffc84-b66a-4ec4-9984-5b85f9ad9545';

  UPDATE ad_infocolumn SET
    seqnoselection = 0,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND columnname IN ('AbERP_OnApprovedLeave', 'AbERP_ShowUnmatchedStaff')
    AND COALESCE(isquerycriteria, 'N') = 'N';

  -- Related Info parents stay active
  UPDATE ad_infocolumn SET isactive = 'Y', updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND ad_infocolumn_uu IN (
      '3402dcb1-ec9b-46b3-a8a6-8248b89cc4f4',
      '42578105-dbb8-4f51-9e53-8af7e5073997'
    );

  RAISE NOTICE '22-harden-nonnegative applied on AD_InfoWindow_ID=%', v_iw;
END $$;

SELECT columnname, name, isactive, isquerycriteria, isdisplayed, ad_reference_id, left(selectclause,70) AS selectclause
FROM ad_infocolumn
WHERE ad_infowindow_id = (
    SELECT ad_infowindow_id FROM ad_infowindow
    WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf'
  )
  AND (
    columnname IN (
      'AbERP_Gender_ID','C_Job_ID','R_Status_ID','Supervisor_ID',
      'C_BPartner_Location_ID','C_BPartner_ID','AD_User_ID','Name','IsEmployee','AbERP_isagencystaff'
    )
  )
ORDER BY columnname;
