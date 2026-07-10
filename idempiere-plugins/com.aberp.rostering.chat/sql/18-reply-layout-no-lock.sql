SET search_path TO adempiere;

-- =============================================================================
-- Rostering Chat layout + Reply field (no optimistic-lock fights)
-- =============================================================================
-- Layout:
--   1. Worker | Status
--   2. Subject
--   3. Awaiting Reply | Last Activity
--   4. Last Message (read-only)
--   5. Reply (editable) — Save sends to Updates + app
--   6. Close Chat
--
-- Optimistic lock fix: never UPDATE r_request again from triggers while
-- touching Updated. Reply handling mutates NEW in a BEFORE trigger only.
-- =============================================================================

-- 1) Drop the LastResult compose trigger (caused lock conflicts)
DROP TRIGGER IF EXISTS aberp_rostering_chat_sync_lastresult_trg ON r_request;
DROP FUNCTION IF EXISTS aberp_rostering_chat_sync_lastresult();

-- 2) Reply → LastResult + clear draft on Save (BEFORE, mutate NEW only)
CREATE OR REPLACE FUNCTION aberp_rostering_chat_apply_reply()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_type_name TEXT;
  v_reply TEXT;
BEGIN
  SELECT rt.name INTO v_type_name
  FROM r_requesttype rt
  WHERE rt.r_requesttype_id = NEW.r_requesttype_id;

  IF v_type_name IS DISTINCT FROM 'Rostering Chat' THEN
    RETURN NEW;
  END IF;

  v_reply := NULLIF(btrim(COALESCE(NEW.aberp_rosteringreply, '')), '');
  IF v_reply IS NULL THEN
    RETURN NEW;
  END IF;

  -- Only act when Reply actually changed (or was newly set)
  IF TG_OP = 'UPDATE'
     AND OLD.aberp_rosteringreply IS NOT DISTINCT FROM NEW.aberp_rosteringreply THEN
    RETURN NEW;
  END IF;

  NEW.lastresult := LEFT(v_reply, 2000);
  NEW.aberp_rosteringreply := NULL;
  NEW.ad_role_id := 0;
  NEW.datelastaction := NOW();
  -- Do NOT override NEW.updated — WebUI owns optimistic lock

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS aberp_rostering_chat_apply_reply_trg ON r_request;
CREATE TRIGGER aberp_rostering_chat_apply_reply_trg
BEFORE INSERT OR UPDATE OF aberp_rosteringreply ON r_request
FOR EACH ROW
EXECUTE PROCEDURE aberp_rostering_chat_apply_reply();

-- 3) After Reply/LastResult changes, insert Updates row (no r_request.updated bump).
-- NOTE: must listen on aberp_rosteringreply too — PG "UPDATE OF lastresult" does not
-- fire when LastResult is only changed inside a BEFORE trigger.
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
      AND (
        u.created > NOW() - INTERVAL '15 seconds'
        OR u.r_requestupdate_id = (
          SELECT MAX(u2.r_requestupdate_id) FROM r_requestupdate u2
          WHERE u2.r_request_id = NEW.r_request_id
        )
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

DROP TRIGGER IF EXISTS aberp_rostering_chat_header_to_update_trg ON r_request;
CREATE TRIGGER aberp_rostering_chat_header_to_update_trg
AFTER INSERT OR UPDATE OF aberp_rosteringreply, lastresult ON r_request
FOR EACH ROW
EXECUTE PROCEDURE aberp_rostering_chat_insert_update_from_header();

-- 4) Updates → header sync: never bump Updated (avoids ReQuery fights)
CREATE OR REPLACE FUNCTION aberp_rostering_chat_sync_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_type_name TEXT;
  v_worker_id INTEGER;
  v_role_id INTEGER := 1000012;
BEGIN
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

  IF v_worker_id IS NOT NULL AND NEW.createdby = v_worker_id THEN
    UPDATE r_request
    SET lastresult = btrim(NEW.result),
        ad_role_id = v_role_id,
        datelastaction = NOW()
        -- intentionally omit updated/updatedby
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

