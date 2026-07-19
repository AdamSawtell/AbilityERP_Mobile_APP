SET search_path TO adempiere;

SELECT tablename, accesslevel, isdeleteable, entitytype
FROM ad_table
WHERE tablename LIKE 'AbERP_ActivityAudit%'
ORDER BY tablename;

SELECT c_contactactivity_id, ad_client_id, ad_org_id, contactactivitytype
FROM c_contactactivity WHERE c_contactactivity_id = 1641177;

SELECT ur.ad_user_id, u.name, r.name AS role, r.ad_role_id, r.isaccessallorgs,
       r.ismanual, r.preferencetype, r.userlevel
FROM ad_user_roles ur
JOIN ad_user u ON u.ad_user_id = ur.ad_user_id
JOIN ad_role r ON r.ad_role_id = ur.ad_role_id
WHERE u.name = 'SuperUser' AND r.ad_client_id IN (0, 1000003)
ORDER BY r.ad_client_id, r.name;

SELECT name, windowtype, issotrx FROM ad_window WHERE name LIKE 'Activity Audit%';
