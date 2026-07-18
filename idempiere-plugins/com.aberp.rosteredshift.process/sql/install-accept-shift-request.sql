-- =============================================================================
-- Accept Shift Request — portable Application Dictionary install (one script)
-- =============================================================================
-- NO hardcoded AD IDs — resolves tab/table/window/roles/reference by name.
-- Safe to run on any AbilityERP build (idempotent).
--
-- Run after JAR deploy (stop on first error):
--   psql -v ON_ERROR_STOP=1 -d idempiere -f install-accept-shift-request.sql
--
-- Then restart iDempiere and log out/in on WebUI.
-- =============================================================================

SET search_path TO adempiere;

-- ---------------------------------------------------------------------------
-- 0. Prerequisites
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_tab_id INTEGER;
  v_table_id INTEGER;
BEGIN
  SELECT ad_table_id INTO v_table_id
  FROM ad_table WHERE tablename = 'AbERP_RosteredResponseLog' AND isactive = 'Y' LIMIT 1;
  IF v_table_id IS NULL THEN
    RAISE EXCEPTION 'Table AbERP_RosteredResponseLog not found';
  END IF;

  SELECT t.ad_tab_id INTO v_tab_id
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
  WHERE w.name = 'Shift (Rostered)'
    AND t.name = 'Response Log'
    AND tb.tablename = 'AbERP_RosteredResponseLog'
    AND t.isactive = 'Y'
  LIMIT 1;

  IF v_tab_id IS NULL THEN
    RAISE EXCEPTION 'Response Log tab not found on Shift (Rostered) window';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Process
-- ---------------------------------------------------------------------------
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
  (SELECT COALESCE(MAX(ad_process_id), 0) + 1 FROM ad_process),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'SHIFT_ACCEPT_REQUEST', 'Accept Shift Request',
  'Accept a worker shift request from the response log and assign them to the rostered shift.',
  '3', 'Ab_ERP',
  'N', 'N',
  'com.aberp.rosteredshift.process.AcceptShiftRequest',
  'N', 'N', 'S',
  'N',
  (
    substring(md5('SHIFT_ACCEPT_REQUEST-process'), 1, 8) || '-' ||
    substring(md5('SHIFT_ACCEPT_REQUEST-process'), 9, 4) || '-4789-a012-3456789abcde'
  ),
  'P', 'N'
WHERE NOT EXISTS (
  SELECT 1 FROM ad_process WHERE value = 'SHIFT_ACCEPT_REQUEST'
);

-- ---------------------------------------------------------------------------
-- 2. Physical column for button field
-- ---------------------------------------------------------------------------
ALTER TABLE aberp_rosteredresponselog
  ADD COLUMN IF NOT EXISTS aberp_acceptshiftrequest character(1);

-- ---------------------------------------------------------------------------
-- 3. AD_Element
-- ---------------------------------------------------------------------------
INSERT INTO ad_element (
  ad_element_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  columnname, entitytype, name, printname, ad_element_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_element_id), 0) + 1 FROM ad_element),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'AbERP_AcceptShiftRequest', 'Ab_ERP', 'Accept Shift Request', 'Accept Shift Request',
  (
    substring(md5('AbERP_AcceptShiftRequest-element'), 1, 8) || '-' ||
    substring(md5('AbERP_AcceptShiftRequest-element'), 9, 4) || '-4012-d345-678901234567'
  )
WHERE NOT EXISTS (
  SELECT 1 FROM ad_element WHERE columnname = 'AbERP_AcceptShiftRequest'
);

INSERT INTO ad_element (
  ad_element_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  columnname, entitytype, name, printname, ad_element_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_element_id), 0) + 1 FROM ad_element),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'AbERP_IsShiftEmployeeVacant', 'Ab_ERP', 'Shift Employee Vacant', 'Shift Employee Vacant',
  (
    substring(md5('AbERP_IsShiftEmployeeVacant-element'), 1, 8) || '-' ||
    substring(md5('AbERP_IsShiftEmployeeVacant-element'), 9, 4) || '-4345-a678-901234567890'
  )
