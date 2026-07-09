-- Add Accept Shift Request button on Response Log tab (under IsSuperseded).
SET search_path TO adempiere;

ALTER TABLE aberp_rosteredresponselog
  ADD COLUMN IF NOT EXISTS aberp_acceptshiftrequest character(1);

-- AD_Element
INSERT INTO ad_element (
  ad_element_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  columnname, entitytype, name, printname,
  ad_element_uu
)
SELECT
  1012215, 0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'AbERP_AcceptShiftRequest', 'Ab_ERP', 'Accept Shift Request', 'Accept Shift Request',
  'd4e5f6a7-b8c9-4012-d345-678901234567'
WHERE NOT EXISTS (
  SELECT 1 FROM ad_element WHERE columnname = 'AbERP_AcceptShiftRequest'
);

-- AD_Column (Button → SHIFT_ACCEPT_REQUEST process)
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
  1030289, 0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Accept Shift Request', 'Ab_ERP', 'AbERP_AcceptShiftRequest', 1000607,
  28, 1, 0,
  'N', 'N', 'N', 'Y', 'N', 0,
  'N', 'N', 'N',
  e.ad_element_id, p.ad_process_id, 'Y', 'N',
  'N', 'Y', 'Y', 0,
  'B', 'N', 'N', 'N', 'N',
  'e5f6a7b8-c9d0-4123-e456-789012345678'
FROM ad_element e
JOIN ad_process p ON p.value = 'SHIFT_ACCEPT_REQUEST'
WHERE e.columnname = 'AbERP_AcceptShiftRequest'
  AND NOT EXISTS (
    SELECT 1 FROM ad_column WHERE columnname = 'AbERP_AcceptShiftRequest'
  );

-- AD_Field on Response Log tab, directly under IsSuperseded (seqno 61)
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
  1010802, 0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Accept Shift Request', 'N', 1000366, c.ad_column_id,
  'Y', NULL, 1, 'N', 61,
  'N', 'N', 'N', 'N', 'Ab_ERP',
  'Y', 5, 1, 2,
  'N', 'N', 'N', 'N',
  'N', 'N', 'N',
  'f6a7b8c9-d0e1-4234-f567-890123456789'
FROM ad_column c
WHERE c.columnname = 'AbERP_AcceptShiftRequest'
  AND NOT EXISTS (
    SELECT 1 FROM ad_field f
    WHERE f.ad_tab_id = 1000366 AND f.name = 'Accept Shift Request'
      AND f.ad_column_id = c.ad_column_id
  );

-- Ensure Reviewed stays below the button
UPDATE ad_field SET seqno = 65, updated = NOW(), updatedby = 100
WHERE ad_tab_id = 1000366 AND ad_column_id = (
  SELECT ad_column_id FROM ad_column WHERE columnname = 'IsReviewed' AND ad_table_id = 1000607
);
