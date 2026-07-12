SET search_path TO adempiere;

-- =============================================================================
-- Rostering Chat: Send button, clearer Awaiting labels, no Status, no lock fights
-- =============================================================================
-- Layout:
--   Worker
--   Subject
--   Awaiting Reply | Last Activity
--   Last Message (read-only)
--   Reply
--   Send Reply  (button — primary send path)
--   Close Chat
--
-- Awaiting Reply:
--   AD_Role_ID=1000012 → "Response required"  (rostering must reply)
--   else open           → "Awaiting worker"
--   Closed              → "Closed"
-- =============================================================================

-- 1) Clearer awaiting label (virtual column)
UPDATE ad_column
SET columnsql = '(SELECT CASE
      WHEN R_Request.R_Status_ID = 102 THEN ''Closed''
      WHEN COALESCE(R_Request.AD_Role_ID, 0) = 1000012 THEN ''Response required''
      ELSE ''Awaiting worker''
    END)',
    updated = NOW(),
    updatedby = 100
WHERE columnname = 'AbERP_ChatAwaitingReply'
  AND ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'R_Request');

-- 2) Sync-from-Updates must NEVER run nested under header→update insert
--    (depth>1 already), and must never touch updated/updatedby.
CREATE OR REPLACE FUNCTION aberp_rostering_chat_sync_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_type_name TEXT;
  v_worker_id INTEGER;
  v_role_id INTEGER := 1000012;
BEGIN
  -- Skip when nested (e.g. header trigger just inserted this update)
  IF pg_trigger_depth() > 1 THEN
    RETURN NEW;
  END IF;

  SELECT rt.name, r.ad_user_id
    INTO v_type_name, v_worker_id
  FROM r_request r
  JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
  WHERE r.r_request_id = NEW.r_request_id;

  IF v_type_name IS DISTINCT FROM 'Rostering Chat' THEN
    RETURN NEW;
  END IF;

  IF NEW.result IS NULL OR btrim(NEW.result) = '' THEN
    RETURN NEW;
  END IF;

  -- Only Public entries drive the header (ignore Confidential duplicates)
  IF COALESCE(NEW.confidentialtypeentry, 'A') = 'C' THEN
    RETURN NEW;
  END IF;

  IF v_worker_id IS NOT NULL AND NEW.createdby = v_worker_id THEN
    UPDATE r_request
    SET lastresult = btrim(NEW.result),
        ad_role_id = v_role_id,
        datelastaction = NOW()
        -- do NOT set updated/updatedby (WebUI optimistic lock)
    WHERE r_request_id = NEW.r_request_id
      AND (
        lastresult IS DISTINCT FROM btrim(NEW.result)
        OR COALESCE(ad_role_id, 0) IS DISTINCT FROM v_role_id
      );
  ELSE
    UPDATE r_request
    SET lastresult = btrim(NEW.result),
        ad_role_id = 0,
        datelastaction = NOW()
    WHERE r_request_id = NEW.r_request_id
      AND (
        lastresult IS DISTINCT FROM btrim(NEW.result)
        OR COALESCE(ad_role_id, 0) <> 0
      );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS aberp_rostering_chat_sync_update_trg ON r_requestupdate;
CREATE TRIGGER aberp_rostering_chat_sync_update_trg
AFTER INSERT OR UPDATE OF result ON r_requestupdate
FOR EACH ROW
EXECUTE PROCEDURE aberp_rostering_chat_sync_update();

-- 3) Header→Updates insert: Public only; skip if identical latest already exists
CREATE OR REPLACE FUNCTION aberp_rostering_chat_insert_update_from_header()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_type_name TEXT;
  v_next_id INTEGER;
