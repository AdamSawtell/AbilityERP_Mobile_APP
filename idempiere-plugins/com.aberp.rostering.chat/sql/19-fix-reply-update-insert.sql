SET search_path TO adempiere;

-- AFTER must fire on Reply column updates (BEFORE copies Reply → LastResult;
-- PostgreSQL "UPDATE OF lastresult" does NOT fire when only Reply was in SET)
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

  -- Fire when lastresult changed, or Reply was consumed into lastresult
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
      AND u.created > NOW() - INTERVAL '15 seconds'
  ) THEN
    RETURN NEW;
  END IF;

  -- Also skip if identical message already exists as latest update
  IF EXISTS (
    SELECT 1 FROM r_requestupdate u
    WHERE u.r_request_id = NEW.r_request_id
      AND btrim(u.result) = btrim(NEW.lastresult)
      AND u.r_requestupdate_id = (
        SELECT MAX(u2.r_requestupdate_id) FROM r_requestupdate u2
        WHERE u2.r_request_id = NEW.r_request_id
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

-- Retest reply on 1000096 (re-open first)
UPDATE r_request
SET r_status_id = 1000000,
    ad_role_id = 1000012,
    aberp_rosteringreply = NULL,
    updated = NOW(),
    updatedby = 100
WHERE r_request_id = 1000096;

UPDATE r_request
SET aberp_rosteringreply = 'Layout test reply 2 — ' || to_char(NOW(),'HH24:MI:SS'),
    updated = NOW(),
    updatedby = 100
WHERE r_request_id = 1000096;

SELECT r_request_id, LEFT(lastresult,80) AS last_message, aberp_rosteringreply AS reply_draft, ad_role_id
FROM r_request WHERE r_request_id = 1000096;

SELECT r_requestupdate_id, LEFT(result,80) AS result, created
FROM r_requestupdate WHERE r_request_id = 1000096
ORDER BY created DESC LIMIT 5;

-- Close via status
UPDATE r_request
SET r_status_id = 102, ad_role_id = 0, updated = NOW(), updatedby = 100
WHERE r_request_id = 1000096;

SELECT r.r_request_id, r.r_status_id, s.name AS status, s.isclosed
FROM r_request r JOIN r_status s ON s.r_status_id = r.r_status_id
WHERE r.r_request_id = 1000096;
