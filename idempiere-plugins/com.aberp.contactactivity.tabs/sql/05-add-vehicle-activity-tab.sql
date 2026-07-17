-- SAW026: add the standard Activity tab to Vehicle (AbERP_Vehicle).
-- Portable and idempotent: no client AD_* numeric IDs are hardcoded.
-- No existing client-owned *_UU value is changed.
\set ON_ERROR_STOP on
SET search_path TO adempiere;

BEGIN;

-- Fail closed before changing metadata.
DO $$
DECLARE
  v_count INTEGER;
  v_type TEXT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM ad_window w
  JOIN ad_tab t ON t.ad_window_id = w.ad_window_id
  JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
  WHERE w.name = 'Vehicle'
    AND w.isactive = 'Y'
    AND tb.tablename = 'AbERP_Vehicle'
    AND t.tablevel = 0
    AND t.isactive = 'Y';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Expected one active Vehicle root tab on AbERP_Vehicle; found %', v_count;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM ad_table
    WHERE tablename = 'C_ContactActivity' AND isactive = 'Y'
  ) THEN
    RAISE EXCEPTION 'Active C_ContactActivity table not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM ad_element
    WHERE columnname = 'AbERP_Vehicle_ID' AND isactive = 'Y'
  ) THEN
    RAISE EXCEPTION 'Active AD_Element AbERP_Vehicle_ID not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM ad_reference r
    JOIN ad_ref_table rt ON rt.ad_reference_id = r.ad_reference_id
    JOIN ad_table tb ON tb.ad_table_id = rt.ad_table_id
    WHERE r.ad_reference_uu = '51ee0d93-0d9d-4d34-8b5b-e62a766c21fc'
      AND r.validationtype = 'T'
      AND r.isactive = 'Y'
      AND tb.tablename = 'AbERP_Vehicle'
  ) THEN
    RAISE EXCEPTION 'Active AbERP_Vehicle Search reference not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM ad_tab t
    JOIN ad_window w ON w.ad_window_id = t.ad_window_id
    JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
    WHERE w.name = 'Enquiry'
      AND t.name = 'Activity'
      AND tb.tablename = 'C_ContactActivity'
      AND t.isactive = 'Y'
  ) THEN
    RAISE EXCEPTION 'Enquiry Activity template tab not found';
  END IF;

  FOREACH v_type IN ARRAY ARRAY['EM', 'ME', 'PC', 'CN', 'TA'] LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM ad_ref_list rl
      JOIN ad_column c ON c.ad_reference_value_id = rl.ad_reference_id
      JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
      WHERE tb.tablename = 'C_ContactActivity'
        AND c.columnname = 'ContactActivityType'
        AND rl.value = v_type
        AND rl.isactive = 'Y'
    ) THEN
      RAISE EXCEPTION 'Active Contact Activity Type % not found', v_type;
    END IF;
  END LOOP;

  IF NOT EXISTS (
    SELECT 1 FROM ad_val_rule
    WHERE name = 'AbERP_IncludedActivityWindows' AND isactive = 'Y'
  ) THEN
    RAISE EXCEPTION 'Validation rule AbERP_IncludedActivityWindows not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM ad_role
    WHERE name = 'AbilityERP Admin' AND isactive = 'Y'
  ) THEN
    RAISE EXCEPTION 'Active AbilityERP Admin role not found';
  END IF;
END $$;

-- Physical child link. Existing data and existing columns are preserved.
ALTER TABLE c_contactactivity
  ADD COLUMN IF NOT EXISTS aberp_vehicle_id numeric(10);

-- Register the child link column by stable names and a fixed AbilityERP UUID.
INSERT INTO ad_column (
  ad_column_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, entitytype, columnname, ad_table_id,
  ad_reference_id, ad_reference_value_id, fieldlength, version,
  iskey, isparent, ismandatory, isupdateable, isidentifier, seqno,
  istranslated, isencrypted, isselectioncolumn,
  ad_element_id, issyncdatabase, isalwaysupdateable,
  isallowlogging, isallowcopy, seqnoselection, istoolbarbutton, issecure,
  fkconstraintname, fkconstrainttype, isdisablezoomacross,
  ad_column_uu
)
SELECT
  nextid((
    SELECT ad_sequence_id::integer
    FROM ad_sequence
    WHERE name = 'AD_Column' AND istableid = 'Y'
    LIMIT 1
  ), 'N'::varchar),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Vehicle', 'Ab_ERP', 'AbERP_Vehicle_ID', ca.ad_table_id,
  COALESCE((
    SELECT ad_reference_id FROM ad_reference
    WHERE name = 'Search' AND validationtype = 'D' AND isactive = 'Y'
    LIMIT 1
  ), 30),
  vehicle_ref.ad_reference_id,
  22, 0,
  'N', 'N', 'N', 'N', 'N', 0,
  'N', 'N', 'N',
  e.ad_element_id, 'Y', 'N',
  'Y', 'Y', 0, 'N', 'N',
  'AbERPVehicle_CContactActivity', 'N', 'N',
  '7d14ac4f-5fef-4f1f-b917-026000000001'
