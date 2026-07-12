-- SAW014 discover: Support Location window / table
SELECT w.ad_window_id, w.name AS window_name, w.ad_window_uu,
       t.ad_tab_id, t.name AS tab_name, t.ad_tab_uu, t.seqno,
       tb.ad_table_id, tb.tablename, tb.ad_table_uu, tb.isview, tb.entitytype
FROM ad_window w
JOIN ad_tab t ON t.ad_window_id = w.ad_window_id AND t.isactive = 'Y'
JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
WHERE w.name ILIKE '%Support Location%'
   OR tb.tablename ILIKE '%SupportLocation%'
   OR tb.tablename ILIKE '%support%loc%'
   OR w.name ILIKE '%Support Loc%'
ORDER BY w.name, t.seqno;