BEGIN
  IF pg_trigger_depth() > 1 THEN
    RETURN NEW;
  END IF;

  IF NEW.lastresult IS NULL OR btrim(NEW.lastresult) = '' THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE'
     AND OLD.lastresult IS NOT DISTINCT FROM NEW.lastresult
     AND (
       NEW.aberp_rosteringreply IS NOT DISTINCT FROM OLD.aberp_rosteringreply
       OR NEW.aberp_rosteringreply IS NOT NULL
     ) THEN
    RETURN NEW;
  END IF;

  SELECT rt.name INTO v_type_name
  FROM r_requesttype rt
  WHERE rt.r_requesttype_id = NEW.r_requesttype_id;

  IF v_type_name IS DISTINCT FROM 'Rostering Chat' THEN
    RETURN NEW;
  END IF;

  IF EXISTS (
    SELECT 1 FROM r_requestupdate u
    WHERE u.r_request_id = NEW.r_request_id
      AND btrim(u.result) = btrim(NEW.lastresult)
      AND COALESCE(u.confidentialtypeentry, 'A') = 'A'
      AND u.created > NOW() - INTERVAL '30 seconds'
  ) THEN
    RETURN NEW;
  END IF;

  IF EXISTS (
    SELECT 1 FROM r_requestupdate u
    WHERE u.r_request_id = NEW.r_request_id
      AND btrim(u.result) = btrim(NEW.lastresult)
      AND COALESCE(u.confidentialtypeentry, 'A') = 'A'
      AND u.r_requestupdate_id = (
        SELECT MAX(u2.r_requestupdate_id) FROM r_requestupdate u2
        WHERE u2.r_request_id = NEW.r_request_id
          AND COALESCE(u2.confidentialtypeentry, 'A') = 'A'
      )
  ) THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(MAX(r_requestupdate_id), 0) + 1 INTO v_next_id FROM r_requestupdate;

  INSERT INTO r_requestupdate (
    r_requestupdate_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby,
    r_request_id, result, confidentialtypeentry
  ) VALUES (
    v_next_id, NEW.ad_client_id, COALESCE(NEW.ad_org_id, 0), 'Y',
    NOW(), COALESCE(NEW.updatedby, 100), NOW(), COALESCE(NEW.updatedby, 100),
    NEW.r_request_id, btrim(NEW.lastresult), 'A'
  );

  UPDATE ad_sequence s
  SET currentnext = GREATEST(s.currentnext, v_next_id + COALESCE(s.incrementno, 1))
  WHERE s.name = 'R_RequestUpdate';

  RETURN NEW;
END;
$$;

-- 4) Field layout: hide Status, show Send Reply
UPDATE ad_field f
SET isdisplayed = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Y'
      WHEN 'R_Status_ID' THEN 'N'                 -- hide Status
      WHEN 'Summary' THEN 'Y'
      WHEN 'AbERP_ChatAwaitingReply' THEN 'Y'
      WHEN 'DateLastAction' THEN 'Y'
      WHEN 'LastResult' THEN 'Y'
      WHEN 'AbERP_RosteringReply' THEN 'Y'
      WHEN 'AbERP_SendRosteringReply' THEN 'Y'    -- Send Reply button
      WHEN 'AbERP_CloseRosteringChat' THEN 'Y'
      ELSE f.isdisplayed
    END,
    isreadonly = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'N'
      WHEN 'Summary' THEN 'N'
      WHEN 'AbERP_ChatAwaitingReply' THEN 'Y'
      WHEN 'DateLastAction' THEN 'Y'
      WHEN 'LastResult' THEN 'Y'
      WHEN 'AbERP_RosteringReply' THEN 'N'
      WHEN 'AbERP_SendRosteringReply' THEN 'N'
      WHEN 'AbERP_CloseRosteringChat' THEN 'N'
      ELSE f.isreadonly
    END,
    isupdateable = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Y'
      WHEN 'Summary' THEN 'Y'
      WHEN 'AbERP_RosteringReply' THEN 'Y'
      WHEN 'AbERP_SendRosteringReply' THEN 'Y'
      WHEN 'AbERP_CloseRosteringChat' THEN 'Y'
      WHEN 'LastResult' THEN 'N'
      ELSE COALESCE(f.isupdateable, 'N')
    END,
    issameline = CASE c.columnname
      WHEN 'DateLastAction' THEN 'Y'              -- next to Awaiting Reply
      WHEN 'AbERP_SendRosteringReply' THEN 'Y'    -- next to Reply / before Close
      ELSE 'N'
    END,
    seqno = CASE c.columnname
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
    name = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Worker'
      WHEN 'Summary' THEN 'Subject'
      WHEN 'AbERP_ChatAwaitingReply' THEN 'Awaiting Reply'
      WHEN 'DateLastAction' THEN 'Last Activity'
      WHEN 'LastResult' THEN 'Last Message'
      WHEN 'AbERP_RosteringReply' THEN 'Reply'
      WHEN 'AbERP_SendRosteringReply' THEN 'Send Reply'
      WHEN 'AbERP_CloseRosteringChat' THEN 'Close Chat'
      ELSE f.name
    END,
    description = CASE c.columnname
      WHEN 'AbERP_ChatAwaitingReply' THEN 'Response required = waiting for rostering; Awaiting worker = waiting for the app'
      WHEN 'LastResult' THEN 'Latest message (read-only)'
      WHEN 'AbERP_RosteringReply' THEN 'Type your reply, then click Send Reply'
      WHEN 'AbERP_SendRosteringReply' THEN 'Send the Reply text to the worker app'
      ELSE f.description
    END,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat';