FROM ad_table ca
JOIN ad_element e
  ON e.columnname = 'AbERP_Vehicle_ID'
 AND e.isactive = 'Y'
JOIN ad_reference vehicle_ref
  ON vehicle_ref.ad_reference_uu = '51ee0d93-0d9d-4d34-8b5b-e62a766c21fc'
 AND vehicle_ref.validationtype = 'T'
 AND vehicle_ref.isactive = 'Y'
WHERE ca.tablename = 'C_ContactActivity'
  AND ca.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1
    FROM ad_column c
    WHERE c.ad_table_id = ca.ad_table_id
      AND c.columnname = 'AbERP_Vehicle_ID'
  );

-- Vehicle fields across AbilityERP use the canonical AbERP_Vehicle Search
-- reference so the UI renders the licence identifier. A generic Table Direct
-- link can inherit the numeric parent but display it as ~-1~ in ZK.
UPDATE ad_column c
SET ad_reference_id = COALESCE((
      SELECT ad_reference_id
      FROM ad_reference
      WHERE name = 'Search'
        AND validationtype = 'D'
        AND isactive = 'Y'
      LIMIT 1
    ), 30),
    ad_reference_value_id = vehicle_ref.ad_reference_id,
    updated = NOW(),
    updatedby = 100
FROM ad_table ca
JOIN ad_reference vehicle_ref
  ON vehicle_ref.ad_reference_uu = '51ee0d93-0d9d-4d34-8b5b-e62a766c21fc'
 AND vehicle_ref.validationtype = 'T'
 AND vehicle_ref.isactive = 'Y'
WHERE c.ad_table_id = ca.ad_table_id
  AND ca.tablename = 'C_ContactActivity'
  AND c.columnname = 'AbERP_Vehicle_ID'
  AND c.isactive = 'Y';

-- Register the level-one Activity tab after the existing Vehicle child tabs.
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
  nextid((
    SELECT ad_sequence_id::integer
    FROM ad_sequence
    WHERE name = 'AD_Tab' AND istableid = 'Y'
    LIMIT 1
  ), 'N'::varchar),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Activity', ca.ad_table_id, w.ad_window_id, 45, 1,
  'Y', 'N', 'N', 'N',
  link.ad_column_id, 'N', 'N', 'N',
  'N', 'Ab_ERP', 'Y', 'N',
  'B', 'N', 'Y',
  '7d14ac4f-5fef-4f1f-b917-026000000002'
FROM ad_window w
JOIN ad_tab root
  ON root.ad_window_id = w.ad_window_id
 AND root.tablevel = 0
 AND root.isactive = 'Y'
JOIN ad_table vehicle
  ON vehicle.ad_table_id = root.ad_table_id
 AND vehicle.tablename = 'AbERP_Vehicle'
 AND vehicle.isactive = 'Y'
CROSS JOIN ad_table ca
JOIN ad_column link
  ON link.ad_table_id = ca.ad_table_id
 AND link.columnname = 'AbERP_Vehicle_ID'
 AND link.isactive = 'Y'
WHERE w.name = 'Vehicle'
  AND w.isactive = 'Y'
  AND ca.tablename = 'C_ContactActivity'
  AND ca.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1
    FROM ad_tab t
    WHERE t.ad_window_id = w.ad_window_id
      AND t.ad_table_id = ca.ad_table_id
      AND t.name = 'Activity'
  );

-- Reactivate/rebind an existing Vehicle Activity tab without changing its UUID.
UPDATE ad_tab t
SET isactive = 'Y',
    ad_column_id = link.ad_column_id,
    seqno = 45,
    tablevel = 1,
    updated = NOW(),
    updatedby = 100
FROM ad_window w
JOIN ad_table ca
  ON ca.tablename = 'C_ContactActivity'
 AND ca.isactive = 'Y'
JOIN ad_column link
  ON link.ad_table_id = ca.ad_table_id
 AND link.columnname = 'AbERP_Vehicle_ID'
 AND link.isactive = 'Y'
WHERE t.ad_window_id = w.ad_window_id
  AND t.ad_table_id = ca.ad_table_id
  AND t.name = 'Activity'
  AND w.name = 'Vehicle'
  AND w.isactive = 'Y';