-- 5) Field layout + flags
UPDATE ad_field f
SET isdisplayed = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Y'
      WHEN 'R_Status_ID' THEN 'Y'
      WHEN 'Summary' THEN 'Y'
      WHEN 'AbERP_ChatAwaitingReply' THEN 'Y'
      WHEN 'DateLastAction' THEN 'Y'
      WHEN 'LastResult' THEN 'Y'
      WHEN 'AbERP_RosteringReply' THEN 'Y'
      WHEN 'AbERP_CloseRosteringChat' THEN 'Y'
      WHEN 'AbERP_SendRosteringReply' THEN 'N'
      ELSE f.isdisplayed
    END,
    isreadonly = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'N'
      WHEN 'R_Status_ID' THEN 'N'
      WHEN 'Summary' THEN 'N'
      WHEN 'AbERP_ChatAwaitingReply' THEN 'Y'
      WHEN 'DateLastAction' THEN 'Y'
      WHEN 'LastResult' THEN 'Y'          -- read-only history
      WHEN 'AbERP_RosteringReply' THEN 'N' -- compose here
      WHEN 'AbERP_CloseRosteringChat' THEN 'N'
      ELSE f.isreadonly
    END,
    isupdateable = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Y'
      WHEN 'R_Status_ID' THEN 'Y'
      WHEN 'Summary' THEN 'Y'
      WHEN 'AbERP_RosteringReply' THEN 'Y'
      WHEN 'AbERP_CloseRosteringChat' THEN 'Y'
      WHEN 'LastResult' THEN 'N'
      ELSE COALESCE(f.isupdateable, 'N')
    END,
    issameline = CASE c.columnname
      WHEN 'R_Status_ID' THEN 'Y'          -- next to Worker
      WHEN 'DateLastAction' THEN 'Y'       -- next to Awaiting Reply
      WHEN 'AbERP_CloseRosteringChat' THEN 'N'
      ELSE 'N'
    END,
    xposition = CASE c.columnname
      WHEN 'AD_User_ID' THEN 1
      WHEN 'R_Status_ID' THEN 4
      WHEN 'Summary' THEN 1
      WHEN 'AbERP_ChatAwaitingReply' THEN 1
      WHEN 'DateLastAction' THEN 4
      WHEN 'LastResult' THEN 1
      WHEN 'AbERP_RosteringReply' THEN 1
      WHEN 'AbERP_CloseRosteringChat' THEN 1
      ELSE f.xposition
    END,
    columnspan = CASE c.columnname
      WHEN 'AD_User_ID' THEN 2
      WHEN 'R_Status_ID' THEN 2
      WHEN 'Summary' THEN 5
      WHEN 'AbERP_ChatAwaitingReply' THEN 2
      WHEN 'DateLastAction' THEN 2
      WHEN 'LastResult' THEN 5
      WHEN 'AbERP_RosteringReply' THEN 5
      WHEN 'AbERP_CloseRosteringChat' THEN 2
      ELSE f.columnspan
    END,
    numlines = CASE c.columnname
      WHEN 'Summary' THEN 2
      WHEN 'LastResult' THEN 3
      WHEN 'AbERP_RosteringReply' THEN 4
      ELSE 1
    END,
    seqno = CASE c.columnname
      WHEN 'AD_User_ID' THEN 10
      WHEN 'R_Status_ID' THEN 15
      WHEN 'Summary' THEN 20
      WHEN 'AbERP_ChatAwaitingReply' THEN 30
      WHEN 'DateLastAction' THEN 35
      WHEN 'LastResult' THEN 40
      WHEN 'AbERP_RosteringReply' THEN 50
      WHEN 'AbERP_CloseRosteringChat' THEN 60
      ELSE f.seqno
    END,
    name = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Worker'
      WHEN 'R_Status_ID' THEN 'Status'
      WHEN 'Summary' THEN 'Subject'
      WHEN 'AbERP_ChatAwaitingReply' THEN 'Awaiting Reply'
      WHEN 'DateLastAction' THEN 'Last Activity'
      WHEN 'LastResult' THEN 'Last Message'
      WHEN 'AbERP_RosteringReply' THEN 'Reply'
      WHEN 'AbERP_CloseRosteringChat' THEN 'Close Chat'
      ELSE f.name
    END,
    description = CASE c.columnname
      WHEN 'LastResult' THEN 'Latest message in this chat (read-only)'
      WHEN 'AbERP_RosteringReply' THEN 'Type your reply, then Save. It is sent to the worker app.'
      ELSE f.description
    END,
    displaylogic = CASE c.columnname
      WHEN 'AbERP_CloseRosteringChat' THEN NULL
      ELSE f.displaylogic
    END,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat';

-- Column flags
UPDATE ad_column c
SET isupdateable = 'Y', isalwaysupdateable = 'Y', updated = NOW(), updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id AND tb.tablename = 'R_Request'
  AND c.columnname IN ('AbERP_RosteringReply', 'R_Status_ID', 'AD_User_ID', 'Summary', 'AbERP_CloseRosteringChat');

UPDATE ad_column c
SET isupdateable = 'N', isalwaysupdateable = 'N', updated = NOW(), updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id AND tb.tablename = 'R_Request'
  AND c.columnname = 'LastResult';

-- Chat tab stays form + insertable
UPDATE ad_tab t
SET isreadonly = 'N', isinsertrecord = 'Y', issinglerow = 'Y',
    updated = NOW(), updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat';

SELECT 'layout' AS c, f.seqno, f.name, c.columnname, f.isdisplayed, f.isreadonly, f.issameline
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat' AND f.isdisplayed = 'Y'
ORDER BY f.seqno;

SELECT 'triggers' AS c, tgname FROM pg_trigger
WHERE tgname LIKE 'aberp_rostering_chat%'
ORDER BY 1;
