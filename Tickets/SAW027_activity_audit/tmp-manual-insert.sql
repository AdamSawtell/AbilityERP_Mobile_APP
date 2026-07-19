SET search_path TO adempiere;

-- Manual insert mimicking engine to surface constraint/type issues
INSERT INTO aberp_activityauditproc (
  aberp_activityauditproc_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby, aberp_activityauditproc_uu,
  c_contactactivity_id, activityupdated, lastaudited, auditresult,
  matchedterms, termsapplied
) VALUES (
  1000099, 1000003, 0, 'Y',
  NOW(), 100, NOW(), 100, '27a027-test-proc-000000000001',
  1641177, NOW(), NOW(), 'MT',
  'Fall', 'test'
);

INSERT INTO aberp_activityauditreview (
  aberp_activityauditreview_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby, aberp_activityauditreview_uu,
  c_contactactivity_id, activitydate, c_bpartner_id, ad_user_id,
  contactactivitytype, matchedterms, matchedextract, category,
  highestrisklevel, reviewstatus, isreviewed, isfollowuprequired,
  activityupdatedaudited
) VALUES (
  1000099, 1000003, 0, 'Y',
  NOW(), 100, NOW(), 100, '27a027-test-rev-000000000001',
  1641177, NOW(), NULL, NULL,
  'TA', 'Fall', 'had a fall', 'SF',
  'MD', 'NW', 'N', 'N',
  NOW()
);

SELECT aberp_activityauditreview_id, matchedterms FROM aberp_activityauditreview WHERE aberp_activityauditreview_id=1000099;
