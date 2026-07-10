SET search_path TO adempiere;

-- =============================================================================
-- Officer reply UX: type in Last Message on Chat, Save → creates Updates row
-- (Updates tab remains visible history; Close via Status or Close Chat button)
-- =============================================================================

-- Show Last Message as editable compose field
UPDATE ad_field f
SET isreadonly = 'N',
    isupdateable = 'Y',
    isdisplayed = 'Y',
    name = 'Reply / Last Message',
    description = 'Type your reply here, then Save. It is sent to the worker app.',
    numlines = 4,
    columnspan = 5,
    seqno = 30,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname = 'LastResult';

UPDATE ad_column c
SET isupdateable = 'Y',
    isalwaysupdateable = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'R_Request'
  AND c.columnname = 'LastResult';

-- When officer changes LastResult on a Rostering Chat, insert Updates row + clear queue
CREATE OR REPLACE FUNCTION aberp_rostering_chat_sync_lastresult()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_type_name TEXT;
  v_next_id INTEGER;
BEGIN
  IF NEW.lastresult IS NULL OR btrim(NEW.lastresult) = '' THEN
    RETURN NEW;
  END IF;
  IF OLD.lastresult IS NOT DISTINCT FROM NEW.lastresult THEN
    RETURN NEW;
  END IF;

  SELECT rt.name INTO v_type_name
  FROM r_requesttype rt
  WHERE rt.r_requesttype_id = NEW.r_requesttype_id;

  IF v_type_name IS DISTINCT FROM 'Rostering Chat' THEN
    RETURN NEW;
  END IF;

  -- Avoid duplicate if an Updates row with same text was just inserted
  IF EXISTS (
    SELECT 1 FROM r_requestupdate u
    WHERE u.r_request_id = NEW.r_request_id
      AND btrim(u.result) = btrim(NEW.lastresult)
      AND u.created > NOW() - INTERVAL '5 seconds'
  ) THEN
    NEW.ad_role_id := 0;
    NEW.datelastaction := NOW();
    RETURN NEW;
  END IF;

  SELECT COALESCE(MAX(r_requestupdate_id), 0) + 1 INTO v_next_id FROM r_requestupdate;

  INSERT INTO r_requestupdate (
    r_requestupdate_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby,
    r_request_id, result, confidentialtypeentry
  ) VALUES (
    v_next_id, NEW.ad_client_id, NEW.ad_org_id, 'Y',
    NOW(), NEW.updatedby, NOW(), NEW.updatedby,
    NEW.r_request_id, btrim(NEW.lastresult), 'A'
  );

  UPDATE ad_sequence s
  SET currentnext = GREATEST(s.currentnext, v_next_id + COALESCE(s.incrementno, 1))
  WHERE s.name = 'R_RequestUpdate';

  NEW.ad_role_id := 0;
  NEW.datelastaction := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS aberp_rostering_chat_sync_lastresult_trg ON r_request;
CREATE TRIGGER aberp_rostering_chat_sync_lastresult_trg
BEFORE UPDATE OF lastresult ON r_request
FOR EACH ROW
EXECUTE PROCEDURE aberp_rostering_chat_sync_lastresult();

-- Keep Close Chat visible + Status editable
UPDATE ad_field f
SET isdisplayed = 'Y', isreadonly = 'N', isupdateable = 'Y', displaylogic = NULL,
    updated = NOW(), updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname IN ('AbERP_CloseRosteringChat', 'R_Status_ID', 'AD_User_ID', 'Summary');

SELECT 'lastresult_field' AS c, f.name, f.isreadonly, f.isupdateable, f.isdisplayed
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name='Rostering Chat' AND t.name='Chat' AND c.columnname='LastResult';

SELECT 'triggers' AS c, tgname FROM pg_trigger
WHERE tgname LIKE 'aberp_rostering_chat%';
