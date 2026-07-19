SET search_path TO adempiere;
-- All partner/user/location-ish fields on Activity Viewer
SELECT c.columnname, f.name, f.isdisplayed, f.seqno, fg.name AS fieldgroup
FROM ad_field f
JOIN ad_column c ON c.ad_column_id=f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id=f.ad_tab_id
JOIN ad_window w ON w.ad_window_id=t.ad_window_id
LEFT JOIN ad_fieldgroup fg ON fg.ad_fieldgroup_id=f.ad_fieldgroup_id
WHERE w.name='Activity Viewer' AND t.seqno=10
  AND (c.columnname ILIKE '%partner%' OR c.columnname ILIKE '%user%' OR c.columnname ILIKE '%location%' OR c.columnname ILIKE '%staff%' OR c.columnname ILIKE '%sales%')
ORDER BY f.seqno;
-- Sample seeded activity
SELECT a.c_contactactivity_id, a.c_bpartner_id, bp.name AS bp, bp.iscustomer, bp.isemployee,
       a.ad_user_id, u.name AS user_name, u.c_bpartner_id AS user_bp,
       a.c_bpartner_staff_id, st.name AS staff_bp, st.isemployee AS staff_isemp,
       a.aberp_support_location_id, a.salesrep_id
FROM c_contactactivity a
LEFT JOIN c_bpartner bp ON bp.c_bpartner_id=a.c_bpartner_id
LEFT JOIN ad_user u ON u.ad_user_id=a.ad_user_id
LEFT JOIN c_bpartner st ON st.c_bpartner_id=a.c_bpartner_staff_id
WHERE a.c_contactactivity_id IN (1636620,1635020,1639769);
-- Client / Employee window first tab table
SELECT w.name, t.name, tb.tablename, t.seqno
FROM ad_window w
JOIN ad_tab t ON t.ad_window_id=w.ad_window_id
JOIN ad_table tb ON tb.ad_table_id=t.ad_table_id
WHERE w.name IN ('Client','Employee','Support Location') AND t.seqno=10;
