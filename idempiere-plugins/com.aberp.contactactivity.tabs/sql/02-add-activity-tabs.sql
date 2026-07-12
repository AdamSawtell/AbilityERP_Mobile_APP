-- Add Activity tabs to Booking Generator, Service Booking, and Service Agreement (Project).
-- Clones Enquiry Activity tab (1000138) field layout.
SET search_path TO adempiere;

-- Booking Generator (1000193) — link AbERP_BookingGenerator_ID
INSERT INTO ad_tab (
  ad_tab_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, ad_table_id, ad_window_id, seqno, tablevel,
  issinglerow, isinfotab, istranslationtab, isreadonly,
  ad_column_id, hastree, processing, importfields,
  issorttab, entitytype, isinsertrecord, isadvancedtab,
  treedisplayedon, islookuponlyselection, isallowadvancedlookup,
  ad_tab_uu
)
SELECT
  1000424, 0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Activity', 53354, 1000193, 25, 1,
  'Y', 'N', 'N', 'N',
  1030291, 'N', 'N', 'N',
  'N', 'Ab_ERP', 'Y', 'N',
  'B', 'N', 'Y',
  'b1b2b3b4-c001-4001-8001-000000000001'
WHERE NOT EXISTS (
  SELECT 1 FROM ad_tab WHERE ad_window_id = 1000193 AND name = 'Activity' AND ad_table_id = 53354
);

-- Service Booking (1000077) — link C_Order_ID
INSERT INTO ad_tab (
  ad_tab_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, ad_table_id, ad_window_id, seqno, tablevel,
  issinglerow, isinfotab, istranslationtab, isreadonly,
  ad_column_id, hastree, processing, importfields,
  issorttab, entitytype, isinsertrecord, isadvancedtab,
  treedisplayedon, islookuponlyselection, isallowadvancedlookup,
  ad_tab_uu
)
SELECT
  1000425, 0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Activity', 53354, 1000077, 25, 1,
  'Y', 'N', 'N', 'N',
  1030292, 'N', 'N', 'N',
  'N', 'Ab_ERP', 'Y', 'N',
  'B', 'N', 'Y',
  'b1b2b3b4-c001-4001-8001-000000000002'
WHERE NOT EXISTS (
  SELECT 1 FROM ad_tab WHERE ad_window_id = 1000077 AND name = 'Activity' AND ad_table_id = 53354
);

-- Service Agreement (1000118) — link C_Project_ID (tab may already exist from partial deploy)
INSERT INTO ad_tab (
  ad_tab_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, ad_table_id, ad_window_id, seqno, tablevel,
  issinglerow, isinfotab, istranslationtab, isreadonly,
  ad_column_id, hastree, processing, importfields,
  issorttab, entitytype, isinsertrecord, isadvancedtab,
  treedisplayedon, islookuponlyselection, isallowadvancedlookup,
  ad_tab_uu
)
SELECT
  1000426, 0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Activity', 53354, 1000118, 45, 1,
  'Y', 'N', 'N', 'N',
  212251, 'N', 'N', 'N',
  'N', 'Ab_ERP', 'Y', 'N',
  'B', 'N', 'Y',
  'b1b2b3b4-c001-4001-8001-000000000003'
WHERE NOT EXISTS (
  SELECT 1 FROM ad_tab WHERE ad_window_id = 1000118 AND name = 'Activity' AND ad_table_id = 53354
);

-- Clone fields from Enquiry Activity tab for each new tab
DO $$
DECLARE
  cfg RECORD;
  src RECORD;
  new_field_id INTEGER;
  link_col INTEGER;
  field_offset INTEGER := 0;
BEGIN
  FOR cfg IN
    SELECT * FROM (VALUES
      (1000424, 1030291),
      (1000425, 1030292),
      (1000426, 212251)
    ) AS t(ad_tab_id, link_column_id)
  LOOP
    IF NOT EXISTS (SELECT 1 FROM ad_field WHERE ad_tab_id = cfg.ad_tab_id LIMIT 1) THEN
      SELECT COALESCE(MAX(ad_field_id), 0) + 1 INTO new_field_id FROM ad_field;
      FOR src IN
        SELECT f.*, col.columnname
        FROM ad_field f
        JOIN ad_column col ON col.ad_column_id = f.ad_column_id
        WHERE f.ad_tab_id = 1000138 AND f.isactive = 'Y'
        ORDER BY f.seqno, f.ad_field_id
      LOOP
        link_col := src.ad_column_id;
        IF src.columnname = 'AbERP_Enquiry_ID' THEN
          link_col := cfg.link_column_id;
        END IF;

        INSERT INTO ad_field (
          ad_field_id, ad_client_id, ad_org_id, isactive,
          created, createdby, updated, updatedby,
          name, description, help, iscentrallymaintained,
          ad_tab_id, ad_column_id, ad_fieldgroup_id,
          isdisplayed, displaylogic, displaylength, isreadonly, seqno, sortno,
          issameline, isheading, isfieldonly, isencrypted, entitytype,
          ad_reference_id, ismandatory, included_tab_id, defaultvalue,
          ad_reference_value_id, ad_val_rule_id, infofactoryclass,
          isallowcopy, seqnogrid, isdisplayedgrid, xposition, numlines, columnspan,
          isquickentry, isupdateable, isalwaysupdateable, mandatorylogic, readonlylogic,
          istoolbarbutton, isadvancedfield, isdefaultfocus, vformat,
          placeholder, isquickform, isselectioncolumn, isdisablezoomacross,
          ad_field_uu
        ) VALUES (
          new_field_id, src.ad_client_id, src.ad_org_id, src.isactive,
          NOW(), 100, NOW(), 100,
          CASE WHEN src.columnname = 'AbERP_Enquiry_ID' THEN
            (SELECT name FROM ad_column WHERE ad_column_id = cfg.link_column_id)
          ELSE src.name END,
          src.description, src.help, src.iscentrallymaintained,
          cfg.ad_tab_id, link_col, src.ad_fieldgroup_id,
          src.isdisplayed, src.displaylogic, src.displaylength, src.isreadonly, src.seqno, src.sortno,
          src.issameline, src.isheading, src.isfieldonly, src.isencrypted, 'Ab_ERP',
          src.ad_reference_id, src.ismandatory, src.included_tab_id, src.defaultvalue,
          src.ad_reference_value_id, src.ad_val_rule_id, src.infofactoryclass,
          src.isallowcopy, src.seqnogrid, src.isdisplayedgrid, src.xposition, src.numlines, src.columnspan,
          src.isquickentry, src.isupdateable, src.isalwaysupdateable, src.mandatorylogic, src.readonlylogic,
          src.istoolbarbutton, src.isadvancedfield, src.isdefaultfocus, src.vformat,
          src.placeholder, src.isquickform, src.isselectioncolumn, src.isdisablezoomacross,
          (
            substring(md5('aberp-ca-' || new_field_id::text || '-' || cfg.ad_tab_id::text || '-' || link_col::text), 1, 8) || '-' ||
            substring(md5('aberp-ca-' || new_field_id::text || '-' || cfg.ad_tab_id::text || '-' || link_col::text), 9, 4) || '-4001-8001-' ||
            substring(md5('aberp-ca-' || new_field_id::text || '-' || cfg.ad_tab_id::text || '-' || link_col::text), 13, 12)
          )
        );
        new_field_id := new_field_id + 1;
      END LOOP;
    END IF;
  END LOOP;
END $$;