WHERE NOT EXISTS (
  SELECT 1 FROM ad_element WHERE columnname = 'AbERP_IsShiftEmployeeVacant'
);

-- ---------------------------------------------------------------------------
-- 4. AD_Column — button + virtual vacant flag
-- ---------------------------------------------------------------------------
INSERT INTO ad_column (
  ad_column_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, entitytype, columnname, ad_table_id,
  ad_reference_id, fieldlength, version,
  iskey, isparent, ismandatory, isupdateable, isidentifier, seqno,
  istranslated, isencrypted, isselectioncolumn,
  ad_element_id, ad_process_id, issyncdatabase, isalwaysupdateable,
  isautocomplete, isallowlogging, isallowcopy, seqnoselection,
  istoolbarbutton, issecure, fkconstrainttype, ishtml, isdisablezoomacross,
  ad_column_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_column_id), 0) + 1 FROM ad_column),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Accept Shift Request', 'Ab_ERP', 'AbERP_AcceptShiftRequest', tb.ad_table_id,
  COALESCE(
    (SELECT ad_reference_id FROM ad_reference WHERE name = 'Button' AND isactive = 'Y' LIMIT 1),
    (SELECT c2.ad_reference_id FROM ad_column c2
     WHERE c2.ad_table_id = tb.ad_table_id AND c2.istoolbarbutton IN ('B', 'Y') LIMIT 1),
    28
  ),
  1, 0,
  'N', 'N', 'N', 'Y', 'N', 0,
  'N', 'N', 'N',
  e.ad_element_id, p.ad_process_id, 'Y', 'N',
  'N', 'Y', 'Y', 0,
  'B', 'N', 'N', 'N', 'N',
  (
    substring(md5('AbERP_AcceptShiftRequest-col'), 1, 8) || '-' ||
    substring(md5('AbERP_AcceptShiftRequest-col'), 9, 4) || '-4123-e456-789012345678'
  )
FROM ad_element e
JOIN ad_process p ON p.value = 'SHIFT_ACCEPT_REQUEST'
CROSS JOIN ad_table tb
WHERE e.columnname = 'AbERP_AcceptShiftRequest'
  AND tb.tablename = 'AbERP_RosteredResponseLog' AND tb.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_column c
    WHERE c.columnname = 'AbERP_AcceptShiftRequest' AND c.ad_table_id = tb.ad_table_id
  );

INSERT INTO ad_column (
  ad_column_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, entitytype, columnname, ad_table_id,
  ad_reference_id, fieldlength, version,
  iskey, isparent, ismandatory, isupdateable, isidentifier, seqno,
  istranslated, isencrypted, isselectioncolumn,
  ad_element_id, issyncdatabase, isalwaysupdateable,
  isautocomplete, isallowlogging, isallowcopy,
  istoolbarbutton, issecure, fkconstrainttype, ishtml,
  columnsql, ad_column_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_column_id), 0) + 1 FROM ad_column),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Shift Employee Vacant', 'Ab_ERP', 'AbERP_IsShiftEmployeeVacant', tb.ad_table_id,
  COALESCE(
    (SELECT ad_reference_id FROM ad_reference WHERE name = 'Yes-No' AND isactive = 'Y' LIMIT 1),
    (SELECT c2.ad_reference_id FROM ad_column c2
     WHERE c2.ad_table_id = tb.ad_table_id AND c2.columnname = 'IsReviewed' LIMIT 1),
    20
  ),
  1, 0,
  'N', 'N', 'N', 'N', 'N', 0,
  'N', 'N', 'N',
  e.ad_element_id, 'N', 'N',
  'N', 'N', 'N',
  'N', 'N', 'N', 'N',
  '(SELECT CASE WHEN EXISTS (SELECT 1 FROM AbERP_Rostered_ShiftStaff ss WHERE ss.AbERP_Rostered_Shift_ID = AbERP_RosteredResponseLog.AbERP_Rostered_Shift_ID AND ss.IsActive=''Y'' AND COALESCE(ss.AbERP_User_Contact_ID,0) > 0) THEN ''N'' ELSE ''Y'' END)',
  (
    substring(md5('AbERP_IsShiftEmployeeVacant-col'), 1, 8) || '-' ||
    substring(md5('AbERP_IsShiftEmployeeVacant-col'), 9, 4) || '-4456-b789-012345678901'
  )
