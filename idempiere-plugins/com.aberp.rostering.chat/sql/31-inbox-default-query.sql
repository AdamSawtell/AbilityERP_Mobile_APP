SET search_path TO adempiere, public;

-- =============================================================================
-- Rostering Chat inbox:
--   1) Send Chat / Close Chat start at form column 2
--   2) Shared AD_UserQuery rows (Response required default label + Lookup options)
--      Menu open passes a non-null MQuery, so IsDefault alone does not filter.
--      RosteringChatTabPanel applies Response required on first activate;
--      32-shared-grid-view.sql sets shared SeqNoGrid columns.
--      Tab WhereClause stays type-only so Lookup can reach Awaiting worker / Closed.
-- =============================================================================

-- 1) Buttons start at column 2
UPDATE ad_field f
SET xposition = CASE c.columnname
      WHEN 'AbERP_SendRosteringReply' THEN 2
      WHEN 'AbERP_CloseRosteringChat' THEN 3
      ELSE f.xposition
    END,
    columnspan = 1,
    issameline = CASE c.columnname
      WHEN 'AbERP_CloseRosteringChat' THEN 'Y'
      WHEN 'AbERP_SendRosteringReply' THEN 'N'
      ELSE f.issameline
    END,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND c.columnname IN ('AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat');

-- Keep type filter only (do NOT bake Response required into WhereClause —
-- that would permanently hide Closed / Awaiting worker from Find).
UPDATE ad_tab t
SET whereclause = 'R_Request.R_RequestType_ID=' || (
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

-- Find dialog: make Worker + Chat Assigned searchable
UPDATE ad_column c
SET isselectioncolumn = 'Y',
    seqnoselection = CASE c.columnname
      WHEN 'AbERP_ChatAwaitingReply' THEN 10
      WHEN 'AD_User_ID' THEN 20
      WHEN 'DocumentNo' THEN 30
      ELSE COALESCE(c.seqnoselection, 99)
    END,
    updated = NOW(),
    updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'R_Request'
  AND c.columnname IN ('AbERP_ChatAwaitingReply', 'AD_User_ID', 'DocumentNo');

-- 2) Default + optional saved queries (shared, all users)
DO $$
DECLARE
  v_table_id INTEGER;
  v_tab_id INTEGER;
  v_window_id INTEGER;
  v_client_id INTEGER;
BEGIN
  SELECT COALESCE(
    (SELECT ad_client_id FROM ad_client WHERE name = 'AbilityERP' AND isactive = 'Y' ORDER BY ad_client_id LIMIT 1),
    (SELECT ad_client_id FROM ad_client WHERE ad_client_id > 0 AND isactive = 'Y' ORDER BY ad_client_id LIMIT 1)
  ) INTO v_client_id;

  SELECT ad_table_id INTO v_table_id FROM ad_table WHERE tablename = 'R_Request';
  SELECT t.ad_tab_id, w.ad_window_id
    INTO v_tab_id, v_window_id
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE w.name = 'Rostering Chat' AND t.name = 'Chat';

  -- Response required (DEFAULT inbox)
  IF NOT EXISTS (
    SELECT 1 FROM ad_userquery
    WHERE ad_tab_id = v_tab_id AND name = 'Response required' AND ad_user_id IS NULL
  ) THEN
    INSERT INTO ad_userquery (
      ad_userquery_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_user_id, ad_table_id, ad_tab_id, ad_window_id,
      ad_role_id, isdefault, code, ad_userquery_uu
    ) VALUES (
      (SELECT COALESCE(MAX(ad_userquery_id), 0) + 1 FROM ad_userquery),
      v_client_id, 0, 'Y',
      NOW(), 100, NOW(), 100,
      'Response required',
      'Inbox: chats waiting for rostering. Clear or change Lookup to find Awaiting worker / Closed.',
      NULL, v_table_id, v_tab_id, v_window_id,
      NULL, 'Y',
      '@SQL=R_Request.AbERP_ChatAwaitingReply=''Response required''',
      generate_uuid()
    );
  ELSE
    UPDATE ad_userquery
    SET isdefault = 'Y',
        code = '@SQL=R_Request.AbERP_ChatAwaitingReply=''Response required''',
        description = 'Inbox: chats waiting for rostering. Clear or change Lookup to find Awaiting worker / Closed.',
        ad_window_id = v_window_id,
        ad_table_id = v_table_id,
        updated = NOW(),
        updatedby = 100
    WHERE ad_tab_id = v_tab_id AND name = 'Response required' AND ad_user_id IS NULL;
  END IF;

  -- Awaiting worker (saved, not default)
  IF NOT EXISTS (
    SELECT 1 FROM ad_userquery
    WHERE ad_tab_id = v_tab_id AND name = 'Awaiting worker' AND ad_user_id IS NULL
  ) THEN
    INSERT INTO ad_userquery (
      ad_userquery_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_user_id, ad_table_id, ad_tab_id, ad_window_id,
      ad_role_id, isdefault, code, ad_userquery_uu
    ) VALUES (
      (SELECT COALESCE(MAX(ad_userquery_id), 0) + 1 FROM ad_userquery),
      v_client_id, 0, 'Y',
      NOW(), 100, NOW(), 100,
      'Awaiting worker',
      'Chats waiting for the worker app to reply. Select from Lookup saved queries.',
      NULL, v_table_id, v_tab_id, v_window_id,
      NULL, 'N',
      '@SQL=R_Request.AbERP_ChatAwaitingReply=''Awaiting worker''',
      generate_uuid()
    );
  END IF;

  -- Closed (saved, not default)
  IF NOT EXISTS (
    SELECT 1 FROM ad_userquery
    WHERE ad_tab_id = v_tab_id AND name = 'Closed' AND ad_user_id IS NULL
  ) THEN
    INSERT INTO ad_userquery (
      ad_userquery_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_user_id, ad_table_id, ad_tab_id, ad_window_id,
      ad_role_id, isdefault, code, ad_userquery_uu
    ) VALUES (
      (SELECT COALESCE(MAX(ad_userquery_id), 0) + 1 FROM ad_userquery),
      v_client_id, 0, 'Y',
      NOW(), 100, NOW(), 100,
      'Closed',
      'Closed chats. Select from Lookup saved queries.',
      NULL, v_table_id, v_tab_id, v_window_id,
      NULL, 'N',
      '@SQL=R_Request.AbERP_ChatAwaitingReply=''Closed''',
      generate_uuid()
    );
  END IF;

  -- Only one default on this tab
  UPDATE ad_userquery
  SET isdefault = 'N', updated = NOW(), updatedby = 100
  WHERE ad_tab_id = v_tab_id
    AND isdefault = 'Y'
    AND name IS DISTINCT FROM 'Response required';
END $$;

SELECT 'buttons' AS c, f.name, f.xposition, f.columnspan, f.issameline
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname IN ('AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat')
ORDER BY f.seqno;

SELECT 'queries' AS c, name, isdefault, code
FROM ad_userquery
WHERE ad_tab_id = (SELECT t.ad_tab_id FROM ad_tab t JOIN ad_window w ON w.ad_window_id=t.ad_window_id
                   WHERE w.name='Rostering Chat' AND t.name='Chat')
ORDER BY isdefault DESC, name;

SELECT 'counts' AS c, aberp_chatawaitingreply, COUNT(*)::int
FROM r_request
WHERE r_requesttype_id = (SELECT r_requesttype_id FROM r_requesttype WHERE name = 'Rostering Chat' AND isactive = 'Y' ORDER BY 1 LIMIT 1)
  AND isactive = 'Y'
GROUP BY aberp_chatawaitingreply
ORDER BY 1;
