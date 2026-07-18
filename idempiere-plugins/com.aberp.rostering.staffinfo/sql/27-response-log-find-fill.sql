-- =============================================================================
-- SAW011 — Response Log Find and Fill button (portable, no hardcoded AD IDs)
-- Opens Staff Rostering Info (Find & Fill) with worker prefilled; OK fills vacant
-- Employee slot and marks the response reviewed.
-- =============================================================================

SET search_path TO adempiere;

ALTER TABLE aberp_rosteredresponselog
  ADD COLUMN IF NOT EXISTS aberp_findfillstaff character(1);

-- Process
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
  'AbERP_ResponseLog_FindFill', 'Find and Fill',
  'Open Find and Fill for the response worker against this shift; OK fills a vacant Employee slot.',
  '3', 'Ab_ERP',
  'N', 'N',
  'com.aberp.rostering.staffinfo.process.ResponseLogFindFill',
  'N', 'N', 'S',
  'N',
  'a030f001-4789-4c01-b030-a012f0000001',
  'P', 'N'
WHERE NOT EXISTS (
  SELECT 1 FROM ad_process WHERE value = 'AbERP_ResponseLog_FindFill'
);

UPDATE ad_process
SET classname = 'com.aberp.rostering.staffinfo.process.ResponseLogFindFill',
    name = 'Find and Fill',
    isactive = 'Y',
    updated = NOW(),
    updatedby = 100
WHERE value = 'AbERP_ResponseLog_FindFill';

-- Element
INSERT INTO ad_element (
  ad_element_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  columnname, entitytype, name, printname, ad_element_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_element_id), 0) + 1 FROM ad_element),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'AbERP_FindFillStaff', 'Ab_ERP', 'Find and Fill', 'Find and Fill',
  'a030f002-4030-4c01-c012-a012f0000002'
WHERE NOT EXISTS (
  SELECT 1 FROM ad_element WHERE columnname = 'AbERP_FindFillStaff'
);

-- Column (Window button)
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
  'Find and Fill', 'Ab_ERP', 'AbERP_FindFillStaff', tb.ad_table_id,
  COALESCE(
    (SELECT ad_reference_id FROM ad_reference WHERE name = 'Button' AND isactive = 'Y' LIMIT 1),
    28
  ),
  1, 0,
  'N', 'N', 'N', 'Y', 'N', 0,
  'N', 'N', 'N',
  e.ad_element_id, p.ad_process_id, 'Y', 'Y',
  'N', 'Y', 'Y', 0,
  'B', 'N', 'N', 'N', 'N',
  'a030f003-4130-4c01-d030-a012f0000003'
FROM ad_element e
JOIN ad_process p ON p.value = 'AbERP_ResponseLog_FindFill'
CROSS JOIN ad_table tb
WHERE e.columnname = 'AbERP_FindFillStaff'
  AND tb.tablename = 'AbERP_RosteredResponseLog' AND tb.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_column c
    WHERE c.columnname = 'AbERP_FindFillStaff' AND c.ad_table_id = tb.ad_table_id
  );

UPDATE ad_column c
SET ad_process_id = p.ad_process_id,
    istoolbarbutton = 'B',
    isalwaysupdateable = 'Y',
    isupdateable = 'Y',
    isactive = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb, ad_process p
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'AbERP_RosteredResponseLog'
  AND c.columnname = 'AbERP_FindFillStaff'
  AND p.value = 'AbERP_ResponseLog_FindFill';

-- Field next to Reviewed
INSERT INTO ad_field (
  ad_field_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, iscentrallymaintained, ad_tab_id, ad_column_id,
  isdisplayed, displaylogic, displaylength, isreadonly, seqno,
  issameline, isheading, isfieldonly, isencrypted, entitytype,
  isdisplayedgrid, xposition, numlines, columnspan,
  isquickentry, istoolbarbutton, isadvancedfield, isdefaultfocus,
  ad_field_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_field_id), 0) + 1 FROM ad_field),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'Find and Fill', 'Y', tab.ad_tab_id, c.ad_column_id,
  'Y',
  NULL,
  14, 'N', 68,
  'N', 'N', 'N', 'N', 'Ab_ERP',
  'Y', 5, 1, 2,
  'N', NULL, 'N', 'N',
  'a030f004-4230-4c01-e030-a012f0000004'
FROM ad_column c
CROSS JOIN ad_table tb
JOIN ad_tab tab ON tab.ad_table_id = tb.ad_table_id
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
WHERE c.columnname = 'AbERP_FindFillStaff'
  AND c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'AbERP_RosteredResponseLog'
  AND w.name = 'Shift (Rostered)' AND tab.name = 'Response Log' AND tab.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_field f
    WHERE f.ad_tab_id = tab.ad_tab_id AND f.ad_column_id = c.ad_column_id
  );

UPDATE ad_field f
SET isactive = 'Y',
    isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    istoolbarbutton = NULL,
    displaylogic = NULL,
    seqno = 68,
    seqnogrid = 40,
    xposition = 5,
    columnspan = 2,
    iscentrallymaintained = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_tab tab
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id,
     ad_column c
WHERE f.ad_tab_id = tab.ad_tab_id
  AND f.ad_column_id = c.ad_column_id
  AND w.name = 'Shift (Rostered)' AND tab.name = 'Response Log'
  AND c.columnname = 'AbERP_FindFillStaff';

-- Process access
INSERT INTO ad_process_access (
  ad_process_id, ad_role_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby, isreadwrite, ad_process_access_uu
)
SELECT p.ad_process_id, r.ad_role_id, r.ad_client_id, 0, 'Y',
  NOW(), 100, NOW(), 100, 'Y', NULL
FROM ad_process p
CROSS JOIN ad_role r
WHERE p.value = 'AbERP_ResponseLog_FindFill'
  AND r.name IN ('Admin', 'AbilityERP Admin', 'Rostering', 'Rostering TL', 'Rostering Officer',
                 'System Administrator')
  AND r.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_process_access x
    WHERE x.ad_process_id = p.ad_process_id AND x.ad_role_id = r.ad_role_id
  );

UPDATE ad_process_access pa
SET isactive = 'Y', isreadwrite = 'Y', updated = NOW(), updatedby = 100
FROM ad_process p, ad_role r
WHERE pa.ad_process_id = p.ad_process_id AND pa.ad_role_id = r.ad_role_id
  AND p.value = 'AbERP_ResponseLog_FindFill'
  AND r.name IN ('Admin', 'AbilityERP Admin', 'Rostering', 'Rostering TL', 'Rostering Officer',
                 'System Administrator');

SELECT 'Process' AS kind, p.value, p.classname, p.isactive
FROM ad_process p WHERE p.value = 'AbERP_ResponseLog_FindFill';

SELECT 'Field' AS kind, f.name, f.isdisplayed, f.displaylogic, f.seqno, f.xposition
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE c.columnname = 'AbERP_FindFillStaff';