FROM ad_element e
CROSS JOIN ad_table tb
WHERE e.columnname = 'AbERP_IsShiftEmployeeVacant'
  AND tb.tablename = 'AbERP_RosteredResponseLog' AND tb.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_column c
    WHERE c.columnname = 'AbERP_IsShiftEmployeeVacant' AND c.ad_table_id = tb.ad_table_id
  );

-- ---------------------------------------------------------------------------
-- 5. AD_Field on Response Log tab (resolved by window + tab name)
-- ---------------------------------------------------------------------------
INSERT INTO ad_field (
  ad_field_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, iscentrallymaintained, ad_tab_id, ad_column_id,
  isdisplayed, displaylength, isreadonly, seqno,
  issameline, isheading, isfieldonly, isencrypted, entitytype,
  isdisplayedgrid, xposition, numlines, columnspan,
  isquickentry, istoolbarbutton, ad_field_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_field_id), 0) + 1 FROM ad_field),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'Shift Employee Vacant', 'N', tab.ad_tab_id, c.ad_column_id,
  'N', 1, 'Y', 62,
  'N', 'N', 'N', 'N', 'Ab_ERP',
  'N', 1, 1, 1,
  'N', 'N',
  (
    substring(md5('AbERP_IsShiftEmployeeVacant-field-' || tab.ad_tab_id::text), 1, 8) || '-' ||
    substring(md5('AbERP_IsShiftEmployeeVacant-field-' || tab.ad_tab_id::text), 9, 4) || '-4567-c890-123456789012'
  )
FROM ad_column c
CROSS JOIN ad_table tb
JOIN ad_tab tab ON tab.ad_table_id = tb.ad_table_id
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
WHERE c.columnname = 'AbERP_IsShiftEmployeeVacant'
  AND c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'AbERP_RosteredResponseLog'
  AND w.name = 'Shift (Rostered)' AND tab.name = 'Response Log' AND tab.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_field f
    WHERE f.ad_tab_id = tab.ad_tab_id AND f.ad_column_id = c.ad_column_id
  );

INSERT INTO ad_field (
  ad_field_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, iscentrallymaintained, ad_tab_id, ad_column_id,
  isdisplayed, displaylogic, displaylength, isreadonly, seqno,
  issameline, isheading, isfieldonly, isencrypted, entitytype,
  isdisplayedgrid, xposition, numlines, columnspan,
  isquickentry, istoolbarbutton, isadvancedfield, isdefaultfocus,
  isquickform, isselectioncolumn, isdisablezoomacross,
  ad_field_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_field_id), 0) + 1 FROM ad_field),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'Accept Shift Request', 'N', tab.ad_tab_id, c.ad_column_id,
  'Y',
  '@AbERP_RosteredResponse@=REQ & @IsReviewed@!Y & @IsSuperseded@!Y',
  1, 'N', 55,
  'N', 'N', 'N', 'N', 'Ab_ERP',
  'Y', 5, 1, 2,
  'N', 'Y', 'N', 'N',
  'N', 'N', 'N',
  (
    substring(md5('AbERP_AcceptShiftRequest-field-' || tab.ad_tab_id::text), 1, 8) || '-' ||
    substring(md5('AbERP_AcceptShiftRequest-field-' || tab.ad_tab_id::text), 9, 4) || '-4234-f567-890123456789'
  )
