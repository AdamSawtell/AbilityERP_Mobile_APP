SELECT w.name AS win, t.name, t.seqno, t.tablevel, t.issinglerow, t.isinfotab, t.isadvancedtab, t.isreadonly, t.isinsertrecord, t.ad_column_id, t.parent_column_id, t.whereclause IS NOT NULL AS has_wh, t.isactive,
  (SELECT COUNT(*) FROM ad_field f WHERE f.ad_tab_id=t.ad_tab_id AND f.isdisplayed='Y') AS disp_fields
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id=t.ad_window_id
WHERE w.name IN ('Leave Planning','Ongoing Unavailability','Employee Roster Period Summary')
ORDER BY w.name, t.seqno;

-- Any userdef hiding tabs?
SELECT * FROM ad_userdef_tab WHERE ad_tab_id IN (
  SELECT ad_tab_id FROM ad_tab WHERE ad_window_id=(SELECT ad_window_id FROM ad_window WHERE name='Leave Planning')
);
