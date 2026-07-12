-- Fix User/Contact hardcoded on Activity tabs (Booking Generator, Service Booking, Service Agreement).
--
-- ROOT CAUSE: C_ContactActivity.AD_User_ID column has default @AD_User_ID@ which
-- pre-fills the same user on every new activity when the parent window has no AD_User_ID
-- (e.g. Booking Generator only has C_BPartner_ID). AbilityERP uses AbERP_User_BP_ID
-- filtered by C_BPartner_ID instead — see Shift (Rostered) Activity tab.
--
-- Portable: resolve table/windows/columns by name — never hardcode AD_Table_ID.
-- PG-safe UPDATE … FROM (no JOIN that references the target alias).
-- Run after register-contactactivity-tabs.sql. Log out/in after applying.
SET search_path TO adempiere;

-- 1. Override column default @AD_User_ID@ on these tabs — stop auto-fill
UPDATE ad_field f
SET defaultvalue = NULL,
    isdisplayed = 'N',
    isdisplayedgrid = 'N',
    isreadonly = 'N',
    seqno = 0,
    updated = NOW(),
    updatedby = 100
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE f.ad_tab_id = t.ad_tab_id
  AND t.name = 'Activity'
  AND w.name IN ('Booking Generator', 'Service Booking', 'Service Agreement (Project)')
  AND EXISTS (
    SELECT 1 FROM ad_column col
    WHERE col.ad_column_id = f.ad_column_id AND col.columnname = 'AD_User_ID'
  );

-- 2. Business Partner — show, editable, inherit from parent record
UPDATE ad_field f
SET isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    isreadonly = 'N',
    defaultvalue = '@C_BPartner_ID@',
    seqno = 70,
    seqnogrid = 160,
    xposition = 1,
    numlines = 1,
    columnspan = 2,
    updated = NOW(),
    updatedby = 100
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE f.ad_tab_id = t.ad_tab_id
  AND t.name = 'Activity'
  AND w.name IN ('Booking Generator', 'Service Booking', 'Service Agreement (Project)')
  AND EXISTS (
    SELECT 1 FROM ad_column col
    WHERE col.ad_column_id = f.ad_column_id AND col.columnname = 'C_BPartner_ID'
  );

-- 3. Add User field (AbERP_User_BP_ID) — picks contact for the Business Partner
-- Use MAX+1 (not nextid): AD_Field sequence often lags after bulk tab clones.
DO $$
DECLARE
  r RECORD;
  v_col_id INTEGER;
  v_new_id INTEGER;
  v_uu TEXT;
BEGIN
  SELECT c.ad_column_id INTO v_col_id
  FROM ad_column c
  JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
  WHERE tb.tablename = 'C_ContactActivity' AND tb.isactive = 'Y'
    AND c.columnname = 'AbERP_User_BP_ID'
  LIMIT 1;
  IF v_col_id IS NULL THEN
    RAISE EXCEPTION 'AbERP_User_BP_ID column not found on C_ContactActivity';
  END IF;

  FOR r IN
    SELECT t.ad_tab_id
    FROM ad_tab t
    JOIN ad_window w ON w.ad_window_id = t.ad_window_id
    WHERE t.name = 'Activity'
      AND w.name IN ('Booking Generator', 'Service Booking', 'Service Agreement (Project)')
      AND NOT EXISTS (
        SELECT 1 FROM ad_field x
        WHERE x.ad_tab_id = t.ad_tab_id AND x.ad_column_id = v_col_id
      )
  LOOP
    SELECT COALESCE(MAX(ad_field_id), 0) + 1 INTO v_new_id FROM ad_field;
    v_uu :=
      substring(md5('aberp-ca-user-' || r.ad_tab_id::text), 1, 8) || '-' ||
      substring(md5('aberp-ca-user-' || r.ad_tab_id::text), 9, 4) || '-4002-8002-' ||
      substring(md5('aberp-ca-user-' || r.ad_tab_id::text), 13, 12);

    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, iscentrallymaintained, ad_tab_id, ad_column_id,
      isdisplayed, displaylength, isreadonly, seqno,
      issameline, isheading, isfieldonly, isencrypted, entitytype,
      isdisplayedgrid, seqnogrid, xposition, numlines, columnspan,
      isquickentry, isadvancedfield, isdefaultfocus,
      isquickform, isselectioncolumn, isdisablezoomacross,
      ad_field_uu
    ) VALUES (
      v_new_id, 0, 0, 'Y',
      NOW(), 100, NOW(), 100,
      'User', 'Y', r.ad_tab_id, v_col_id,
      'Y', 0, 'N', 80,
      'N', 'N', 'N', 'N', 'Ab_ERP',
      'Y', 170, 4, 1, 2,
      'N', 'N', 'N',
      'N', 'N', 'N',
      v_uu
    );
  END LOOP;

  UPDATE ad_sequence
  SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id), 0) + 1 FROM ad_field)),
      updated = NOW()
  WHERE name = 'AD_Field' AND istableid = 'Y';