FROM ad_column c
CROSS JOIN ad_table tb
JOIN ad_tab tab ON tab.ad_table_id = tb.ad_table_id
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
WHERE c.columnname = 'AbERP_AcceptShiftRequest'
  AND c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'AbERP_RosteredResponseLog'
  AND w.name = 'Shift (Rostered)' AND tab.name = 'Response Log' AND tab.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_field f
    WHERE f.ad_tab_id = tab.ad_tab_id AND f.name = 'Accept Shift Request'
      AND f.ad_column_id = c.ad_column_id
  );

-- ---------------------------------------------------------------------------
-- 6. Process access (roles resolved by name + System Administrator)
-- ---------------------------------------------------------------------------
INSERT INTO ad_process_access (
  ad_process_id, ad_role_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby, isreadwrite, ad_process_access_uu
)
SELECT p.ad_process_id, roles.ad_role_id, roles.ad_client_id, 0, 'Y',
  NOW(), 100, NOW(), 100, 'Y', NULL
FROM ad_process p
CROSS JOIN (
  SELECT ad_role_id, ad_client_id FROM ad_role
  WHERE name IN (
      'AbilityERP Admin',
      'Admin',
      'Rostering Officer',
      'Rostering',
      'Rostering TL'
    ) AND isactive = 'Y'
  UNION ALL
  SELECT 0, 0
) AS roles(ad_role_id, ad_client_id)
WHERE p.value = 'SHIFT_ACCEPT_REQUEST'
  AND NOT EXISTS (
    SELECT 1 FROM ad_process_access x
    WHERE x.ad_process_id = p.ad_process_id
      AND x.ad_role_id = roles.ad_role_id
      AND x.ad_client_id = roles.ad_client_id
  );

-- ---------------------------------------------------------------------------
-- 7. Legacy toolbar button (inactive — field button is used)
-- ---------------------------------------------------------------------------
INSERT INTO ad_toolbarbutton (
  ad_toolbarbutton_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, componentname, action, ad_tab_id, ad_process_id,
  seqno, isadvancedbutton, isaddseparator, entitytype, iscustomization,
  displaylogic, ad_toolbarbutton_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_toolbarbutton_id), 0) + 1 FROM ad_toolbarbutton),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Accept Shift Request', 'Accept Shift Request', 'P', tab.ad_tab_id, p.ad_process_id,
  10, 'N', 'N', 'Ab_ERP', 'N',
  NULL,
  (
    substring(md5('AcceptShiftRequest-toolbar-' || tab.ad_tab_id::text), 1, 8) || '-' ||
    substring(md5('AcceptShiftRequest-toolbar-' || tab.ad_tab_id::text), 9, 4) || '-4789-c012-3456789abcde'
  )
FROM ad_process p
CROSS JOIN ad_table tb
JOIN ad_tab tab ON tab.ad_table_id = tb.ad_table_id
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
WHERE p.value = 'SHIFT_ACCEPT_REQUEST'
  AND tb.tablename = 'AbERP_RosteredResponseLog'
  AND w.name = 'Shift (Rostered)' AND tab.name = 'Response Log' AND tab.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_toolbarbutton tb2
    WHERE tb2.ad_tab_id = tab.ad_tab_id AND tb2.name = 'Accept Shift Request'
  );

-- ---------------------------------------------------------------------------
-- 8. Refresh display logic and button config (safe to re-run)
-- ---------------------------------------------------------------------------
UPDATE ad_column c
SET columnsql = '(SELECT CASE WHEN EXISTS (SELECT 1 FROM AbERP_Rostered_ShiftStaff ss WHERE ss.AbERP_Rostered_Shift_ID = AbERP_RosteredResponseLog.AbERP_Rostered_Shift_ID AND ss.IsActive=''Y'' AND COALESCE(ss.AbERP_User_Contact_ID,0) > 0) THEN ''N'' ELSE ''Y'' END)',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'AbERP_RosteredResponseLog'
  AND c.columnname = 'AbERP_IsShiftEmployeeVacant';

