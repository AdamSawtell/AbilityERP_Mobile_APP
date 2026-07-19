SET search_path TO adempiere;

-- Document the overwritten Fall match on the existing open review
UPDATE aberp_activityauditreview SET
  reviewnotes = CASE
    WHEN COALESCE(reviewnotes,'') ILIKE '%Prior match%' THEN reviewnotes
    WHEN COALESCE(reviewnotes,'') = '' THEN
      'Prior match replaced (medical re-audit): Fall'
    ELSE reviewnotes || E'\nPrior match replaced (medical re-audit): Fall'
  END,
  updated = NOW()
WHERE aberp_activityauditreview_id = 1000005
  AND ad_client_id = 1000003;

SELECT aberp_activityauditreview_id, matchedterms, reviewnotes
FROM aberp_activityauditreview WHERE aberp_activityauditreview_id = 1000005;
