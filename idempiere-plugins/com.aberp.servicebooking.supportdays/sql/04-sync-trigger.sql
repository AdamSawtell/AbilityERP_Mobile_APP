-- SAW009: keep C_OrderLine support days in sync when Service Pattern link is set/changed.
-- Copies AbERP_RosterStartDay/EndDay from AbERP_ServicePattern (pattern day numbers).
-- Does not overwrite manual day edits unless the pattern ID changes (or days are null).
SET search_path TO adempiere;

CREATE OR REPLACE FUNCTION adempiere.aberp_c_orderline_copy_pattern_days()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_start VARCHAR(5);
  v_end VARCHAR(5);
BEGIN
  IF NEW.aberp_servicepattern_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE'
     AND NEW.aberp_servicepattern_id IS NOT DISTINCT FROM OLD.aberp_servicepattern_id
     AND NEW.aberp_support_start_day IS NOT NULL
     AND NEW.aberp_support_end_day IS NOT NULL THEN
    RETURN NEW;
  END IF;

  SELECT sp.aberp_rosterstartday, sp.aberp_rosterendday
  INTO v_start, v_end
  FROM aberp_servicepattern sp
  WHERE sp.aberp_servicepattern_id = NEW.aberp_servicepattern_id;

  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT'
     OR NEW.aberp_servicepattern_id IS DISTINCT FROM OLD.aberp_servicepattern_id THEN
    NEW.aberp_support_start_day := v_start;
    NEW.aberp_support_end_day := v_end;
  ELSE
    IF NEW.aberp_support_start_day IS NULL THEN
      NEW.aberp_support_start_day := v_start;
    END IF;
    IF NEW.aberp_support_end_day IS NULL THEN
      NEW.aberp_support_end_day := v_end;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_aberp_c_orderline_copy_pattern_days ON c_orderline;

CREATE TRIGGER tr_aberp_c_orderline_copy_pattern_days
BEFORE INSERT OR UPDATE OF aberp_servicepattern_id, aberp_support_start_day, aberp_support_end_day
ON c_orderline
FOR EACH ROW
EXECUTE PROCEDURE adempiere.aberp_c_orderline_copy_pattern_days();
