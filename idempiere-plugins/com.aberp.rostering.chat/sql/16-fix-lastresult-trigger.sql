SET search_path TO adempiere;

CREATE OR REPLACE FUNCTION aberp_rostering_chat_sync_lastresult()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_type_name TEXT;
  v_next_id INTEGER;
BEGIN
  -- Ignore nested updates from the Updates sync trigger
  IF pg_trigger_depth() > 1 THEN
    RETURN NEW;
  END IF;

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

  IF EXISTS (
    SELECT 1 FROM r_requestupdate u
    WHERE u.r_request_id = NEW.r_request_id
      AND btrim(u.result) = btrim(NEW.lastresult)
      AND u.created > NOW() - INTERVAL '10 seconds'
  ) THEN
    UPDATE r_request
    SET ad_role_id = 0,
        datelastaction = NOW()
    WHERE r_request_id = NEW.r_request_id
      AND COALESCE(ad_role_id, 0) <> 0;
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

  -- Clear officer queue without touching lastresult (avoids re-entry)
  UPDATE r_request
  SET ad_role_id = 0,
      datelastaction = NOW()
  WHERE r_request_id = NEW.r_request_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS aberp_rostering_chat_sync_lastresult_trg ON r_request;
CREATE TRIGGER aberp_rostering_chat_sync_lastresult_trg
AFTER UPDATE OF lastresult ON r_request
FOR EACH ROW
EXECUTE PROCEDURE aberp_rostering_chat_sync_lastresult();

-- Also harden Updates sync so it does not rewrite lastresult when unchanged
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
        datelastaction = NOW(),
        updated = NOW(),
        updatedby = NEW.createdby
    WHERE r_request_id = NEW.r_request_id
      AND (
        lastresult IS DISTINCT FROM btrim(NEW.result)
        OR COALESCE(ad_role_id, 0) IS DISTINCT FROM v_role_id
      );
  ELSE
    UPDATE r_request
    SET lastresult = btrim(NEW.result),
        ad_role_id = 0,
        datelastaction = NOW(),
        updated = NOW(),
        updatedby = NEW.createdby
    WHERE r_request_id = NEW.r_request_id
      AND (
        lastresult IS DISTINCT FROM btrim(NEW.result)
        OR COALESCE(ad_role_id, 0) <> 0
      );
  END IF;

  RETURN NEW;
END;
$$;

-- Retest
UPDATE r_request
SET lastresult = 'Officer reply via Last Message save — ' || to_char(NOW(),'HH24:MI:SS'),
    updated = NOW(),
    updatedby = 100
WHERE r_request_id = 1000095;

SELECT r_requestupdate_id, LEFT(result,80) AS result, created
FROM r_requestupdate WHERE r_request_id = 1000095
ORDER BY created DESC LIMIT 4;

SELECT r_request_id, LEFT(lastresult,80) AS lastresult, ad_role_id
FROM r_request WHERE r_request_id = 1000095;
