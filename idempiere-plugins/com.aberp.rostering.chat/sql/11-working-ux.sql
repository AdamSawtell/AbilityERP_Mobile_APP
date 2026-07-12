SET search_path TO adempiere;

-- =============================================================================
-- Rostering Chat UX that actually works (no reliance on broken button context)
-- =============================================================================
-- 1. Officers can CREATE a new chat (insert on Chat tab)
-- 2. Officers reply by adding a row on Updates (insert) — same table the app reads
-- 3. Officers close by setting Status = Closed (editable)
-- 4. Keep Send/Close buttons as optional shortcuts; clear displaylogic traps
-- =============================================================================

-- Chat tab: form + allow new records
UPDATE ad_tab t
SET isreadonly = 'N',
    isinsertrecord = 'Y',
    issinglerow = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat' AND t.tablevel = 0;

-- Updates tab: allow adding messages (this is what the app polls)
UPDATE ad_tab t
SET isreadonly = 'N',
    isinsertrecord = 'Y',
    issinglerow = 'N',
    orderbyclause = 'R_RequestUpdate.Created ASC',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Updates';

-- Show only useful Chat fields; make Worker + Status editable
UPDATE ad_field f
SET isdisplayed = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Y'
      WHEN 'R_Status_ID' THEN 'Y'
      WHEN 'AbERP_ChatAwaitingReply' THEN 'Y'
      WHEN 'LastResult' THEN 'Y'
      WHEN 'DateLastAction' THEN 'Y'
      WHEN 'Summary' THEN 'Y'
      WHEN 'AbERP_RosteringReply' THEN 'N'  -- reply via Updates tab instead
      WHEN 'AbERP_SendRosteringReply' THEN 'N'
      WHEN 'AbERP_CloseRosteringChat' THEN 'Y' -- keep close button visible
      WHEN 'DocumentNo' THEN 'N'
      WHEN 'C_BPartner_ID' THEN 'N'
      WHEN 'Created' THEN 'N'
      WHEN 'Updated' THEN 'N'
      WHEN 'SalesRep_ID' THEN 'N'
      ELSE f.isdisplayed
    END,
    isdisplayedgrid = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Y'
      WHEN 'R_Status_ID' THEN 'Y'
      WHEN 'AbERP_ChatAwaitingReply' THEN 'Y'
      WHEN 'LastResult' THEN 'Y'
      WHEN 'DateLastAction' THEN 'Y'
      WHEN 'Summary' THEN 'Y'
      ELSE 'N'
    END,
    isreadonly = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'N'
      WHEN 'R_Status_ID' THEN 'N'
      WHEN 'Summary' THEN 'N'
      WHEN 'AbERP_CloseRosteringChat' THEN 'N'
      WHEN 'AbERP_ChatAwaitingReply' THEN 'Y'
      WHEN 'LastResult' THEN 'Y'
      WHEN 'DateLastAction' THEN 'Y'
      ELSE 'Y'
    END,
    isupdateable = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Y'
      WHEN 'R_Status_ID' THEN 'Y'
      WHEN 'Summary' THEN 'Y'
      WHEN 'AbERP_CloseRosteringChat' THEN 'Y'
      ELSE COALESCE(f.isupdateable, 'N')
    END,
    displaylogic = CASE c.columnname
      WHEN 'AbERP_CloseRosteringChat' THEN NULL  -- always show; process checks status
      ELSE f.displaylogic
    END,
    seqno = CASE c.columnname
      WHEN 'AD_User_ID' THEN 10
      WHEN 'Summary' THEN 15
      WHEN 'R_Status_ID' THEN 20
      WHEN 'AbERP_ChatAwaitingReply' THEN 25
      WHEN 'LastResult' THEN 30
      WHEN 'DateLastAction' THEN 40
      WHEN 'AbERP_CloseRosteringChat' THEN 130
      ELSE f.seqno
    END,
    name = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Worker'
      WHEN 'LastResult' THEN 'Last Message'
      WHEN 'DateLastAction' THEN 'Last Activity'
      WHEN 'Summary' THEN 'Subject'
      ELSE f.name
    END,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat';