END $$;

UPDATE ad_field f
SET name = 'User',
    defaultvalue = NULL,
    isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    isreadonly = 'N',
    seqno = 80,
    seqnogrid = 170,
    xposition = 4,
    numlines = 1,
    columnspan = 2,
    updated = NOW(),
    updatedby = 100
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE f.ad_tab_id = t.ad_tab_id
  AND t.name = 'Activity'
  AND w.name IN ('Booking Generator', 'Service Booking', 'Service Agreement (Project)')
  AND EXISTS (
    SELECT 1 FROM ad_column col
    WHERE col.ad_column_id = f.ad_column_id AND col.columnname = 'AbERP_User_BP_ID'
  );

-- 4. Backfill Business Partner from parent where missing
UPDATE c_contactactivity ca
SET c_bpartner_id = bg.c_bpartner_id, updated = NOW(), updatedby = 100
FROM aberp_bookinggenerator bg
WHERE ca.aberp_bookinggenerator_id = bg.aberp_bookinggenerator_id
  AND ca.c_bpartner_id IS NULL AND bg.c_bpartner_id IS NOT NULL;

UPDATE c_contactactivity ca
SET c_bpartner_id = o.c_bpartner_id, updated = NOW(), updatedby = 100
FROM c_order o
WHERE ca.c_order_id = o.c_order_id
  AND ca.c_bpartner_id IS NULL AND o.c_bpartner_id IS NOT NULL;

UPDATE c_contactactivity ca
SET c_bpartner_id = p.c_bpartner_id, updated = NOW(), updatedby = 100
FROM c_project p
WHERE ca.c_project_id = p.c_project_id
  AND ca.c_bpartner_id IS NULL AND p.c_bpartner_id IS NOT NULL;

-- 5. Migrate wrongly saved AD_User_ID to AbERP_User_BP_ID, then clear AD_User_ID
UPDATE c_contactactivity
SET aberp_user_bp_id = ad_user_id,
    ad_user_id = NULL,
    updated = NOW(),
    updatedby = 100
WHERE ad_user_id IS NOT NULL
  AND aberp_user_bp_id IS NULL
  AND (aberp_bookinggenerator_id IS NOT NULL OR c_order_id IS NOT NULL OR c_project_id IS NOT NULL);

-- Verify
SELECT w.name AS window_name, f.name AS field_name, col.columnname,
       f.defaultvalue, f.isdisplayed, f.isreadonly, f.seqno
FROM ad_field f
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
JOIN ad_column col ON col.ad_column_id = f.ad_column_id
WHERE t.name = 'Activity'
  AND w.name IN ('Booking Generator', 'Service Booking', 'Service Agreement (Project)')
  AND col.columnname IN ('C_BPartner_ID', 'AD_User_ID', 'AbERP_User_BP_ID')
ORDER BY w.name, f.seqno;
