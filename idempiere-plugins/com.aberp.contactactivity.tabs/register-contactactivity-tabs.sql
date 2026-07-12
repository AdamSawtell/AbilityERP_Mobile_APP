-- =============================================================================
-- com.aberp.contactactivity.tabs — portable single deploy script
-- Adds Activity tab to: Booking Generator, Service Booking, Service Agreement (Project)
--
-- NO hardcoded AD IDs — resolves table/window/element/column/reference by name.
-- Safe to run on any AbilityERP / iDempiere build (idempotent).
--
-- Run:
--   psql -d idempiere -f register-contactactivity-tabs.sql
--
-- Prerequisites:
--   - JAR com.aberp.contactactivity.tabs installed (restart iDempiere first)
--   - Enquiry window has an Activity tab on C_ContactActivity (clone template)
--   - Standard elements C_Order_ID, C_Project_ID exist
--
-- After run: log out and log back in on WebUI.
-- =============================================================================

SET search_path TO adempiere;

-- ---------------------------------------------------------------------------
-- 0. Resolve IDs by name (read-only checks)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_table_id INTEGER;
  v_type_ref_id INTEGER;
  v_enquiry_tab INTEGER;
BEGIN
  SELECT ad_table_id INTO v_table_id
  FROM ad_table WHERE tablename = 'C_ContactActivity' AND isactive = 'Y' LIMIT 1;
  IF v_table_id IS NULL THEN
    RAISE EXCEPTION 'C_ContactActivity table not found';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_element WHERE columnname = 'C_Order_ID') THEN
    RAISE EXCEPTION 'AD_Element C_Order_ID not found — standard iDempiere element missing';
  END IF;

  SELECT c.ad_reference_value_id INTO v_type_ref_id
  FROM ad_column c
  WHERE c.ad_table_id = v_table_id AND c.columnname = 'ContactActivityType' LIMIT 1;
  IF v_type_ref_id IS NULL THEN
    RAISE EXCEPTION 'ContactActivityType column / list reference not found on C_ContactActivity';
  END IF;

  SELECT t.ad_tab_id INTO v_enquiry_tab
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
  WHERE w.name = 'Enquiry' AND t.name = 'Activity'
    AND tb.tablename = 'C_ContactActivity' AND t.isactive = 'Y'
  LIMIT 1;
  IF v_enquiry_tab IS NULL THEN
    RAISE EXCEPTION 'Enquiry Activity tab not found — cannot clone fields';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM ad_window WHERE name = 'Booking Generator' AND isactive = 'Y'
  ) THEN
    RAISE WARNING 'Window Booking Generator not found — tab will be skipped';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM ad_window WHERE name = 'Service Booking' AND isactive = 'Y'
  ) THEN
    RAISE WARNING 'Window Service Booking not found — tab will be skipped';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM ad_window WHERE name = 'Service Agreement (Project)' AND isactive = 'Y'
  ) THEN
    RAISE WARNING 'Window Service Agreement (Project) not found — tab will be skipped';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Physical + AD link columns on C_ContactActivity
-- ---------------------------------------------------------------------------
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
  (SELECT COALESCE(MAX(ad_element_id), 0) + 1 FROM ad_element),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'AbERP_BookingGenerator_ID', 'Ab_ERP', 'Booking Generator', 'Booking Generator',
  (
    substring(md5('AbERP_BookingGenerator_ID-element'), 1, 8) || '-' ||
    substring(md5('AbERP_BookingGenerator_ID-element'), 9, 4) || '-4001-8001-' ||
    substring(md5('AbERP_BookingGenerator_ID-element'), 13, 12)
  )
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
  (SELECT COALESCE(MAX(ad_column_id), 0) + 1 FROM ad_column),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Booking Generator', 'Ab_ERP', 'AbERP_BookingGenerator_ID', tb.ad_table_id,
  (SELECT ad_reference_id FROM ad_reference WHERE name = 'Table Direct' LIMIT 1),
  22, 0,
  'N', 'N', 'N', 'N', 'N', 0,
  'N', 'N', 'N',
  e.ad_element_id, 'Y', 'N',
  'Y', 'Y', 0, 'N', 'N',
  'AbERPBG_CContactActivity', 'N', 'N',
  (
    substring(md5('AbERP_BookingGenerator_ID-col-' || tb.ad_table_id::text), 1, 8) || '-' ||
    substring(md5('AbERP_BookingGenerator_ID-col-' || tb.ad_table_id::text), 9, 4) || '-4001-8001-' ||
    substring(md5('AbERP_BookingGenerator_ID-col-' || tb.ad_table_id::text), 13, 12)
  )
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
  (SELECT COALESCE(MAX(ad_column_id), 0) + 1 FROM ad_column),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Order', 'Ab_ERP', 'C_Order_ID', tb.ad_table_id,
  (SELECT ad_reference_id FROM ad_reference WHERE name = 'Table Direct' LIMIT 1),
  22, 0,
  'N', 'N', 'N', 'N', 'N', 0,
  'N', 'N', 'N',
  e.ad_element_id, 'Y', 'N',
  'Y', 'Y', 0, 'N', 'N',
  'COrder_CContactActivity', 'N', 'N',
  (
    substring(md5('C_Order_ID-col-' || tb.ad_table_id::text), 1, 8) || '-' ||
    substring(md5('C_Order_ID-col-' || tb.ad_table_id::text), 9, 4) || '-4001-8001-' ||
    substring(md5('C_Order_ID-col-' || tb.ad_table_id::text), 13, 12)
  )