-- Send / Close buttons must be updateable
UPDATE ad_column c
SET isupdateable = 'Y', isalwaysupdateable = 'Y', updated = NOW(), updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id AND tb.tablename = 'R_Request'
  AND c.columnname IN ('AbERP_RosteringReply', 'AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat');

UPDATE ad_element
SET name = 'Send Reply', printname = 'Send Reply', updated = NOW(), updatedby = 100
WHERE columnname = 'AbERP_SendRosteringReply';

UPDATE ad_process
SET showhelp = 'N',
    name = 'Send Reply',
    description = 'Send the Reply field to the worker app',
    help = 'Type in Reply, then click Send Reply.',
    updated = NOW(),
    updatedby = 100
WHERE value = 'AbERP_RosteringChat_Send';

-- Process params: pull Reply from field, request from context
UPDATE ad_process_para pp
SET defaultvalue = CASE pp.columnname
      WHEN 'Reply' THEN '@AbERP_RosteringReply@'
      WHEN 'AbERP_RosteringReply' THEN '@AbERP_RosteringReply@'
      WHEN 'R_Request_ID' THEN '@R_Request_ID@'
      ELSE pp.defaultvalue
    END,
    isactive = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_process p
WHERE pp.ad_process_id = p.ad_process_id
  AND p.value = 'AbERP_RosteringChat_Send'
  AND pp.columnname IN ('Reply', 'AbERP_RosteringReply', 'R_Request_ID');

-- 5) Updates tab: time order + Public only (hide Confidential duplicates)
UPDATE ad_tab t
SET orderbyclause = 'R_RequestUpdate.Created ASC, R_RequestUpdate.R_RequestUpdate_ID ASC',
    whereclause = 'R_RequestUpdate.R_Request_ID=@R_Request_ID@ AND COALESCE(R_RequestUpdate.ConfidentialTypeEntry,''A'')<>''C''',
    isreadonly = 'Y',
    isinsertrecord = 'N',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Updates';

-- 6) Deactivate Confidential duplicate updates on Rostering Chat threads
UPDATE r_requestupdate u
SET isactive = 'N',
    updated = NOW(),
    updatedby = 100
FROM r_request r
JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
WHERE u.r_request_id = r.r_request_id
  AND rt.name = 'Rostering Chat'
  AND COALESCE(u.confidentialtypeentry, 'A') = 'C'
  AND u.isactive = 'Y';

-- 7) Open thread 1000097 for testing (awaiting rostering)
UPDATE r_request
SET r_status_id = 1000000,
    ad_role_id = 1000012,
    processed = 'N',
    aberp_rosteringreply = NULL,
    updated = NOW(),
    updatedby = 100
WHERE r_request_id = 1000097;

-- Align lastresult to latest Public update
UPDATE r_request r
SET lastresult = u.result,
    datelastaction = u.created
FROM (
  SELECT DISTINCT ON (r_request_id)
    r_request_id, result, created
  FROM r_requestupdate
  WHERE r_request_id = 1000097
    AND isactive = 'Y'
    AND COALESCE(confidentialtypeentry, 'A') = 'A'
  ORDER BY r_request_id, created DESC, r_requestupdate_id DESC
) u
WHERE r.r_request_id = u.r_request_id;

SELECT 'layout' AS c, f.seqno, f.name, c.columnname, f.isdisplayed, f.isreadonly, f.issameline
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat' AND f.isdisplayed = 'Y'
ORDER BY f.seqno;

SELECT 'awaiting' AS c, columnsql
FROM ad_column
WHERE columnname = 'AbERP_ChatAwaitingReply'
  AND ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'R_Request');

SELECT '1000097' AS c, r_request_id, LEFT(lastresult,60), ad_role_id,
  (SELECT CASE WHEN r_status_id=102 THEN 'Closed'
        WHEN COALESCE(ad_role_id,0)=1000012 THEN 'Response required'
        ELSE 'Awaiting worker' END)
FROM r_request WHERE r_request_id = 1000097;

SELECT 'msgs' AS c, r_requestupdate_id, LEFT(result,40), created, confidentialtypeentry, isactive
FROM r_requestupdate WHERE r_request_id = 1000097
ORDER BY created ASC, r_requestupdate_id ASC;
