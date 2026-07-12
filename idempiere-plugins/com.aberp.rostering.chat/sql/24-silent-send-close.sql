SET search_path TO adempiere;

-- =============================================================================
-- Silent Send Reply + Close Chat: NO process dialog
-- Type Reply on the form → click Send Reply → runs immediately (showhelp=S)
-- =============================================================================

-- 1) Both processes: Silent (S) = no parameter popup
UPDATE ad_process
SET showhelp = 'S',
    updated = NOW(),
    updatedby = 100
WHERE value IN ('AbERP_RosteringChat_Send', 'AbERP_RosteringChat_Close');

-- 2) Hide / deactivate ALL process parameters (visible params force a dialog)
UPDATE ad_process_para pp
SET isactive = 'N',
    ismandatory = 'N',
    displaylogic = '@0@=1',
    updated = NOW(),
    updatedby = 100
FROM ad_process p
WHERE pp.ad_process_id = p.ad_process_id
  AND p.value IN ('AbERP_RosteringChat_Send', 'AbERP_RosteringChat_Close');

-- Keep R_Request_ID as inactive context-only default (process uses getRecord_ID)
UPDATE ad_process_para pp
SET isactive = 'Y',
    ismandatory = 'N',
    displaylogic = '@0@=1',
    defaultvalue = '@R_Request_ID@',
    updated = NOW(),
    updatedby = 100
FROM ad_process p
WHERE pp.ad_process_id = p.ad_process_id
  AND p.value IN ('AbERP_RosteringChat_Send', 'AbERP_RosteringChat_Close')
  AND pp.columnname = 'R_Request_ID';

-- Reply param: inactive — form field AbERP_RosteringReply is the source of truth
UPDATE ad_process_para pp
SET isactive = 'N',
    ismandatory = 'N',
    displaylogic = '@0@=1',
    updated = NOW(),
    updatedby = 100
FROM ad_process p
WHERE pp.ad_process_id = p.ad_process_id
  AND p.value = 'AbERP_RosteringChat_Send'
  AND pp.columnname IN ('Reply', 'AbERP_RosteringReply', 'Message');

-- 3) Reply field: editable compose box on the Chat tab
UPDATE ad_column c
SET isupdateable = 'Y',
    isalwaysupdateable = 'Y',
    ismandatory = 'N',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'R_Request'
  AND c.columnname = 'AbERP_RosteringReply';

UPDATE ad_field f
SET isdisplayed = 'Y',
    isreadonly = 'N',
    isupdateable = 'Y',
    name = 'Reply',
    description = 'Type your reply, then click Send Reply',
    seqno = 50,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname = 'AbERP_RosteringReply';

-- 4) Send Reply button: bound, always clickable, no display trap when open
UPDATE ad_column c
SET ad_process_id = p.ad_process_id,
    ad_reference_id = 28,
    istoolbarbutton = 'B',
    isupdateable = 'Y',
    isalwaysupdateable = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb, ad_process p
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'R_Request'
  AND c.columnname = 'AbERP_SendRosteringReply'
  AND p.value = 'AbERP_RosteringChat_Send';

UPDATE ad_field f
SET isdisplayed = 'Y',
    isreadonly = 'N',
    isupdateable = 'Y',
    name = 'Send Reply',
    displaylogic = '@R_Status_ID@!102 & @R_Status_ID@!1000002',
    seqno = 55,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname = 'AbERP_SendRosteringReply';

-- 5) Close Chat: same silent treatment
UPDATE ad_column c
SET ad_process_id = p.ad_process_id,
    ad_reference_id = 28,
    istoolbarbutton = 'B',
    isupdateable = 'Y',
    isalwaysupdateable = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb, ad_process p
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'R_Request'
  AND c.columnname = 'AbERP_CloseRosteringChat'
  AND p.value = 'AbERP_RosteringChat_Close';

UPDATE ad_field f
SET isdisplayed = 'Y',
    isreadonly = 'N',
    isupdateable = 'Y',
    name = 'Close Chat',
    displaylogic = NULL,
    seqno = 60,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname = 'AbERP_CloseRosteringChat';

SELECT 'proc' AS c, value, showhelp FROM ad_process
WHERE value IN ('AbERP_RosteringChat_Send', 'AbERP_RosteringChat_Close')
ORDER BY value;

SELECT 'para' AS c, p.value, pp.columnname, pp.isactive, pp.displaylogic, pp.ismandatory
FROM ad_process_para pp
JOIN ad_process p ON p.ad_process_id = pp.ad_process_id
WHERE p.value IN ('AbERP_RosteringChat_Send', 'AbERP_RosteringChat_Close')
ORDER BY p.value, pp.seqno;
