-- Add link columns on C_ContactActivity for Booking Generator and Service Booking.
-- C_Project_ID already exists for Service Agreement (Project).
SET search_path TO adempiere;

ALTER TABLE c_contactactivity
  ADD COLUMN IF NOT EXISTS aberp_bookinggenerator_id numeric(10);

ALTER TABLE c_contactactivity
  ADD COLUMN IF NOT EXISTS c_order_id numeric(10);

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
  1030291, 0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Booking Generator', 'Ab_ERP', 'AbERP_BookingGenerator_ID', 53354,
  19, 22, 0,
  'N', 'N', 'N', 'N', 'N', 0,
  'N', 'N', 'N',
  1011414, 'Y', 'N',
  'Y', 'Y', 0, 'N', 'N',
  'AbERPBG_CContactActivity', 'N', 'N',
  'a1a2a3a4-b001-4001-8001-000000000001'
WHERE NOT EXISTS (
  SELECT 1 FROM ad_column WHERE columnname = 'AbERP_BookingGenerator_ID' AND ad_table_id = 53354
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
  1030292, 0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Order', 'Ab_ERP', 'C_Order_ID', 53354,
  19, 22, 0,
  'N', 'N', 'N', 'N', 'N', 0,
  'N', 'N', 'N',
  558, 'Y', 'N',
  'Y', 'Y', 0, 'N', 'N',
  'COrder_CContactActivity', 'N', 'N',
  'a1a2a3a4-b001-4001-8001-000000000002'
WHERE NOT EXISTS (
  SELECT 1 FROM ad_column WHERE columnname = 'C_Order_ID' AND ad_table_id = 53354
);
