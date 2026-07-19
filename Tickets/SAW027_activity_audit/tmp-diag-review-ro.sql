SET search_path TO adempiere;

SELECT aberp_activityauditreview_id, ad_client_id, ad_org_id, isactive,
       matchedterms, reviewstatus, isreviewed
FROM aberp_activityauditreview WHERE ad_client_id = 1000003;

-- UserDef overrides
SELECT uf.name, uf.isreadonly, uf.isdisplayed, c.columnname, u.name AS userdef
FROM ad_userdef_field uf
JOIN ad_field f ON f.ad_field_id = uf.ad_field_id
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_userdef_tab ut ON ut.ad_userdef_tab_id = uf.ad_userdef_tab_id
JOIN ad_userdef_win u ON u.ad_userdef_win_id = ut.ad_userdef_win_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Activity Audit Review';

-- Column updateable for review fields that should edit
SELECT columnname, isupdateable, isalwaysupdateable, ismandatory, callout
FROM ad_column
WHERE ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename='AbERP_ActivityAuditReview')
  AND columnname IN ('ReviewStatus','IsReviewed','ReviewNotes','IsFollowUpRequired','ReviewedBy','ReviewedDate')
ORDER BY columnname;

-- Role org access for Admin
SELECT r.name, oa.ad_org_id, o.name AS org, oa.isreadonly
FROM ad_role r
LEFT JOIN ad_role_orgaccess oa ON oa.ad_role_id = r.ad_role_id
LEFT JOIN ad_org o ON o.ad_org_id = oa.ad_org_id
WHERE r.name IN ('Admin','AbilityERP Admin') AND r.ad_client_id = 1000003
ORDER BY r.name, oa.ad_org_id;

SELECT name, isaccessallorgs, iscanexport, iscanreport, preferencetype
FROM ad_role WHERE name IN ('Admin','AbilityERP Admin') AND ad_client_id IN (0,1000003);
