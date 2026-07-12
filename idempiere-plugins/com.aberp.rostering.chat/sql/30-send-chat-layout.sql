SET search_path TO adempiere, public;

-- =============================================================================
-- Rostering Chat UX polish:
--   - Button: Send Reply → Send Chat
--   - Close Chat on the same line as Send Chat
--   - Subject default: Rostering Chat (was Message to Rostering)
--   - Tighter field sizes for Subject / Last Message / Reply
-- =============================================================================

-- 1) Field layout + names + sizes
UPDATE ad_field f
SET seqno = CASE c.columnname
      WHEN 'AD_User_ID' THEN 10
      WHEN 'Summary' THEN 20
      WHEN 'AbERP_ChatAwaitingReply' THEN 30
      WHEN 'DateLastAction' THEN 35
      WHEN 'LastResult' THEN 40
      WHEN 'AbERP_RosteringReply' THEN 50
      WHEN 'AbERP_SendRosteringReply' THEN 55
      WHEN 'AbERP_CloseRosteringChat' THEN 60
      ELSE f.seqno
    END,
    issameline = CASE c.columnname
      WHEN 'DateLastAction' THEN 'Y'
      WHEN 'AbERP_CloseRosteringChat' THEN 'Y'  -- next to Send Chat
      ELSE 'N'
    END,
    name = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Worker'
      WHEN 'Summary' THEN 'Subject'
      WHEN 'AbERP_ChatAwaitingReply' THEN 'Chat Assigned'
      WHEN 'DateLastAction' THEN 'Last Activity'
      WHEN 'LastResult' THEN 'Last Message'
      WHEN 'AbERP_RosteringReply' THEN 'Reply'
      WHEN 'AbERP_SendRosteringReply' THEN 'Send Chat'
      WHEN 'AbERP_CloseRosteringChat' THEN 'Close Chat'
      ELSE f.name
    END,
    description = CASE c.columnname
      WHEN 'AbERP_RosteringReply' THEN 'Type your message, then click Send Chat'
      WHEN 'AbERP_SendRosteringReply' THEN 'Send the Reply text to the worker app'
      WHEN 'AbERP_CloseRosteringChat' THEN 'Close this chat so the worker can start a new conversation'
      ELSE f.description
    END,
    displaylength = CASE c.columnname
      WHEN 'Summary' THEN 30
      WHEN 'AbERP_ChatAwaitingReply' THEN 20
      WHEN 'DateLastAction' THEN 20
      WHEN 'LastResult' THEN 40
      WHEN 'AbERP_RosteringReply' THEN 40
      WHEN 'AbERP_SendRosteringReply' THEN 12
      WHEN 'AbERP_CloseRosteringChat' THEN 12
      ELSE f.displaylength
    END,
    columnspan = CASE c.columnname
      WHEN 'AD_User_ID' THEN 2
      WHEN 'Summary' THEN 2
      WHEN 'AbERP_ChatAwaitingReply' THEN 2
      WHEN 'DateLastAction' THEN 2
      WHEN 'LastResult' THEN 5
      WHEN 'AbERP_RosteringReply' THEN 5
      WHEN 'AbERP_SendRosteringReply' THEN 1
      WHEN 'AbERP_CloseRosteringChat' THEN 1
      ELSE COALESCE(f.columnspan, 1)
    END,
    numlines = CASE c.columnname
      WHEN 'Summary' THEN 1
      WHEN 'LastResult' THEN 1
      WHEN 'AbERP_RosteringReply' THEN 2
      ELSE 1
    END,
    xposition = CASE c.columnname
      WHEN 'DateLastAction' THEN 4
      WHEN 'AbERP_SendRosteringReply' THEN 2
      WHEN 'AbERP_CloseRosteringChat' THEN 3
      ELSE 1
    END,
    isdisplayed = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND c.columnname IN (
    'AD_User_ID', 'Summary', 'AbERP_ChatAwaitingReply', 'DateLastAction',
    'LastResult', 'AbERP_RosteringReply',
    'AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat'
  );

