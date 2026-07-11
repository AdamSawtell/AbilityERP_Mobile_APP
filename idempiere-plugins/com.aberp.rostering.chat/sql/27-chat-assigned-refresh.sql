SET search_path TO adempiere, public;

-- =============================================================================
-- Chat Assigned (was Awaiting Reply):
--   1) Rename field
--   2) Store value in a real column so it refreshes when navigating records
--   3) Fix officer-create trigger that was clearing the rostering queue on
--      worker-started chats (broke "Response required" / worker↔officer flow)
-- =============================================================================

-- Physical column (virtual columnsql does not refresh reliably on record nav)
ALTER TABLE r_request
  ADD COLUMN IF NOT EXISTS aberp_chatawaitingreply VARCHAR(60);

-- AD: stop treating it as virtual SQL; make it a normal read-only field
UPDATE ad_column
SET columnsql = NULL,
    ad_reference_id = 10,
    fieldlength = 60,
    isupdateable = 'N',
    isalwaysupdateable = 'N',
    updated = NOW(),
    updatedby = 100
WHERE columnname = 'AbERP_ChatAwaitingReply'
  AND ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'R_Request');

UPDATE ad_field f
SET name = 'Chat Assigned',
    description = 'Who the chat is waiting on',
    help = 'Closed = done. Response required = waiting for rostering. Awaiting worker = waiting for the app.',
    isdisplayed = 'Y',
    isreadonly = 'Y',
    isupdateable = 'N',
    seqno = 30,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND c.columnname = 'AbERP_ChatAwaitingReply';

UPDATE ad_element
SET name = 'Chat Assigned',
    printname = 'Chat Assigned',
    description = 'Who the chat is waiting on',
    updated = NOW(),
    updatedby = 100
WHERE columnname = 'AbERP_ChatAwaitingReply';

-- Compute + maintain Chat Assigned; fix officer vs worker create queue
CREATE OR REPLACE FUNCTION aberp_rostering_chat_assigned_text(
  p_status_id NUMERIC,
  p_role_id NUMERIC
) RETURNS VARCHAR
LANGUAGE sql
STABLE
AS $$
  SELECT CASE
    WHEN COALESCE((SELECT s.isclosed FROM r_status s WHERE s.r_status_id = p_status_id), 'N') = 'Y'
      THEN 'Closed'
    WHEN COALESCE(p_role_id, 0) = 1000012
      THEN 'Response required'
    ELSE 'Awaiting worker'
  END;
$$;

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

  -- Stamp worker BP so PWA can find the thread
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

  -- Always keep Summary non-null (Send Reply saves the row first; empty Subject
  -- in the form would otherwise fail with NOT NULL on r_request.summary).
  IF NEW.summary IS NULL OR btrim(NEW.summary) = '' THEN
    NEW.summary := 'Message to Rostering';
  END IF;

  -- Do not let a blank Last Message field wipe the real transcript on save.
  -- apply_reply sets lastresult from Reply in the same BEFORE cycle when sending.
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

    -- ONLY clear rostering queue when an officer creates the chat for a worker.
    -- Worker-app creates set createdby = worker (= ad_user_id) and MUST keep 1000012.
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

-- Fire on ANY update so Chat Assigned stays in sync when Reply/Send clears
-- the queue (apply_reply mutates ad_role_id/lastresult on UPDATE OF reply only —
-- column-specific triggers would miss that and leave a stale label).
DROP TRIGGER IF EXISTS aberp_rostering_chat_before_save_trg ON r_request;
CREATE TRIGGER aberp_rostering_chat_before_save_trg
BEFORE INSERT OR UPDATE
ON r_request
FOR EACH ROW
EXECUTE FUNCTION aberp_rostering_chat_before_save();

-- Backfill Chat Assigned + repair worker-started open chats wrongly de-queued
UPDATE r_request r
SET aberp_chatawaitingreply = aberp_rostering_chat_assigned_text(r.r_status_id, r.ad_role_id)
FROM r_requesttype rt
WHERE r.r_requesttype_id = rt.r_requesttype_id
  AND rt.name = 'Rostering Chat';

-- Open threads created by the worker that lost queue 1000012 because of the bad trigger
UPDATE r_request r
SET ad_role_id = 1000012,
    aberp_chatawaitingreply = 'Response required',
    updated = NOW(),
    updatedby = 100
FROM r_requesttype rt, r_status rs
WHERE r.r_requesttype_id = rt.r_requesttype_id
  AND rt.name = 'Rostering Chat'
  AND rs.r_status_id = r.r_status_id
  AND COALESCE(rs.isclosed, 'N') <> 'Y'
  AND COALESCE(r.ad_role_id, 0) = 0
  AND r.createdby = r.ad_user_id
  AND r.isactive = 'Y';

-- Subject must stay populated; make it read-only so Send Reply save cannot null it
UPDATE ad_field f
SET isreadonly = 'Y',
    isupdateable = 'N',
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND c.columnname IN ('Summary', 'LastResult');

-- Recompute after repair
UPDATE r_request r
SET aberp_chatawaitingreply = aberp_rostering_chat_assigned_text(r.r_status_id, r.ad_role_id)
FROM r_requesttype rt
WHERE r.r_requesttype_id = rt.r_requesttype_id
  AND rt.name = 'Rostering Chat';

SELECT 'field' AS c, f.name, f.isdisplayed, f.isreadonly
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND c.columnname = 'AbERP_ChatAwaitingReply';

SELECT 'col' AS c, columnname, columnsql IS NULL AS not_virtual, fieldlength
FROM ad_column
WHERE columnname = 'AbERP_ChatAwaitingReply';

SELECT 'sample' AS c, r_request_id, ad_role_id, r_status_id, aberp_chatawaitingreply, createdby, ad_user_id
FROM r_request
WHERE r_requesttype_id = (SELECT r_requesttype_id FROM r_requesttype WHERE name = 'Rostering Chat' LIMIT 1)
ORDER BY coalesce(datelastaction, updated) DESC
LIMIT 8;
