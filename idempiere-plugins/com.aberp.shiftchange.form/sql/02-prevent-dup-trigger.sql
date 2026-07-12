SET search_path TO adempiere;

-- =============================================================================
-- SAW013: Hard-block duplicate active R_Request rows for AbERP_ShiftChange
-- UI DisplayLogic hides the button; this trigger stops API / accidental re-runs.
-- Existing historical duplicates are left alone (trigger fires on INSERT only).
-- =============================================================================

CREATE OR REPLACE FUNCTION adempiere.aberp_shiftchange_prevent_dup_request()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_table_id NUMERIC;
  v_existing NUMERIC;
BEGIN
  SELECT ad_table_id INTO v_table_id
  FROM ad_table
  WHERE tablename = 'AbERP_ShiftChange'
  LIMIT 1;

  IF v_table_id IS NULL OR NEW.ad_table_id IS DISTINCT FROM v_table_id THEN
    RETURN NEW;
  END IF;

  IF COALESCE(NEW.isactive, 'Y') <> 'Y' THEN
    RETURN NEW;
  END IF;

  IF NEW.record_id IS NULL OR NEW.record_id <= 0 THEN
    RETURN NEW;
  END IF;

  SELECT r.r_request_id INTO v_existing
  FROM r_request r
  WHERE r.ad_table_id = NEW.ad_table_id
    AND r.record_id = NEW.record_id
    AND r.isactive = 'Y'
    AND r.r_request_id IS DISTINCT FROM NEW.r_request_id
  ORDER BY r.created
  LIMIT 1;

  IF v_existing IS NOT NULL THEN
    RAISE EXCEPTION
      'A request already exists for this Shift Change form (AbERP_ShiftChange_ID=%, existing R_Request_ID=%). Open the Requests tab instead of creating another.',
      NEW.record_id, v_existing;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS aberp_shiftchange_prevent_dup_request_trg ON adempiere.r_request;

CREATE TRIGGER aberp_shiftchange_prevent_dup_request_trg
  BEFORE INSERT ON adempiere.r_request
  FOR EACH ROW
  EXECUTE PROCEDURE adempiere.aberp_shiftchange_prevent_dup_request();

COMMENT ON FUNCTION adempiere.aberp_shiftchange_prevent_dup_request() IS
  'SAW013: prevent a second active R_Request for the same AbERP_ShiftChange record';
