-- SAW027 — fix Review editability + preserve prior match on overwrite
SET search_path TO adempiere;

-- 1) Make stamp columns always-updateable so Reviewed callout can save
UPDATE ad_column SET
  isalwaysupdateable = 'Y',
  updated = NOW()
WHERE ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_ActivityAuditReview')
  AND columnname IN ('ReviewedBy', 'ReviewedDate');

-- 2) Ensure review workflow fields are not read-only at field level
UPDATE ad_field f SET
  isreadonly = 'N',
  updated = NOW()
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Activity Audit Review'
  AND t.name = 'Reviews'
  AND c.columnname IN ('ReviewStatus', 'IsReviewed', 'ReviewNotes', 'IsFollowUpRequired');

-- 3) Processing Button column must not lock the tab:
--    keep DB default N; clear any accidental Y; ensure field stays hidden & not toolbar
UPDATE aberp_activityauditreview SET processing = 'N' WHERE processing IS DISTINCT FROM 'N';

UPDATE ad_field f SET
  isdisplayed = 'N',
  isdisplayedgrid = 'N',
  isreadonly = 'Y',
  updated = NOW()
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Activity Audit Review'
  AND c.columnname = 'Processing';

-- 4) Move Org=* reviews onto the HCO org so Client+Org access can update
--    (activity itself is Org 0 on this smoke row — use client's non-* org)
UPDATE aberp_activityauditreview r SET
  ad_org_id = COALESCE((
      SELECT o.ad_org_id FROM ad_org o
      WHERE o.ad_client_id = r.ad_client_id AND o.ad_org_id <> 0 AND o.isactive = 'Y'
      ORDER BY o.ad_org_id
      LIMIT 1
    ), r.ad_org_id),
  updated = NOW()
WHERE r.ad_client_id = 1000003
  AND r.ad_org_id = 0;

-- 5) Tab must allow insert/update
UPDATE ad_tab t SET
  isreadonly = 'N',
  isinsertrecord = 'Y',
  updated = NOW()
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Activity Audit Review'
  AND t.name = 'Reviews';

SELECT r.aberp_activityauditreview_id, r.ad_org_id, r.processing,
       f.name, c.columnname, f.isreadonly, c.isupdateable, c.isalwaysupdateable
FROM aberp_activityauditreview r
CROSS JOIN ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE r.ad_client_id = 1000003
  AND w.name = 'Activity Audit Review'
  AND c.columnname IN ('ReviewStatus','IsReviewed','ReviewNotes','ReviewedBy','ReviewedDate','Processing')
ORDER BY f.seqno;
