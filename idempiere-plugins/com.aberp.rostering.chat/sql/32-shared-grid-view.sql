SET search_path TO adempiere, public;

-- =============================================================================
-- Rostering Chat — shared Grid View (pack-in / all users)
--
-- iDempiere best practice: configure grid columns on AD_Field
--   (IsDisplayedGrid + SeqNoGrid), NOT per-user Customize Grid
--   (AD_TabCustomization). Form layout stays on SeqNo / XPosition.
--
-- Inbox columns (grid): Last Activity | Chat Assigned | Worker | Last Message
-- Reply / Send Chat / Close Chat stay form-only (toggle to single-row to act).
-- =============================================================================

-- 1) Shared grid column set + order
UPDATE ad_field f
SET isdisplayedgrid = CASE c.columnname
      WHEN 'DateLastAction' THEN 'Y'
      WHEN 'AbERP_ChatAwaitingReply' THEN 'Y'
      WHEN 'AD_User_ID' THEN 'Y'
      WHEN 'LastResult' THEN 'Y'
      ELSE 'N'
    END,
    seqnogrid = CASE c.columnname
      WHEN 'DateLastAction' THEN 10
      WHEN 'AbERP_ChatAwaitingReply' THEN 20
      WHEN 'AD_User_ID' THEN 30
      WHEN 'LastResult' THEN 40
      ELSE 0
    END,
    name = CASE c.columnname
      WHEN 'DateLastAction' THEN 'Last Activity'
      WHEN 'AbERP_ChatAwaitingReply' THEN 'Chat Assigned'
      WHEN 'AD_User_ID' THEN 'Worker'
      WHEN 'LastResult' THEN 'Last Message'
      ELSE f.name
    END,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat';

-- Explicitly hide action / system columns from grid (form still uses SeqNo)
UPDATE ad_field f
SET isdisplayedgrid = 'N',
    seqnogrid = 0,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND c.columnname IN (
    'AbERP_RosteringReply', 'AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat',
    'R_Status_ID', 'Summary', 'Processed', 'UpdatedBy', 'AD_Org_ID', 'AD_Client_ID',
    'CreatedBy', 'IsActive', 'DocumentNo', 'R_Request_ID', 'R_RequestType_ID',
    'AD_Role_ID', 'C_BPartner_ID', 'Created', 'Updated', 'SalesRep_ID'
  );

-- 2) Form: Send Chat / Close Chat start at column 2 (unchanged contract)
UPDATE ad_field f
SET xposition = CASE c.columnname
      WHEN 'AbERP_SendRosteringReply' THEN 2
      WHEN 'AbERP_CloseRosteringChat' THEN 3
      ELSE f.xposition
    END,
    columnspan = CASE c.columnname
      WHEN 'AbERP_SendRosteringReply' THEN 1
      WHEN 'AbERP_CloseRosteringChat' THEN 1
      ELSE f.columnspan
    END,
    issameline = CASE c.columnname
      WHEN 'AbERP_SendRosteringReply' THEN 'N'
      WHEN 'AbERP_CloseRosteringChat' THEN 'Y'
      ELSE f.issameline
    END,
    isdisplayed = 'Y',
    isdisplayedgrid = 'N',
    displaylogic = NULL,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND c.columnname IN ('AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat');

-- Form mode required so Reply edits are not ignored (toggle to Grid for triage)
UPDATE ad_tab t
SET issinglerow = 'Y',
    whereclause = 'R_Request.R_RequestType_ID=' || (
      SELECT rt.r_requesttype_id::text
      FROM r_requesttype rt
      WHERE rt.name = 'Rostering Chat' AND rt.isactive = 'Y'
      ORDER BY rt.r_requesttype_id
      LIMIT 1
    ),
    orderbyclause = 'R_Request.DateLastAction DESC NULLS LAST, R_Request.Updated DESC',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat';

-- 3) Drop per-user grid overrides so AD_Field wins for everyone / pack-in
DELETE FROM ad_tab_customization
WHERE ad_tab_id IN (
  SELECT t.ad_tab_id
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
);

-- 4) Saved queries: encoded Find format (UI-native) + keep IsDefault for Lookup label
UPDATE ad_userquery uq
SET code = CASE uq.name
      WHEN 'Response required' THEN 'AbERP_ChatAwaitingReply<^>=<^>Response required<^><^>'
      WHEN 'Awaiting worker' THEN 'AbERP_ChatAwaitingReply<^>=<^>Awaiting worker<^><^>'
      WHEN 'Closed' THEN 'AbERP_ChatAwaitingReply<^>=<^>Closed<^><^>'
      ELSE uq.code
    END,
    isdefault = CASE WHEN uq.name = 'Response required' THEN 'Y' ELSE 'N' END,
    description = CASE uq.name
      WHEN 'Response required' THEN
        'Default inbox (applied on open by Rostering Chat tab). Also selectable from Lookup.'
      WHEN 'Awaiting worker' THEN
        'Chats waiting for the worker app. Select from the toolbar Lookup.'
      WHEN 'Closed' THEN
        'Closed chats. Select from the toolbar Lookup.'
      ELSE uq.description
    END,
    updated = NOW(),
    updatedby = 100
WHERE uq.ad_tab_id IN (
  SELECT t.ad_tab_id
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
)
AND uq.name IN ('Response required', 'Awaiting worker', 'Closed')
AND uq.ad_user_id IS NULL;

SELECT 'grid' AS c, f.seqnogrid, f.name, c.columnname, f.isdisplayedgrid, f.isdisplayed
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND f.isdisplayedgrid = 'Y'
ORDER BY f.seqnogrid;

SELECT 'buttons' AS c, f.name, f.xposition, f.issameline, f.isdisplayedgrid
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname IN ('AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat');

SELECT 'customizations_left' AS c, COUNT(*)::int AS n
FROM ad_tab_customization
WHERE ad_tab_id IN (
  SELECT t.ad_tab_id FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
);