FROM ad_element e
CROSS JOIN ad_table tb
WHERE e.columnname = 'C_Order_ID'
  AND tb.tablename = 'C_ContactActivity' AND tb.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_column c
    WHERE c.columnname = 'C_Order_ID' AND c.ad_table_id = tb.ad_table_id
  );

-- ---------------------------------------------------------------------------
-- 2. Activity tabs (windows + link columns resolved by name)
-- ---------------------------------------------------------------------------
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
  (SELECT COALESCE(MAX(ad_tab_id), 0) + 1 FROM ad_tab),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Activity', tb.ad_table_id, w.ad_window_id, 25, 1,
  'Y', 'N', 'N', 'N',
  c.ad_column_id, 'N', 'N', 'N',
  'N', 'Ab_ERP', 'Y', 'N',
  'B', 'N', 'Y',
  (
    substring(md5('activity-tab-' || w.name), 1, 8) || '-' ||
    substring(md5('activity-tab-' || w.name), 9, 4) || '-4001-8001-' ||
    substring(md5('activity-tab-' || w.name), 13, 12)
  )
FROM ad_window w
CROSS JOIN ad_table tb
JOIN ad_column c ON c.columnname = 'AbERP_BookingGenerator_ID' AND c.ad_table_id = tb.ad_table_id
WHERE w.name = 'Booking Generator' AND w.isactive = 'Y'
  AND tb.tablename = 'C_ContactActivity' AND tb.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_tab t
    WHERE t.ad_window_id = w.ad_window_id AND t.name = 'Activity' AND t.ad_table_id = tb.ad_table_id
  );

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
  (SELECT COALESCE(MAX(ad_tab_id), 0) + 1 FROM ad_tab),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Activity', tb.ad_table_id, w.ad_window_id, 25, 1,
  'Y', 'N', 'N', 'N',
  c.ad_column_id, 'N', 'N', 'N',
  'N', 'Ab_ERP', 'Y', 'N',
  'B', 'N', 'Y',
  (
    substring(md5('activity-tab-' || w.name), 1, 8) || '-' ||
    substring(md5('activity-tab-' || w.name), 9, 4) || '-4001-8001-' ||
    substring(md5('activity-tab-' || w.name), 13, 12)
  )
FROM ad_window w
CROSS JOIN ad_table tb
JOIN ad_column c ON c.columnname = 'C_Order_ID' AND c.ad_table_id = tb.ad_table_id
WHERE w.name = 'Service Booking' AND w.isactive = 'Y'
  AND tb.tablename = 'C_ContactActivity' AND tb.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_tab t
    WHERE t.ad_window_id = w.ad_window_id AND t.name = 'Activity' AND t.ad_table_id = tb.ad_table_id
  );

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
  (SELECT COALESCE(MAX(ad_tab_id), 0) + 1 FROM ad_tab),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Activity', tb.ad_table_id, w.ad_window_id, 45, 1,
  'Y', 'N', 'N', 'N',
  c.ad_column_id, 'N', 'N', 'N',
  'N', 'Ab_ERP', 'Y', 'N',
  'B', 'N', 'Y',
  (
    substring(md5('activity-tab-' || w.name), 1, 8) || '-' ||
    substring(md5('activity-tab-' || w.name), 9, 4) || '-4001-8001-' ||
    substring(md5('activity-tab-' || w.name), 13, 12)
  )
FROM ad_window w
CROSS JOIN ad_table tb
JOIN ad_column c ON c.columnname = 'C_Project_ID' AND c.ad_table_id = tb.ad_table_id
WHERE w.name = 'Service Agreement (Project)' AND w.isactive = 'Y'
  AND tb.tablename = 'C_ContactActivity' AND tb.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_tab t
    WHERE t.ad_window_id = w.ad_window_id AND t.name = 'Activity' AND t.ad_table_id = tb.ad_table_id
  );

-- ---------------------------------------------------------------------------
-- 3. Clone fields from Enquiry Activity tab
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  template_tab_id INTEGER;
  cfg RECORD;
  src RECORD;
  new_field_id INTEGER;
  link_col INTEGER;
