SET search_path TO adempiere, public;

-- =============================================================================
-- Officer can create a new Rostering Chat from WebUI:
--   New → pick Worker → Save → thread appears in that worker's PWA
-- =============================================================================

-- 1) Allow New on Chat tab (Updates stay read-only history)
UPDATE ad_tab t
SET isreadonly = 'N',
    isinsertrecord = 'Y',
    issinglerow = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND t.tablevel = 0;

UPDATE ad_tab t
SET isreadonly = 'Y',
    isinsertrecord = 'N',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Updates';

-- 2) Validation rule: Worker = Support Worker / Employee Mobile users
DO $$
DECLARE
  v_rule_id INTEGER;
BEGIN
  SELECT ad_val_rule_id INTO v_rule_id
  FROM ad_val_rule
  WHERE name = 'AbERP_RosteringChat_Worker'
  LIMIT 1;

  IF v_rule_id IS NULL THEN
    SELECT COALESCE(MAX(ad_val_rule_id), 0) + 1 INTO v_rule_id FROM ad_val_rule;
    INSERT INTO ad_val_rule (
      ad_val_rule_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, type, code, entitytype, ad_val_rule_uu
    ) VALUES (
      v_rule_id, 0, 0, 'Y',
      NOW(), 100, NOW(), 100,
      'AbERP_RosteringChat_Worker',
      'Users with Support Worker or Employee Mobile role (Rostering Chat Worker picker)',
      'S',
      $code$AD_User.AD_User_ID IN (
  SELECT ur.AD_User_ID
  FROM AD_User_Roles ur
  JOIN AD_Role r ON r.AD_Role_ID = ur.AD_Role_ID
  WHERE ur.IsActive = 'Y'
    AND r.IsActive = 'Y'
    AND r.Name IN ('Support Worker', 'Employee Mobile')
)$code$,
      'Ab_ERP',
      substring(md5('AbERP_RosteringChat_Worker'), 1, 8) || '-' ||
      substring(md5('AbERP_RosteringChat_Worker'), 9, 4) || '-4a26-8026-000000000026'
    );
  ELSE
    UPDATE ad_val_rule
    SET code = $code$AD_User.AD_User_ID IN (
  SELECT ur.AD_User_ID
  FROM AD_User_Roles ur
  JOIN AD_Role r ON r.AD_Role_ID = ur.AD_Role_ID
  WHERE ur.IsActive = 'Y'
    AND r.IsActive = 'Y'
    AND r.Name IN ('Support Worker', 'Employee Mobile')
)$code$,
        isactive = 'Y',
        updated = NOW(),
        updatedby = 100
    WHERE ad_val_rule_id = v_rule_id;
  END IF;
END $$;

-- 3) Chat fields: Worker mandatory + worker val rule; SalesRep default = logged-in officer
UPDATE ad_field f
SET ismandatory = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Y'
      ELSE COALESCE(f.ismandatory, 'N')
    END,
    isdisplayed = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Y'
      WHEN 'Summary' THEN 'Y'
      WHEN 'SalesRep_ID' THEN 'N'
      WHEN 'C_BPartner_ID' THEN 'N'
      WHEN 'R_RequestType_ID' THEN 'N'
      WHEN 'AD_Role_ID' THEN 'N'
      WHEN 'R_Status_ID' THEN 'N'
      ELSE f.isdisplayed
    END,
    isreadonly = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'N'
      WHEN 'Summary' THEN 'N'
      ELSE f.isreadonly
    END,
    isupdateable = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Y'
      WHEN 'Summary' THEN 'Y'
      ELSE COALESCE(f.isupdateable, 'N')
    END,
    defaultvalue = CASE c.columnname
      WHEN 'Summary' THEN '''Rostering Chat'''
      WHEN 'SalesRep_ID' THEN '@#AD_User_ID@'
      WHEN 'AD_Role_ID' THEN NULL  -- officer-initiated → awaiting worker (not queue 1000012)
      WHEN 'LastResult' THEN '''Hello — rostering would like to get in touch with you.'''
      ELSE f.defaultvalue
    END,
    ad_val_rule_id = CASE c.columnname
      WHEN 'AD_User_ID' THEN (
        SELECT vr.ad_val_rule_id FROM ad_val_rule vr
        WHERE vr.name = 'AbERP_RosteringChat_Worker' LIMIT 1
      )
      ELSE f.ad_val_rule_id
    END,
    name = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Worker'
      WHEN 'Summary' THEN 'Subject'
      ELSE f.name
    END,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND c.columnname IN (
    'AD_User_ID', 'Summary', 'SalesRep_ID', 'C_BPartner_ID',
    'R_RequestType_ID', 'AD_Role_ID', 'R_Status_ID', 'LastResult'
  );

