-- SAW016 deeper: approval, calendar days, employee number, location link, fields, workflow
\echo === LEAVE FIELDS ON WINDOW ===
SELECT f.name, c.columnname, f.isdisplayed, f.isreadonly, f.displaylogic, f.seqno, f.ad_field_uu
FROM ad_field f
JOIN ad_column c ON c.ad_column_id=f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id=f.ad_tab_id
WHERE t.ad_tab_id=1000265
ORDER BY f.seqno;

\echo === CURRENT SUPERVISOR COLUMNSQL ===
SELECT columnname, columnsql FROM ad_column
WHERE ad_column_uu='501f9b99-da0a-4531-854b-741a1b13eac0'
   OR (columnname='AbERP_CurrentSupervisor' AND ad_table_id=1000188);

\echo === UNAVAILABILITY TYPES ===
SELECT * FROM aberp_unavailability_type WHERE isactive='Y' ORDER BY 1 LIMIT 20;

\echo === APPROVAL PROCESSES / MODEL VALIDATORS ===
SELECT ad_modelvalidator_id, name, modelvalidationclass, entitytype, isactive
FROM ad_modelvalidator
WHERE modelvalidationclass ILIKE '%leave%' OR name ILIKE '%leave%' OR name ILIKE '%unavail%';

SELECT p.value, p.name, p.classname FROM ad_process p
WHERE classname ILIKE '%approv%' OR name ILIKE '%approv%leave%' OR value ILIKE '%APPROV%LEAVE%';

\echo === WORKFLOW on leave ===
SELECT w.name, w.ad_workflow_uu, n.name AS node
FROM ad_workflow w
LEFT JOIN ad_wf_node n ON n.ad_workflow_id=w.ad_workflow_id
WHERE w.name ILIKE '%leave%' OR w.name ILIKE '%unavail%';

\echo === EMPLOYEE NUMBER ===
SELECT c.columnname, c.name, t.tablename FROM ad_column c
JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE c.columnname ILIKE '%emp%num%' OR c.name ILIKE '%employee number%'
   OR c.columnname ILIKE '%staff%num%' OR c.columnname='Value' AND t.tablename='AD_User'
LIMIT 30;

\echo === CALENDAR DAYS ===
SELECT columnname, name, columnsql FROM ad_column c
JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE upper(t.tablename)=upper('AbERP_Unavailability_Leave')
  AND (c.columnname ILIKE '%day%' OR c.name ILIKE '%day%' OR c.name ILIKE '%calendar%');

\echo === ADVANCED SEARCH table ===
SELECT columnname, name, ad_reference_id, columnsql IS NOT NULL AS virt
FROM ad_column c JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE t.ad_table_id=1000214 OR upper(t.tablename)='ABERP_ONGOINGUNAVAILDAYS'
ORDER BY columnname;
