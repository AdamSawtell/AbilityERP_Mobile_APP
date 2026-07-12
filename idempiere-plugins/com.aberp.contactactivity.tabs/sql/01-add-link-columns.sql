-- SAW007 portable link columns for C_ContactActivity (HCO / multi-client).
-- Replaces seed-ID sql/01-add-link-columns.sql for other builds.
-- Never overwrites existing *_UU; never hardcodes AD_Column_ID / AD_Table_ID.
SET search_path TO adempiere;

ALTER TABLE c_contactactivity
  ADD COLUMN IF NOT EXISTS aberp_bookinggenerator_id numeric(10);

ALTER TABLE c_contactactivity
  ADD COLUMN IF NOT EXISTS c_order_id numeric(10);

INSERT INTO ad_element (
  ad_element_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  columnname, entitytype, name, printname, ad_element_uu
)
SELECT
  nextid((SELECT ad_sequence_id::integer FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y' LIMIT 1), 'N'::varchar),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'AbERP_BookingGenerator_ID', 'Ab_ERP', 'Booking Generator', 'Booking Generator',
  'd1e2f3a4-b001-4001-8001-000000000001'
WHERE NOT EXISTS (
  SELECT 1 FROM ad_element WHERE columnname = 'AbERP_BookingGenerator_ID'
);

INSERT INTO ad_column (
  ad_column_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, entitytype, columnname, ad_table_id,
  ad_reference_id, fieldlength, version,
  iskey, isparent, ismandatory, isupdateable, isidentifier, seqno,
  istranslated, isencrypted, isselectioncolumn,
  ad_element_id, issyncdatabase, isalwaysupdateable,
  isallowlogging, isallowcopy, seqnoselection, istoolbarbutton, issecure,
  fkconstraintname, fkconstrainttype, isdisablezoomacross,
  ad_column_uu
)
SELECT
  nextid((SELECT ad_sequence_id::integer FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y' LIMIT 1), 'N'::varchar),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Booking Generator', 'Ab_ERP', 'AbERP_BookingGenerator_ID', tb.ad_table_id,
  COALESCE((SELECT ad_reference_id FROM ad_reference WHERE name = 'Table Direct' LIMIT 1), 19),
  22, 0,
  'N', 'N', 'N', 'N', 'N', 0,
  'N', 'N', 'N',
  e.ad_element_id, 'Y', 'N',
  'Y', 'Y', 0, 'N', 'N',
  'AbERPBG_CContactActivity', 'N', 'N',
  'a1a2a3a4-b001-4001-8001-000000000001'
FROM ad_element e
CROSS JOIN ad_table tb
WHERE e.columnname = 'AbERP_BookingGenerator_ID'
  AND tb.tablename = 'C_ContactActivity' AND tb.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_column c
    WHERE c.columnname = 'AbERP_BookingGenerator_ID' AND c.ad_table_id = tb.ad_table_id
  );

INSERT INTO ad_column (
  ad_column_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, entitytype, columnname, ad_table_id,
  ad_reference_id, fieldlength, version,
  iskey, isparent, ismandatory, isupdateable, isidentifier, seqno,
  istranslated, isencrypted, isselectioncolumn,
  ad_element_id, issyncdatabase, isalwaysupdateable,
  isallowlogging, isallowcopy, seqnoselection, istoolbarbutton, issecure,
  fkconstraintname, fkconstrainttype, isdisablezoomacross,
  ad_column_uu
)
SELECT
  nextid((SELECT ad_sequence_id::integer FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y' LIMIT 1), 'N'::varchar),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Order', 'Ab_ERP', 'C_Order_ID', tb.ad_table_id,
  COALESCE((SELECT ad_reference_id FROM ad_reference WHERE name = 'Table Direct' LIMIT 1), 19),
  22, 0,
  'N', 'N', 'N', 'N', 'N', 0,
  'N', 'N', 'N',
  e.ad_element_id, 'Y', 'N',
  'Y', 'Y', 0, 'N', 'N',
  'COrder_CContactActivity', 'N', 'N',
  'a1a2a3a4-b001-4001-8001-000000000002'
FROM ad_element e
CROSS JOIN ad_table tb
WHERE e.columnname = 'C_Order_ID'
  AND tb.tablename = 'C_ContactActivity' AND tb.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_column c
    WHERE c.columnname = 'C_Order_ID' AND c.ad_table_id = tb.ad_table_id
  );
