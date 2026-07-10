SET search_path TO adempiere;

-- Sync Rostering Chat Updates → header (LastResult + awaiting queue)
-- Replaces AD_ModelValidator class load (plugin classes are not visible to core Class.forName)

CREATE OR REPLACE FUNCTION aberp_rostering_chat_sync_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_type_name TEXT;
  v_worker_id INTEGER;
  v_role_id INTEGER := 1000012;
BEGIN
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
    -- Worker message → queue for rostering officers
    UPDATE r_request
    SET lastresult = btrim(NEW.result),
        ad_role_id = v_role_id,
        datelastaction = NOW(),
        updated = NOW(),
        updatedby = NEW.createdby
    WHERE r_request_id = NEW.r_request_id;
  ELSE
    -- Officer (or other) reply → awaiting worker
    UPDATE r_request
    SET lastresult = btrim(NEW.result),
        ad_role_id = 0,
        datelastaction = NOW(),
        updated = NOW(),
        updatedby = NEW.createdby
    WHERE r_request_id = NEW.r_request_id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS aberp_rostering_chat_sync_update_trg ON r_requestupdate;
CREATE TRIGGER aberp_rostering_chat_sync_update_trg
AFTER INSERT OR UPDATE OF result ON r_requestupdate
FOR EACH ROW
EXECUTE PROCEDURE aberp_rostering_chat_sync_update();

-- Keep AD validator inactive (OSGi factory path is optional; trigger is source of truth)
UPDATE ad_modelvalidator
SET isactive = 'N', updated = NOW(), updatedby = 100
WHERE modelvalidationclass LIKE '%RosteringChat%'
   OR name = 'AbERP Rostering Chat';

SELECT 'trigger' AS c, tgname FROM pg_trigger WHERE tgname = 'aberp_rostering_chat_sync_update_trg';
SELECT 'validator' AS c, name, isactive FROM ad_modelvalidator
WHERE modelvalidationclass LIKE '%RosteringChat%';