-- Column-level updateable for Worker / Status / Close
UPDATE ad_column c
SET isupdateable = 'Y',
    isalwaysupdateable = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'R_Request'
  AND c.columnname IN ('AD_User_ID', 'R_Status_ID', 'Summary', 'AbERP_CloseRosteringChat');

-- Defaults for NEW chat records
UPDATE ad_field f
SET defaultvalue = CASE c.columnname
      WHEN 'R_Status_ID' THEN (
        SELECT rs.r_status_id::text FROM r_status rs
        WHERE rs.isactive = 'Y' AND rs.name = 'Open - Awaiting Action'
        ORDER BY rs.r_status_id LIMIT 1
      )
      WHEN 'Summary' THEN '''Message to Rostering'''
      ELSE f.defaultvalue
    END,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname IN ('R_Status_ID', 'Summary');

-- Prefer Closed status id 102 as defaultvalue helper for officers (not auto-set)
-- Ensure Updates Result field is editable for new rows
UPDATE ad_field f
SET isreadonly = CASE c.columnname
      WHEN 'Result' THEN 'N'
      WHEN 'Created' THEN 'Y'
      WHEN 'CreatedBy' THEN 'Y'
      WHEN 'R_Request_ID' THEN 'Y'
      ELSE f.isreadonly
    END,
    isupdateable = CASE c.columnname
      WHEN 'Result' THEN 'Y'
      ELSE COALESCE(f.isupdateable, 'N')
    END,
    isdisplayed = CASE c.columnname
      WHEN 'Result' THEN 'Y'
      WHEN 'Created' THEN 'Y'
      WHEN 'CreatedBy' THEN 'Y'
      WHEN 'R_Request_ID' THEN 'N'
      ELSE f.isdisplayed
    END,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Updates';

UPDATE ad_column c
SET isupdateable = 'Y',
    isalwaysupdateable = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'R_RequestUpdate'
  AND c.columnname = 'Result';

-- Close process: no mandatory hidden params that block when context empty
UPDATE ad_process_para pp
SET ismandatory = 'N',
    updated = NOW(),
    updatedby = 100
FROM ad_process p
WHERE pp.ad_process_id = p.ad_process_id
  AND p.value IN ('AbERP_RosteringChat_Close', 'AbERP_RosteringChat_Send');

UPDATE ad_process
SET showhelp = 'S',
    updated = NOW(),
    updatedby = 100
WHERE value IN ('AbERP_RosteringChat_Close', 'AbERP_RosteringChat_Send');

-- Hidden defaults so NEW chats get the right type + queue
DO $$
DECLARE
  v_tab_id INTEGER;
  v_type_id INTEGER;