-- Keep buttons visible
UPDATE ad_field f
SET displaylogic = NULL, updated = NOW(), updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname IN ('AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat');

-- 2) AD element / process labels
UPDATE ad_element
SET name = 'Send Chat',
    printname = 'Send Chat',
    description = 'Send the Reply text to the worker app',
    updated = NOW(),
    updatedby = 100
WHERE columnname = 'AbERP_SendRosteringReply';

UPDATE ad_process
SET name = 'Send Chat',
    description = 'Send the Reply field to the worker app',
    help = 'Type your message in Reply, then click Send Chat.',
    updated = NOW(),
    updatedby = 100
WHERE value = 'AbERP_RosteringChat_Send';

UPDATE ad_column
SET name = 'Send Chat',
    updated = NOW(),
    updatedby = 100
WHERE columnname = 'AbERP_SendRosteringReply'
  AND ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'R_Request');

-- 3) Subject default → Rostering Chat
UPDATE ad_column
SET defaultvalue = '''Rostering Chat''',
    updated = NOW(),
    updatedby = 100
WHERE columnname = 'Summary'
  AND ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'R_Request')
  AND EXISTS (
    SELECT 1 FROM ad_field f
    JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
    JOIN ad_window w ON w.ad_window_id = t.ad_window_id
    WHERE f.ad_column_id = ad_column.ad_column_id
      AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  );

UPDATE ad_field f
SET defaultvalue = '''Rostering Chat''',
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname = 'Summary';

-- Prefer window-level default via AD (officer create path also uses column default)
UPDATE ad_column c
SET defaultvalue = '''Rostering Chat'''
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'R_Request'
  AND c.columnname = 'Summary'
  AND c.defaultvalue IN ('''Message to Rostering''', 'Message to Rostering');

-- Backfill existing Rostering Chat subjects
UPDATE r_request r
SET summary = 'Rostering Chat',
    updated = NOW(),
    updatedby = 100
FROM r_requesttype rt
WHERE r.r_requesttype_id = rt.r_requesttype_id
  AND rt.name = 'Rostering Chat'
  AND btrim(COALESCE(r.summary, '')) IN ('Message to Rostering', '');

-- 4) Trigger fallback text when Summary blank
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

  IF NEW.summary IS NULL OR btrim(NEW.summary) = '' THEN
    NEW.summary := 'Rostering Chat';
  END IF;

  IF (NEW.lastresult IS NULL OR btrim(NEW.lastresult) = '')
     AND (NEW.aberp_rosteringreply IS NULL OR btrim(COALESCE(NEW.aberp_rosteringreply, '')) = '')
     AND TG_OP = 'UPDATE'
     AND OLD.lastresult IS NOT NULL AND btrim(OLD.lastresult) <> '' THEN
    NEW.lastresult := OLD.lastresult;
  END IF;

  IF TG_OP = 'INSERT' THEN
    IF NEW.lastresult IS NULL OR btrim(NEW.lastresult) = '' THEN
      NEW.lastresult := 'Hello — rostering would like to get in touch with you.';
    END IF;
    NEW.datelastaction := COALESCE(NEW.datelastaction, NOW());

    IF COALESCE(NEW.ad_role_id, 0) = 1000012
       AND NEW.createdby IS DISTINCT FROM NEW.ad_user_id THEN
      NEW.ad_role_id := NULL;
    END IF;
  END IF;

  NEW.aberp_chatawaitingreply := aberp_rostering_chat_assigned_text(
    NEW.r_status_id,
    NEW.ad_role_id
  );

  RETURN NEW;
END;
$$;

SELECT 'layout' AS c, f.seqno, f.name, f.issameline, f.displaylength, f.columnspan, f.numlines, c.columnname
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat' AND f.isdisplayed = 'Y'
ORDER BY f.seqno;

SELECT 'subject_sample' AS c, r_request_id, summary, aberp_chatawaitingreply
FROM r_request
WHERE r_requesttype_id = (SELECT r_requesttype_id FROM r_requesttype WHERE name = 'Rostering Chat' LIMIT 1)
ORDER BY coalesce(datelastaction, updated) DESC
LIMIT 5;
