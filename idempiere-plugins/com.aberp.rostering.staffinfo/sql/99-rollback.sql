-- AbERP Staff Rostering Info — rollback to pre-rewrite join fan-out definition
-- Use only if you must restore the old behaviour on this instance.

SET search_path TO adempiere;

UPDATE ad_infowindow SET
  description = NULL,
  help = NULL,
  fromclause =
    'AD_User au'
    || E'\nLEFT JOIN C_BPartner bp                                         ON (bp.C_BPartner_ID = au.C_BPartner_ID AND bp.IsActive = ''Y'')'
    || E'\nLEFT JOIN AbERP_Rostered_ShiftStaff rss         ON (rss.AbERP_User_Contact_ID = au.AD_User_ID AND rss.IsActive = ''Y'' )'
    || E'\nLEFT JOIN AbERP_Rostered_Shift rs                       ON (rs.AbERP_Rostered_Shift_ID = rss.AbERP_Rostered_Shift_ID AND rs.AbERP_isShiftRosteredTemplate = ''N'' AND rs.IsActive = ''Y'' AND rs.StartDate >= (NOW() - INTERVAL ''3 months'') )'
    || E'\nLEFT JOIN AbERP_CredentialAssignment ca         ON (ca.AbERP_User_Contact_ID = au.AD_User_ID AND ca.IsActive = ''Y'')'
    || E'\nLEFT JOIN AbERP_Unavailability_Leave ul         ON (ul.AbERP_User_Contact_ID = au.AD_User_ID AND ul.IsActive = ''Y'')'
    || E'\nLEFT JOIN AbERP_Related_Rostering_Needs_V rv ON (rv.AbERP_Rostered_Shift_ID = rs.AbERP_Rostered_Shift_ID  )'
    || E'\nLEFT JOIN C_Job jb                                                      ON (jb.C_Job_ID = bp.C_Job_ID AND jb.IsActive = ''Y'' )'
    || E'\nLEFT JOIN AbERP_SR_Needs_Rules nr                       ON (nr.C_Job_ID = jb.C_Job_ID AND nr.IsActive = ''Y'')'
    || E'\nLEFT JOIN bi_aberp_rostered_shiftstaff rs_v        ON (rs_v.AbERP_User_Contact_ID = au.AD_User_ID AND rs_v.IsActive = ''Y''  AND rs_v.AbERP_isShiftRosteredTemplate = ''N'')',
  whereclause = 'au.IsActive = ''Y''',
  orderbyclause = NULL,
  otherclause = NULL,
  isdistinct = 'Y',
  maxqueryrecords = 0,
  isloadpagenum = 'Y',
  pagingsize = 0,
  pagesize = 0,
  isshowindashboard = 'Y',
  isvalid = 'Y',
  updated = NOW(),
  updatedby = 100
WHERE ad_infowindow_uu = '2b4ab146-0809-47c6-96f3-8b841d60a6bf';

-- Re-activate previously deactivated join criteria (does not restore every column default nuance)
UPDATE ad_infocolumn SET isactive = 'Y', isquerycriteria = 'Y', updated = NOW(), updatedby = 100
WHERE ad_infocolumn_uu IN (
  'bf6693b4-56dd-4c1b-836d-3c0f517aad9d',
  '32efe3e4-4853-4656-bc45-a6e6672890ca',
  '3916bb24-c7be-4f78-96ee-77a711fba800',
  '2e35fde5-6164-4fd7-afc1-7d931d18bf64',
  'c4ab6130-0d64-4ce0-8be8-e6f7af56a98b',
  '40d550c2-4088-412d-8774-f2d2b2cd9247',
  '492b6870-a7b3-43f8-a9bd-7abf7b9efb49',
  '9ea712d2-845a-4dac-91cc-f4d641ec8072',
  '6a19cf0e-5972-49ae-9f56-bea3f649eb56',
  '40c40fdf-d0a1-4076-951f-f35e3deb463b'
);

UPDATE ad_infocolumn SET isactive = 'N', updated = NOW(), updatedby = 100
WHERE ad_infocolumn_uu IN (
  'a1b2c3d4-e5f6-7788-9900-aabbccdde001',
  'a1b2c3d4-e5f6-7788-9900-aabbccdde002'
);

UPDATE ad_infocolumn SET iskey = 'N', updated = NOW(), updatedby = 100
WHERE ad_infocolumn_uu = '3402dcb1-ec9b-46b3-a8a6-8248b89cc4f4';