BEGIN
  SELECT t.ad_tab_id INTO v_tab_id
  FROM ad_tab t JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE w.name = 'Rostering Chat' AND t.name = 'Chat' AND t.tablevel = 0 LIMIT 1;

  SELECT r_requesttype_id INTO v_type_id
  FROM r_requesttype WHERE name = 'Rostering Chat' AND isactive = 'Y' LIMIT 1;

  -- R_RequestType_ID field (hidden, defaulted)
  INSERT INTO ad_field (
    ad_field_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby,
    name, iscentrallymaintained, ad_tab_id, ad_column_id,
    isdisplayed, displaylength, isreadonly, seqno, defaultvalue,
    issameline, isheading, isfieldonly, isencrypted, entitytype,
    isdisplayedgrid, xposition, numlines, columnspan,
    isquickentry, istoolbarbutton, ad_field_uu
  )
  SELECT
    (SELECT COALESCE(MAX(ad_field_id), 0) + 1 FROM ad_field),
    0, 0, 'Y', NOW(), 100, NOW(), 100,
    'Request Type', 'N', v_tab_id, c.ad_column_id,
    'N', 14, 'Y', 5, v_type_id::text,
    'N', 'N', 'N', 'N', 'Ab_ERP',
    'N', 1, 1, 1, 'N', 'N',
    substring(md5('AbERP_RosteringChat-field-type'), 1, 8) || '-' ||
    substring(md5('AbERP_RosteringChat-field-type'), 9, 4) || '-4a14-8014-000000000014'
  FROM ad_column c
  JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id AND tb.tablename = 'R_Request'
  WHERE c.columnname = 'R_RequestType_ID'
    AND NOT EXISTS (
      SELECT 1 FROM ad_field f WHERE f.ad_tab_id = v_tab_id AND f.ad_column_id = c.ad_column_id
    );

  UPDATE ad_field f
  SET defaultvalue = v_type_id::text, isdisplayed = 'N', isreadonly = 'Y',
      updated = NOW(), updatedby = 100
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab_id AND f.ad_column_id = c.ad_column_id
    AND c.columnname = 'R_RequestType_ID';

  -- AD_Role_ID field (hidden, default Rostering Officer queue)
  INSERT INTO ad_field (
    ad_field_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby,
    name, iscentrallymaintained, ad_tab_id, ad_column_id,
    isdisplayed, displaylength, isreadonly, seqno, defaultvalue,
    issameline, isheading, isfieldonly, isencrypted, entitytype,
    isdisplayedgrid, xposition, numlines, columnspan,
    isquickentry, istoolbarbutton, ad_field_uu
  )
  SELECT
    (SELECT COALESCE(MAX(ad_field_id), 0) + 1 FROM ad_field),
    0, 0, 'Y', NOW(), 100, NOW(), 100,
    'Role', 'N', v_tab_id, c.ad_column_id,
    'N', 14, 'Y', 6, '1000012',
    'N', 'N', 'N', 'N', 'Ab_ERP',
    'N', 1, 1, 1, 'N', 'N',
    substring(md5('AbERP_RosteringChat-field-role'), 1, 8) || '-' ||
    substring(md5('AbERP_RosteringChat-field-role'), 9, 4) || '-4a15-8015-000000000015'
  FROM ad_column c
  JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id AND tb.tablename = 'R_Request'
  WHERE c.columnname = 'AD_Role_ID'
    AND NOT EXISTS (
      SELECT 1 FROM ad_field f WHERE f.ad_tab_id = v_tab_id AND f.ad_column_id = c.ad_column_id
    );

  UPDATE ad_field f
  SET defaultvalue = '1000012', isdisplayed = 'N', isreadonly = 'Y',
      updated = NOW(), updatedby = 100
  FROM ad_column c
  WHERE f.ad_tab_id = v_tab_id AND f.ad_column_id = c.ad_column_id
    AND c.columnname = 'AD_Role_ID';
END $$;

-- Do NOT activate AD_ModelValidator for plugin classes — core Class.forName
-- cannot see OSGi bundles and breaks login with "Missing class ... global".
-- Sync is handled by sql/12-sync-trigger-no-ad-validator.sql (+ optional OSGi factory).
UPDATE ad_modelvalidator
SET isactive = 'N',
    updated = NOW(),
    updatedby = 100
WHERE modelvalidationclass = 'com.aberp.rostering.chat.model.RosteringChatValidator'
   OR name = 'AbERP Rostering Chat';

SELECT 'tabs' AS c, t.name, t.isreadonly, t.isinsertrecord, t.issinglerow
FROM ad_tab t JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' ORDER BY t.seqno;

SELECT 'chat_fields' AS c, f.name, f.isdisplayed, f.isreadonly, f.isupdateable
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat' AND f.isdisplayed = 'Y'
ORDER BY f.seqno;

SELECT 'upd_fields' AS c, f.name, f.isdisplayed, f.isreadonly, f.isupdateable
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Updates'
ORDER BY f.seqno;

SELECT 'validator' AS c, name, modelvalidationclass, isactive
FROM ad_modelvalidator
WHERE modelvalidationclass LIKE '%RosteringChat%' OR name LIKE '%Rostering Chat%';

