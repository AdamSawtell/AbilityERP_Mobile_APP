-- Accept button visibility: REQ only, not reviewed/superseded, shift has no assigned employee.
SET search_path TO adempiere;

-- Virtual flag: Y when no active shift-staff line has an employee assigned
INSERT INTO ad_element (
  ad_element_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  columnname, entitytype, name, printname, ad_element_uu
)
SELECT 1012216, 0, 0, 'Y', NOW(), 100, NOW(), 100,
  'AbERP_IsShiftEmployeeVacant', 'Ab_ERP', 'Shift Employee Vacant', 'Shift Employee Vacant',
  'a7b8c9d0-e1f2-4345-a678-901234567890'
WHERE NOT EXISTS (
  SELECT 1 FROM ad_element WHERE columnname = 'AbERP_IsShiftEmployeeVacant'
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
  1030290, 0, 0, 'Y', NOW(), 100, NOW(), 100,
  'Shift Employee Vacant', 'Ab_ERP', 'AbERP_IsShiftEmployeeVacant', 1000607,
  20, 1, 0,
  'N', 'N', 'N', 'N', 'N', 0,
  'N', 'N', 'N',
  e.ad_element_id, 'N', 'N',
  'N', 'N', 'N',
  'N', 'N', 'N', 'N',
  '(SELECT CASE WHEN EXISTS (SELECT 1 FROM AbERP_Rostered_ShiftStaff ss WHERE ss.AbERP_Rostered_Shift_ID = AbERP_RosteredResponseLog.AbERP_Rostered_Shift_ID AND ss.IsActive=''Y'' AND COALESCE(ss.AbERP_User_Contact_ID,0) > 0) THEN ''N'' ELSE ''Y'' END)',
  'b8c9d0e1-f2a3-4456-b789-012345678901'
FROM ad_element e
WHERE e.columnname = 'AbERP_IsShiftEmployeeVacant'
  AND NOT EXISTS (
    SELECT 1 FROM ad_column WHERE columnname = 'AbERP_IsShiftEmployeeVacant'
  );

-- Hidden context field (not shown; drives Accept button display logic)
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
  1010803, 0, 0, 'Y', NOW(), 100, NOW(), 100,
  'Shift Employee Vacant', 'N', 1000366, c.ad_column_id,
  'N', 1, 'Y', 62,
  'N', 'N', 'N', 'N', 'Ab_ERP',
  'N', 1, 1, 1,
  'N', 'N', 'c9d0e1f2-a3b4-4567-c890-123456789012'
FROM ad_column c
WHERE c.columnname = 'AbERP_IsShiftEmployeeVacant'
  AND NOT EXISTS (
    SELECT 1 FROM ad_field f
    WHERE f.ad_tab_id = 1000366 AND f.ad_column_id = c.ad_column_id
  );

UPDATE ad_field
SET displaylogic = '@AbERP_RosteredResponse@=''REQ'' & @IsReviewed@=''N'' & @IsSuperseded@=''N'' & @AbERP_IsShiftEmployeeVacant@=''Y''',
    updated = NOW(),
    updatedby = 100
WHERE ad_tab_id = 1000366
  AND ad_column_id = (SELECT ad_column_id FROM ad_column WHERE columnname = 'AbERP_AcceptShiftRequest');

UPDATE ad_column
SET columnsql = '(SELECT CASE WHEN EXISTS (SELECT 1 FROM AbERP_Rostered_ShiftStaff ss WHERE ss.AbERP_Rostered_Shift_ID = AbERP_RosteredResponseLog.AbERP_Rostered_Shift_ID AND ss.IsActive=''Y'' AND COALESCE(ss.AbERP_User_Contact_ID,0) > 0) THEN ''N'' ELSE ''Y'' END)',
    updated = NOW(),
    updatedby = 100
WHERE columnname = 'AbERP_IsShiftEmployeeVacant';