-- Clone the established Enquiry Activity fields. The Enquiry parent link field
-- is replaced with AbERP_Vehicle_ID; every other field keeps its configuration.
DO $$
DECLARE
  v_template_tab_id INTEGER;
  v_target_tab_id INTEGER;
  v_link_column_id INTEGER;
  v_source RECORD;
  v_column_id INTEGER;
  v_field_id INTEGER;
  v_field_uu TEXT;
BEGIN
  SELECT t.ad_tab_id INTO STRICT v_template_tab_id
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
  WHERE w.name = 'Enquiry'
    AND t.name = 'Activity'
    AND tb.tablename = 'C_ContactActivity'
    AND t.isactive = 'Y'
  LIMIT 1;

  SELECT t.ad_tab_id, t.ad_column_id
  INTO STRICT v_target_tab_id, v_link_column_id
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
  WHERE w.name = 'Vehicle'
    AND t.name = 'Activity'
    AND tb.tablename = 'C_ContactActivity'
    AND t.isactive = 'Y'
  LIMIT 1;

  FOR v_source IN
    SELECT f.*, c.columnname
    FROM ad_field f
    JOIN ad_column c ON c.ad_column_id = f.ad_column_id
    WHERE f.ad_tab_id = v_template_tab_id
      AND f.isactive = 'Y'
    ORDER BY f.seqno, f.ad_field_id
  LOOP
    v_column_id := CASE
      WHEN v_source.columnname = 'AbERP_Enquiry_ID' THEN v_link_column_id
      ELSE v_source.ad_column_id
    END;

    IF NOT EXISTS (
      SELECT 1 FROM ad_field
      WHERE ad_tab_id = v_target_tab_id
        AND ad_column_id = v_column_id
    ) THEN
      v_field_id := nextid((
        SELECT ad_sequence_id::integer
        FROM ad_sequence
        WHERE name = 'AD_Field' AND istableid = 'Y'
        LIMIT 1
      ), 'N'::varchar);

      v_field_uu :=
        substring(md5('SAW026-Vehicle-Activity-' || v_source.columnname), 1, 8) || '-' ||
        substring(md5('SAW026-Vehicle-Activity-' || v_source.columnname), 9, 4) || '-4026-8026-' ||
        substring(md5('SAW026-Vehicle-Activity-' || v_source.columnname), 13, 12);

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
        v_field_id, v_source.ad_client_id, v_source.ad_org_id, 'Y',
        NOW(), 100, NOW(), 100,
        CASE
          WHEN v_source.columnname = 'AbERP_Enquiry_ID' THEN 'Vehicle'
          ELSE v_source.name
        END,
        v_source.description, v_source.help, v_source.iscentrallymaintained,
        v_target_tab_id, v_column_id, v_source.ad_fieldgroup_id,
        v_source.isdisplayed, v_source.displaylogic, v_source.displaylength,
        v_source.isreadonly, v_source.seqno, v_source.sortno,
        v_source.issameline, v_source.isheading, v_source.isfieldonly,
        v_source.isencrypted, 'Ab_ERP',
        v_source.ad_reference_id, v_source.ismandatory, v_source.included_tab_id,
        v_source.defaultvalue, v_source.ad_reference_value_id,
        v_source.ad_val_rule_id, v_source.infofactoryclass,
        v_source.isallowcopy, v_source.seqnogrid, v_source.isdisplayedgrid,
        v_source.xposition, v_source.numlines, v_source.columnspan,
        v_source.isquickentry, v_source.isupdateable,
        v_source.isalwaysupdateable, v_source.mandatorylogic,
        v_source.readonlylogic, v_source.istoolbarbutton,
        v_source.isadvancedfield, v_source.isdefaultfocus, v_source.vformat,
        v_source.placeholder, v_source.isquickform,
        v_source.isselectioncolumn, v_source.isdisablezoomacross,
        v_field_uu
      );
    END IF;
  END LOOP;
END $$;

-- A conservative rollback deactivates these fields; make re-apply restorative.
UPDATE ad_field f
SET isactive = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
WHERE f.ad_tab_id = t.ad_tab_id
  AND w.name = 'Vehicle'
  AND t.name = 'Activity'
  AND tb.tablename = 'C_ContactActivity';

-- Enable the five SAW007 Activity Types for Vehicle.
DO $$
DECLARE
  v_window_id INTEGER;
  v_type TEXT;
  v_ref_id INTEGER;
