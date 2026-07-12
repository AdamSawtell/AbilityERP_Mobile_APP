-- SAW012 rollback (AD flags / HouseKeeping only — does NOT restore purged rows or drop indexes)

UPDATE ad_table SET ishighvolume = 'N', updated = now(), updatedby = 100
WHERE tablename IN ('AD_PInstance','AD_Session','AD_Issue');

UPDATE ad_tab SET maxqueryrecords = 0, orderbyclause = NULL, updated = now(), updatedby = 100
WHERE ad_tab_uu IN (
  '58bba03d-cb5c-4230-aeb2-1a435ae41b93',
  '939cc571-7724-4631-977a-ec54f21ea0b3',
  '3a8be5bf-fd95-460a-8c4d-2996f46b767e',
  '3e2298f0-8cfe-4520-8518-5bd176c8ec7f',
  '0fa84b5c-6d82-4915-8907-81b52d93bf0e'
);

UPDATE ad_tab SET whereclause = NULL, updated = now(), updatedby = 100
WHERE ad_tab_uu = '58bba03d-cb5c-4230-aeb2-1a435ae41b93';


UPDATE ad_field SET isselectioncolumn = 'N', updated = now(), updatedby = 100
WHERE ad_field_uu IN (
  'ffbb9687-2753-4427-912b-9ee50ea0985a','1bf1c01e-f08a-4422-98f7-fc002ad81203',
  'b73ab274-9b6a-4ab6-b111-bc8f500d6c05','c9d37019-9fc6-450b-9034-8dcff1709a1e',
  '5dbef232-598d-45fb-ae1a-b489e184a34b','b34dc687-f9d8-44a7-ae3e-a87d0417bb5f',
  'e313b0a9-f4aa-40e7-a583-64392fdd6c3d','5a582321-b3f2-4154-a607-8ac26a6dca59',
  '423f8347-ae57-424b-b6cf-120cfaf85482'
);

UPDATE ad_scheduler SET isactive = 'N', updated = now(), updatedby = 100
WHERE ad_scheduler_uu IN (
  'b7e2a012-90d1-4a01-9c02-000000000001',
  'b7e2a012-90d1-4a01-9c02-000000000002',
  'b7e2a012-90d1-4a01-9c02-000000000003',
  'b7e2a012-90d1-4a01-9c02-000000000004'
);

UPDATE ad_housekeeping SET isactive = 'N', updated = now(), updatedby = 100
WHERE ad_housekeeping_uu IN (
  'b7e2a012-90d1-4a01-9c01-000000000001',
  'b7e2a012-90d1-4a01-9c01-000000000002',
  'b7e2a012-90d1-4a01-9c01-000000000003',
  'b7e2a012-90d1-4a01-9c01-000000000004'
);

-- Optional index / function drops (commented):
-- DROP INDEX CONCURRENTLY IF EXISTS adempiere.ad_pinstance_created_ix;
-- DROP INDEX CONCURRENTLY IF EXISTS adempiere.ad_session_created_ix;
-- DROP INDEX CONCURRENTLY IF EXISTS adempiere.ad_changelog_session_created_ix;
-- DROP INDEX CONCURRENTLY IF EXISTS adempiere.ad_issue_created_ix;
-- DROP INDEX CONCURRENTLY IF EXISTS adempiere.ad_pinstance_process_created_ix;
-- DROP FUNCTION IF EXISTS adempiere.aberp_pinstance_ok_to_purge(numeric);
-- DROP FUNCTION IF EXISTS adempiere.aberp_session_ok_to_purge(numeric);
