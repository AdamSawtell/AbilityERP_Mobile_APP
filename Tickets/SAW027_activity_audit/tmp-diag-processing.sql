SET search_path TO adempiere;

-- Processing / button columns on review table
SELECT columnname, ad_reference_id, isupdateable, defaultvalue, callout, fieldlength
FROM ad_column
WHERE ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename='AbERP_ActivityAuditReview')
  AND columnname IN ('Processing','Processed','AbERP_OpenActivity','IsActive')
ORDER BY columnname;

-- Does the physical table have Processing?
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='aberp_activityauditreview'
  AND column_name ILIKE '%process%'
ORDER BY 1;

SELECT aberp_activityauditreview_id,
       CASE WHEN EXISTS (
         SELECT 1 FROM information_schema.columns
         WHERE table_schema='adempiere' AND table_name='aberp_activityauditreview' AND column_name='processing'
       ) THEN 'has_processing_col' ELSE 'no_processing_col' END AS proc_col
FROM aberp_activityauditreview LIMIT 1;

-- Field flags for Processing / Open Activity
SELECT f.name, c.columnname, f.isreadonly, f.isdisplayed, f.istoolbarbutton, c.ad_reference_id
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name='Activity Audit Review'
  AND c.columnname IN ('Processing','AbERP_OpenActivity','Processed');