BEGIN
  SELECT t.ad_tab_id INTO template_tab_id
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
  WHERE w.name = 'Enquiry' AND t.name = 'Activity' AND tb.tablename = 'C_ContactActivity'
    AND t.isactive = 'Y'
  LIMIT 1;

  IF template_tab_id IS NULL THEN
    RAISE EXCEPTION 'Enquiry Activity tab not found — cannot clone fields';
  END IF;

  FOR cfg IN
    SELECT t.ad_tab_id, t.ad_column_id AS link_column_id, w.name AS window_name
    FROM ad_tab t
    JOIN ad_window w ON w.ad_window_id = t.ad_window_id
    JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
    WHERE t.name = 'Activity' AND tb.tablename = 'C_ContactActivity'
      AND w.name IN ('Booking Generator', 'Service Booking', 'Service Agreement (Project)')
      AND t.isactive = 'Y'
  LOOP
    FOR src IN
      SELECT f.*, col.columnname
      FROM ad_field f
      JOIN ad_column col ON col.ad_column_id = f.ad_column_id
      WHERE f.ad_tab_id = template_tab_id AND f.isactive = 'Y'
      ORDER BY f.seqno, f.ad_field_id
    LOOP
      link_col := src.ad_column_id;
      IF src.columnname = 'AbERP_Enquiry_ID' THEN
        link_col := cfg.link_column_id;
      END IF;

      IF NOT EXISTS (
        SELECT 1 FROM ad_field f
        WHERE f.ad_tab_id = cfg.ad_tab_id AND f.ad_column_id = link_col
      ) THEN
        SELECT COALESCE(MAX(ad_field_id), 0) + 1 INTO new_field_id FROM ad_field;

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
      END IF;
    END LOOP;
  END LOOP;

  -- MAX+1 bypasses AD_Field sequence — bump so later nextid() calls do not collide
  UPDATE ad_sequence
  SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id), 0) + 1 FROM ad_field)),
      updated = NOW()
  WHERE name = 'AD_Field' AND istableid = 'Y';
END $$;

-- ---------------------------------------------------------------------------
-- 4. Activity type filtering + Included Activities validation rule
-- ---------------------------------------------------------------------------
UPDATE ad_ref_list rl
SET description = TRIM(BOTH ',' FROM
      COALESCE(NULLIF(description, ''), '')
      || CASE WHEN description IS NULL OR description = '' THEN '' ELSE ',' END
      || (
        SELECT string_agg(w.ad_window_id::text, ',' ORDER BY w.name)
        FROM ad_window w
        WHERE w.name IN ('Booking Generator', 'Service Booking', 'Service Agreement (Project)')
          AND w.isactive = 'Y'
      )
    ),
    updated = NOW(),
    updatedby = 100
WHERE rl.ad_reference_id = (
    SELECT c.ad_reference_value_id
    FROM ad_column c
    JOIN ad_table t ON t.ad_table_id = c.ad_table_id
    WHERE t.tablename = 'C_ContactActivity' AND c.columnname = 'ContactActivityType'
    LIMIT 1
  )
  AND rl.isactive = 'Y'
  AND rl.value IN ('10000006', 'APP', 'EM', 'ME', 'PC', 'TA', 'CN')
  AND EXISTS (
    SELECT 1 FROM ad_window w
    WHERE w.name IN ('Booking Generator', 'Service Booking', 'Service Agreement (Project)')
      AND w.isactive = 'Y'
  )
  AND (
    rl.description IS NULL
    OR rl.description NOT LIKE '%' || (
      SELECT w.ad_window_id::text FROM ad_window w
      WHERE w.name = 'Booking Generator' AND w.isactive = 'Y' LIMIT 1
    ) || '%'
  );

UPDATE ad_val_rule vr
SET code = vr.code || COALESCE((
  SELECT string_agg(E'\nOR AD_Window_UU=''' || w.ad_window_uu || '''', '' ORDER BY w.name)
  FROM ad_window w
  WHERE w.name IN ('Booking Generator', 'Service Booking', 'Service Agreement (Project)')
    AND w.isactive = 'Y'
    AND vr.code NOT LIKE '%' || w.ad_window_uu || '%'
), ''),
updated = NOW(),
updatedby = 100
WHERE vr.name = 'AbERP_IncludedActivityWindows';

-- ---------------------------------------------------------------------------
-- 5. Verify
-- ---------------------------------------------------------------------------
SELECT w.ad_window_id, w.name AS window_name, t.ad_tab_id, t.name AS tab_name,
       c.columnname AS link_column, COUNT(f.ad_field_id) AS field_count
FROM ad_window w
JOIN ad_tab t ON t.ad_window_id = w.ad_window_id
JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
LEFT JOIN ad_column c ON c.ad_column_id = t.ad_column_id
LEFT JOIN ad_field f ON f.ad_tab_id = t.ad_tab_id AND f.isactive = 'Y'
WHERE w.name IN ('Booking Generator', 'Service Booking', 'Service Agreement (Project)')
  AND t.name = 'Activity'
  AND tb.tablename = 'C_ContactActivity'
GROUP BY w.ad_window_id, w.name, t.ad_tab_id, t.name, c.columnname
ORDER BY w.name;
