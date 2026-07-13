-- Peer tabs (both level 0) — more reliable when no FK link
UPDATE ad_tab SET tablevel = 0, updated = NOW()
WHERE ad_tab_uu = '16a01604-c0d4-4f01-8e15-000000000001';

-- Ensure both tabs active
UPDATE ad_tab SET isactive='Y', updated=NOW()
WHERE ad_window_id=(SELECT ad_window_id FROM ad_window WHERE name='Leave Planning');

SELECT name, seqno, tablevel, isactive, ad_table_id FROM ad_tab
WHERE ad_window_id=(SELECT ad_window_id FROM ad_window WHERE name='Leave Planning')
ORDER BY seqno;