-- Keep type / open status defaults (do not clear)
UPDATE ad_field f
SET defaultvalue = COALESCE(
      f.defaultvalue,
      (SELECT rt.r_requesttype_id::text FROM r_requesttype rt
       WHERE rt.name = 'Rostering Chat' AND rt.isactive = 'Y' LIMIT 1)
    ),
    isdisplayed = 'N',
    isreadonly = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname = 'R_RequestType_ID';

UPDATE ad_field f
SET defaultvalue = COALESCE(
      f.defaultvalue,
      (SELECT rs.r_status_id::text FROM r_status rs
       WHERE rs.isactive = 'Y' AND rs.name = 'Open - Awaiting Action'
       ORDER BY rs.r_status_id LIMIT 1)
    ),
    isdisplayed = 'N',
    isreadonly = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname = 'R_Status_ID';

-- Column must allow Worker edit on new records
UPDATE ad_column c
SET isupdateable = 'Y',
    isalwaysupdateable = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'R_Request'
  AND c.columnname IN ('AD_User_ID', 'Summary', 'SalesRep_ID', 'C_BPartner_ID', 'LastResult');

-- 4) BEFORE INSERT/UPDATE: stamp BP from Worker; fill SalesRep / greeting / DateLastAction
CREATE OR REPLACE FUNCTION aberp_rostering_chat_before_save()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_type_name TEXT;
  v_bp INTEGER;
BEGIN
  SELECT rt.name INTO v_type_name
  FROM r_requesttype rt
  WHERE rt.r_requesttype_id = NEW.r_requesttype_id;

  IF v_type_name IS DISTINCT FROM 'Rostering Chat' THEN
    RETURN NEW;
  END IF;

  IF NEW.ad_user_id IS NOT NULL AND NEW.ad_user_id > 0 THEN
    SELECT u.c_bpartner_id INTO v_bp
    FROM ad_user u
    WHERE u.ad_user_id = NEW.ad_user_id;
    IF v_bp IS NOT NULL AND v_bp > 0 THEN
      NEW.c_bpartner_id := v_bp;
    END IF;
  END IF;

  IF COALESCE(NEW.salesrep_id, 0) <= 0 THEN
    NEW.salesrep_id := COALESCE(NEW.updatedby, NEW.createdby, 100);
  END IF;

  IF TG_OP = 'INSERT' THEN
    IF NEW.lastresult IS NULL OR btrim(NEW.lastresult) = '' THEN
      NEW.lastresult := 'Hello — rostering would like to get in touch with you.';
    END IF;
    -- Officer-created thread: worker should respond (not queued to rostering)
    IF COALESCE(NEW.ad_role_id, 0) = 1000012 THEN
      NEW.ad_role_id := NULL;
    END IF;
    NEW.datelastaction := COALESCE(NEW.datelastaction, NOW());
    IF NEW.summary IS NULL OR btrim(NEW.summary) = '' THEN
      NEW.summary := 'Rostering Chat';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS aberp_rostering_chat_before_save_trg ON r_request;
CREATE TRIGGER aberp_rostering_chat_before_save_trg
BEFORE INSERT OR UPDATE OF ad_user_id, salesrep_id, lastresult, summary, ad_role_id
ON r_request
FOR EACH ROW
EXECUTE FUNCTION aberp_rostering_chat_before_save();

-- Verify
SELECT 'tab' AS c, t.name, t.isinsertrecord, t.isreadonly
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat'
ORDER BY t.tablevel, t.seqno;

SELECT 'worker_field' AS c, f.name, f.isdisplayed, f.isreadonly, f.ismandatory,
       f.defaultvalue, vr.name AS val_rule
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
LEFT JOIN ad_val_rule vr ON vr.ad_val_rule_id = f.ad_val_rule_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat' AND c.columnname = 'AD_User_ID';

SELECT 'defaults' AS c, c.columnname, f.defaultvalue, f.isdisplayed
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname IN (
    'Summary', 'SalesRep_ID', 'AD_Role_ID', 'R_RequestType_ID',
    'R_Status_ID', 'LastResult'
  )
ORDER BY c.columnname;
