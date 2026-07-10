SET search_path TO adempiere;

-- =============================================================================
-- Rostering Chat: only latest Public update drives Last Message; never lock bump
-- =============================================================================

CREATE OR REPLACE FUNCTION aberp_rostering_chat_sync_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_type_name TEXT;
  v_worker_id INTEGER;
  v_role_id INTEGER := 1000012;
  v_is_latest BOOLEAN;
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

  -- Only the chronologically latest Public message may rewrite Last Message
  SELECT NOT EXISTS (
    SELECT 1
    FROM r_requestupdate u
    WHERE u.r_request_id = NEW.r_request_id
      AND u.isactive = 'Y'
      AND COALESCE(u.confidentialtypeentry, 'A') = 'A'
      AND u.r_requestupdate_id <> NEW.r_requestupdate_id
      AND (
        u.created > NEW.created
        OR (u.created = NEW.created AND u.r_requestupdate_id > NEW.r_requestupdate_id)
      )
  ) INTO v_is_latest;

  IF NOT v_is_latest THEN
    RETURN NEW;
  END IF;

  IF v_worker_id IS NOT NULL AND NEW.createdby = v_worker_id THEN
    UPDATE r_request
    SET lastresult = btrim(NEW.result),
        ad_role_id = v_role_id,
        datelastaction = NEW.created
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
        datelastaction = NEW.created
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

-- Align all open Rostering Chat headers to latest Public update (no updated bump)
UPDATE r_request r
SET lastresult = u.result,
    datelastaction = u.created,
    ad_role_id = CASE
      WHEN r.r_status_id = 102 THEN 0
      WHEN u.createdby = r.ad_user_id THEN 1000012
      ELSE 0
    END
FROM (
  SELECT DISTINCT ON (ru.r_request_id)
    ru.r_request_id,
    ru.result,
    ru.created,
    ru.createdby
  FROM r_requestupdate ru
  WHERE ru.isactive = 'Y'
    AND COALESCE(ru.confidentialtypeentry, 'A') = 'A'
  ORDER BY ru.r_request_id, ru.created DESC, ru.r_requestupdate_id DESC
) u
JOIN r_requesttype rt ON rt.r_requesttype_id = (
  SELECT r2.r_requesttype_id FROM r_request r2 WHERE r2.r_request_id = u.r_request_id
)
WHERE r.r_request_id = u.r_request_id
  AND rt.name = 'Rostering Chat'
  AND r.isactive = 'Y'
  AND (
    r.lastresult IS DISTINCT FROM u.result
    OR r.datelastaction IS DISTINCT FROM u.created
  );

SELECT '1000098' AS c, r_request_id, LEFT(lastresult,80) AS last_message, ad_role_id,
       updated, updatedby, datelastaction
FROM r_request WHERE r_request_id = 1000098;

SELECT 'msgs' AS c, r_requestupdate_id, LEFT(result,40), createdby, created
FROM r_requestupdate
WHERE r_request_id = 1000098 AND isactive = 'Y'
ORDER BY created ASC, r_requestupdate_id ASC;
