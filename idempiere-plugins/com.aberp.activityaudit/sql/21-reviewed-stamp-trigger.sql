-- SAW027 — stamp Reviewed By/Date/status when IsReviewed flips to Y
-- OSGi model validators / classic Callouts are unreliable for this plugin class
-- (AD_ModelValidator Class.forName breaks login; IColumnCallout did not stamp on save).
SET search_path TO adempiere;

CREATE OR REPLACE FUNCTION aberp_activityauditreview_stamp_reviewed()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.isreviewed = 'Y' AND (OLD.isreviewed IS DISTINCT FROM 'Y') THEN
    IF NEW.reviewedby IS NULL THEN
      NEW.reviewedby := COALESCE(NEW.updatedby, OLD.updatedby, 100);
    END IF;
    IF NEW.revieweddate IS NULL THEN
      NEW.revieweddate := date_trunc('day', NOW());
    END IF;
    IF NEW.reviewstatus IS NULL OR NEW.reviewstatus IN ('NW', 'UR') THEN
      NEW.reviewstatus := 'NF';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS aberp_activityauditreview_stamp_reviewed_trg ON aberp_activityauditreview;
CREATE TRIGGER aberp_activityauditreview_stamp_reviewed_trg
BEFORE UPDATE OF isreviewed ON aberp_activityauditreview
FOR EACH ROW
EXECUTE FUNCTION aberp_activityauditreview_stamp_reviewed();

COMMENT ON FUNCTION aberp_activityauditreview_stamp_reviewed() IS
  'SAW027: stamp Reviewed By/Date and set ReviewStatus NF when IsReviewed becomes Y';
