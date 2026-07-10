SET search_path TO adempiere;

-- Fix "Changes ignored" on Rostering Chat header
-- 1) Form mode for reliable Reply editing
-- 2) Button fields must be updateable or clicks/edits get ignored
-- 3) Ensure chat records are not processed/locked

UPDATE ad_tab t
SET isreadonly = 'N',
    isinsertrecord = 'N',
    issinglerow = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND t.tablevel = 0;

-- Reply: fully editable
UPDATE ad_field f
SET isreadonly = 'N',
    isupdateable = 'Y',
    isdisplayed = 'Y',
    isdefaultfocus = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname = 'AbERP_RosteringReply';

UPDATE ad_column c
SET isupdateable = 'Y',
    isalwaysupdateable = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'R_Request'
  AND c.columnname = 'AbERP_RosteringReply';

-- Send / Close buttons must be updateable or WebUI ignores the action
UPDATE ad_field f
SET isreadonly = 'N',
    isupdateable = 'Y',
    isdisplayed = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname IN ('AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat');

UPDATE ad_column c
SET isupdateable = 'Y',
    isalwaysupdateable = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'R_Request'
  AND c.columnname IN ('AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat');

-- Unlock any chat threads stuck as processed
UPDATE r_request r
SET processed = 'N',
    updated = NOW(),
    updatedby = 100
FROM r_requesttype rt
WHERE rt.r_requesttype_id = r.r_requesttype_id
  AND rt.name = 'Rostering Chat'
  AND r.processed = 'Y';

-- Window must be read-write for rostering roles
UPDATE ad_window_access wa
SET isreadwrite = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE wa.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND wa.isactive = 'Y';

SELECT 'tab' AS check_type, t.name, t.isreadonly, t.issinglerow, t.isinsertrecord
FROM ad_tab t JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat';

SELECT 'fields' AS check_type, f.name, f.isreadonly, f.isupdateable, c.isupdateable, c.isalwaysupdateable
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname IN ('AbERP_RosteringReply', 'AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat');
