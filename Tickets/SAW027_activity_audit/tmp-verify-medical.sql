SET search_path TO adempiere;

-- Latest run
SELECT aberp_activityauditrunt_id, starttime, summary, identified, processed, reviewscreated, reopened, errors
FROM aberp_activityauditrunt
WHERE ad_client_id = 1000003
ORDER BY starttime DESC
LIMIT 3;

-- Reviews for the planted activity
SELECT r.aberp_activityauditreview_id, r.c_contactactivity_id, r.matchedterms, r.category,
       r.highestrisklevel, r.reviewstatus, r.isreviewed, r.updated
FROM aberp_activityauditreview r
WHERE r.ad_client_id = 1000003
  AND r.c_contactactivity_id = 1641177
ORDER BY r.updated DESC;

-- Any recent reviews with medical terms
SELECT r.aberp_activityauditreview_id, r.c_contactactivity_id, r.matchedterms,
       r.highestrisklevel, r.reviewstatus, left(r.matchedextract,120) AS extract
FROM aberp_activityauditreview r
WHERE r.ad_client_id = 1000003
  AND (
    r.matchedterms ILIKE '%Seizure%'
    OR r.matchedterms ILIKE '%Chest%'
    OR r.matchedterms ILIKE '%Stroke%'
    OR r.matchedterms ILIKE '%Insulin%'
    OR r.matchedterms ILIKE '%Paramedic%'
    OR r.matchedterms ILIKE '%Blood%'
    OR r.matchedterms ILIKE '%Choking%'
  )
ORDER BY r.updated DESC
LIMIT 10;

-- Proc state for activity
SELECT * FROM aberp_activityauditproc
WHERE ad_client_id = 1000003 AND c_contactactivity_id = 1641177;
