-- Register Accept Shift Request process and toolbar button on Response Log tab.
-- Run against idempiere schema after deploying com.aberp.rosteredshift.process JAR.
SET search_path TO adempiere;

-- AD_Process: SHIFT_ACCEPT_REQUEST (id 1000709)
INSERT INTO ad_process (
  ad_process_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  value, name, description,
  accesslevel, entitytype,
  isreport, isdirectprint,
  classname,
  isbetafunctionality, isserverprocess, showhelp,
  copyfromprocess, ad_process_uu,
  allowmultipleexecution, isprinterpreview
)
SELECT
  1000709, 0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'SHIFT_ACCEPT_REQUEST', 'Accept Shift Request',
  'Accept a worker shift request from the response log and assign them to the rostered shift.',
  '3', 'Ab_ERP',
  'N', 'N',
  'com.aberp.rosteredshift.process.AcceptShiftRequest',
  'N', 'N', 'S',
  'N', 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
  'P', 'N'
WHERE NOT EXISTS (
  SELECT 1 FROM ad_process WHERE value = 'SHIFT_ACCEPT_REQUEST'
);

-- Process access — REQUIRED (see docs/DEV-REQUIREMENTS.md)
-- Always grant AbilityERP Admin; grant operational roles as needed.
INSERT INTO ad_process_access (
  ad_process_id, ad_role_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby, isreadwrite, ad_process_access_uu
)
SELECT p.ad_process_id, roles.ad_role_id, roles.ad_client_id, 0, 'Y',
  NOW(), 100, NOW(), 100, 'Y', NULL
FROM ad_process p
CROSS JOIN (
  VALUES
    (1000004, 1000002),  -- AbilityERP Admin (mandatory for all new features)
    (1000012, 1000002),  -- Rostering Officer
    (0, 0)               -- System Administrator
) AS roles(ad_role_id, ad_client_id)
WHERE p.value = 'SHIFT_ACCEPT_REQUEST'
  AND NOT EXISTS (
    SELECT 1 FROM ad_process_access x
    WHERE x.ad_process_id = p.ad_process_id
      AND x.ad_role_id = roles.ad_role_id
      AND x.ad_client_id = roles.ad_client_id
  );

-- Toolbar button on Response Log tab (ad_tab_id 1000366)
INSERT INTO ad_toolbarbutton (
  ad_toolbarbutton_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, componentname, action, ad_tab_id, ad_process_id,
  seqno, isadvancedbutton, isaddseparator, entitytype, iscustomization,
  displaylogic, ad_toolbarbutton_uu
)
SELECT
  1000008, 0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Accept Shift Request', 'Accept Shift Request', 'W', 1000366, p.ad_process_id,
  10, 'N', 'N', 'Ab_ERP', 'N',
  '@AbERP_RosteredResponse@=REQ & @IsReviewed@=N & @IsSuperseded@=N',
  'c1d2e3f4-a5b6-4789-c012-3456789abcde'
FROM ad_process p
WHERE p.value = 'SHIFT_ACCEPT_REQUEST'
  AND NOT EXISTS (
    SELECT 1 FROM ad_toolbarbutton tb
    WHERE tb.ad_tab_id = 1000366 AND tb.name = 'Accept Shift Request'
  );