UPDATE ad_column c
SET istoolbarbutton = 'Y',
    issyncdatabase = 'Y',
    fieldlength = 1,
    updated = NOW(),
    updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'AbERP_RosteredResponseLog'
  AND c.columnname = 'AbERP_AcceptShiftRequest';

UPDATE ad_field f
SET isactive = 'Y',
    isdisplayed = 'Y',
    isdisplayedgrid = 'N',
    isfieldonly = 'N',
    istoolbarbutton = 'Y',
    displaylogic = '@AbERP_RosteredResponse@=REQ & @IsReviewed@!Y & @IsSuperseded@!Y',
    seqno = 55,
    columnspan = 2,
    xposition = 1,
    updated = NOW(),
    updatedby = 100
FROM ad_tab tab
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id,
     ad_column c
WHERE f.ad_tab_id = tab.ad_tab_id
  AND f.ad_column_id = c.ad_column_id
  AND w.name = 'Shift (Rostered)' AND tab.name = 'Response Log'
  AND c.columnname = 'AbERP_AcceptShiftRequest';

UPDATE ad_field f
SET seqno = 65, updated = NOW(), updatedby = 100
FROM ad_tab tab
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id,
     ad_column c
JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
WHERE f.ad_tab_id = tab.ad_tab_id
  AND f.ad_column_id = c.ad_column_id
  AND w.name = 'Shift (Rostered)' AND tab.name = 'Response Log'
  AND c.columnname = 'IsReviewed'
  AND tb.tablename = 'AbERP_RosteredResponseLog';

UPDATE ad_toolbarbutton tb
SET isactive = 'Y',
    action = 'P',
    displaylogic = '@AbERP_RosteredResponse@=REQ & @IsReviewed@!Y & @IsSuperseded@!Y',
    updated = NOW(),
    updatedby = 100
FROM ad_tab tab
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
WHERE tb.ad_tab_id = tab.ad_tab_id
  AND w.name = 'Shift (Rostered)' AND tab.name = 'Response Log'
  AND tb.name = 'Accept Shift Request';

-- ---------------------------------------------------------------------------
-- 9. Verify
-- ---------------------------------------------------------------------------
SELECT 'Response Log tab' AS check_type, w.name AS window_name, t.ad_tab_id, t.name AS tab_name
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
WHERE w.name = 'Shift (Rostered)' AND t.name = 'Response Log'
  AND tb.tablename = 'AbERP_RosteredResponseLog';

SELECT 'Process' AS check_type, p.value, p.classname, p.isactive
FROM ad_process p WHERE p.value = 'SHIFT_ACCEPT_REQUEST';

SELECT 'Process access' AS check_type, r.name, pa.isreadwrite
FROM ad_process_access pa
JOIN ad_role r ON r.ad_role_id = pa.ad_role_id
JOIN ad_process p ON p.ad_process_id = pa.ad_process_id
WHERE p.value = 'SHIFT_ACCEPT_REQUEST' AND pa.isactive = 'Y'
ORDER BY r.name;

SELECT 'Button field' AS check_type, w.name AS window_name, t.ad_tab_id,
       f.name, f.isactive, f.isdisplayed, f.displaylogic
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE c.columnname = 'AbERP_AcceptShiftRequest';

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ad_process WHERE value = 'SHIFT_ACCEPT_REQUEST' AND isactive = 'Y') THEN
    RAISE EXCEPTION 'Install FAILED: process SHIFT_ACCEPT_REQUEST not created';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM ad_field f
    JOIN ad_column c ON c.ad_column_id = f.ad_column_id
    WHERE c.columnname = 'AbERP_AcceptShiftRequest'
  ) THEN
    RAISE EXCEPTION 'Install FAILED: Accept button field not created on Response Log tab';
  END IF;
  RAISE NOTICE 'Accept Shift Request install completed successfully';
END $$;
