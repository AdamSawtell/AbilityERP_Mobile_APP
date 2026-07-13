UPDATE ad_tab SET tablevel = 1, updated = NOW()
WHERE ad_tab_uu = '16a01604-c0d4-4f01-8e15-000000000001'
   OR (name = 'Leave Records' AND ad_window_id = (SELECT ad_window_id FROM ad_window WHERE name='Leave Planning'));

SELECT name, seqno, tablevel, isinsertrecord, left(whereclause,80) AS wh
FROM ad_tab WHERE ad_window_id=(SELECT ad_window_id FROM ad_window WHERE name='Leave Planning')
ORDER BY seqno;