BEGIN
  SELECT ad_window_id INTO STRICT v_window_id
  FROM ad_window
  WHERE name = 'Vehicle' AND isactive = 'Y'
  LIMIT 1;

  SELECT c.ad_reference_value_id INTO STRICT v_ref_id
  FROM ad_column c
  JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
  WHERE tb.tablename = 'C_ContactActivity'
    AND c.columnname = 'ContactActivityType'
  LIMIT 1;

  FOREACH v_type IN ARRAY ARRAY['EM', 'ME', 'PC', 'CN', 'TA'] LOOP
    UPDATE ad_ref_list
    SET description = TRIM(BOTH ',' FROM
          COALESCE(NULLIF(description, ''), '')
          || CASE WHEN description IS NULL OR description = '' THEN '' ELSE ',' END
          || v_window_id::text
        ),
        updated = NOW(),
        updatedby = 100
    WHERE ad_reference_id = v_ref_id
      AND value = v_type
      AND isactive = 'Y'
      AND (
        description IS NULL
        OR ',' || description || ',' NOT LIKE '%,' || v_window_id::text || ',%'
      );
  END LOOP;
END $$;

-- Make Vehicle available in Included Activities window selection.
UPDATE ad_val_rule vr
SET code = vr.code || E'\nOR AD_Window_UU=''' || w.ad_window_uu || '''',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE vr.name = 'AbERP_IncludedActivityWindows'
  AND vr.isactive = 'Y'
  AND w.name = 'Vehicle'
  AND w.isactive = 'Y'
  AND vr.code NOT LIKE '%' || w.ad_window_uu || '%';

-- Ensure both standard administrator roles can open the existing parent window.
UPDATE ad_window_access wa
SET isactive = 'Y',
    isreadwrite = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_role r
JOIN ad_window w ON w.name = 'Vehicle' AND w.isactive = 'Y'
WHERE wa.ad_role_id = r.ad_role_id
  AND wa.ad_window_id = w.ad_window_id
  AND r.name IN ('AbilityERP Admin', 'Admin')
  AND r.isactive = 'Y';

INSERT INTO ad_window_access (
  ad_window_id, ad_role_id, ad_client_id, ad_org_id,
  isactive, created, createdby, updated, updatedby,
  isreadwrite, ad_window_access_uu
)
SELECT
  w.ad_window_id, r.ad_role_id, 0, 0,
  'Y', NOW(), 100, NOW(), 100,
  'Y',
  substring(md5('SAW026-' || r.ad_role_uu || '-' || w.ad_window_uu), 1, 8) || '-' ||
  substring(md5('SAW026-' || r.ad_role_uu || '-' || w.ad_window_uu), 9, 4) || '-4026-8026-' ||
  substring(md5('SAW026-' || r.ad_role_uu || '-' || w.ad_window_uu), 13, 12)
FROM ad_role r
CROSS JOIN ad_window w
WHERE r.name IN ('AbilityERP Admin', 'Admin')
  AND r.isactive = 'Y'
  AND w.name = 'Vehicle'
  AND w.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_window_access wa
    WHERE wa.ad_role_id = r.ad_role_id
      AND wa.ad_window_id = w.ad_window_id
  );

COMMIT;

-- Verification: one tab, linked fields, all five types, and role access.
SELECT w.name AS window_name, t.ad_tab_id, t.ad_tab_uu, t.seqno,
       c.columnname AS link_column, COUNT(f.ad_field_id) AS field_count
FROM ad_window w
JOIN ad_tab t ON t.ad_window_id = w.ad_window_id
JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
LEFT JOIN ad_column c ON c.ad_column_id = t.ad_column_id
LEFT JOIN ad_field f ON f.ad_tab_id = t.ad_tab_id AND f.isactive = 'Y'
WHERE w.name = 'Vehicle'
  AND t.name = 'Activity'
  AND tb.tablename = 'C_ContactActivity'
GROUP BY w.name, t.ad_tab_id, t.ad_tab_uu, t.seqno, c.columnname;

SELECT rl.value, rl.name,
       CASE
         WHEN ',' || COALESCE(rl.description, '') || ','
              LIKE '%,' || w.ad_window_id::text || ',%' THEN 'Y'
         ELSE 'N'
       END AS enabled
FROM ad_ref_list rl
JOIN ad_column c ON c.ad_reference_value_id = rl.ad_reference_id
JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
CROSS JOIN ad_window w
WHERE tb.tablename = 'C_ContactActivity'
  AND c.columnname = 'ContactActivityType'
  AND rl.value IN ('EM', 'ME', 'PC', 'CN', 'TA')
  AND rl.isactive = 'Y'
  AND w.name = 'Vehicle'
  AND w.isactive = 'Y'
ORDER BY rl.value;

SELECT r.name AS role_name, wa.isactive, wa.isreadwrite
FROM ad_window_access wa
JOIN ad_role r ON r.ad_role_id = wa.ad_role_id
JOIN ad_window w ON w.ad_window_id = wa.ad_window_id
WHERE w.name = 'Vehicle'
  AND r.name IN ('AbilityERP Admin', 'Admin')
ORDER BY r.name;
