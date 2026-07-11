SET search_path TO adempiere;

-- =============================================================================
-- Fix Close Chat: no dialog trap; awaiting uses IsClosed; align closed status
-- =============================================================================

-- 1) Close process: run immediately (same as Send Reply)
UPDATE ad_process
SET showhelp = 'N',
    name = 'Close Chat',
    description = 'Close this chat so the worker can start a new conversation',
    help = 'Closes the thread. The worker app can then start a new chat.',
    updated = NOW(),
    updatedby = 100
WHERE value = 'ROSTERING_CHAT_CLOSE';

-- Hidden context param only
UPDATE ad_process_para pp
SET ismandatory = 'N',
    isactive = 'Y',
    displaylogic = '@0@=1',
    defaultvalue = '@R_Request_ID@',
    updated = NOW(),
    updatedby = 100
FROM ad_process p
WHERE pp.ad_process_id = p.ad_process_id
  AND p.value = 'ROSTERING_CHAT_CLOSE'
  AND pp.columnname = 'R_Request_ID';

-- 2) Re-bind Close button column → process
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
  AND p.value = 'ROSTERING_CHAT_CLOSE';

UPDATE ad_field f
SET isdisplayed = 'Y',
    isreadonly = 'N',
    isupdateable = 'Y',
    displaylogic = NULL,
    name = 'Close Chat',
    seqno = 60,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname = 'AbERP_CloseRosteringChat';

-- 3) Awaiting Reply: Closed when status.IsClosed='Y' (not hardcoded 102)
UPDATE ad_column
SET columnsql = '(SELECT CASE
      WHEN COALESCE((SELECT s.IsClosed FROM R_Status s WHERE s.R_Status_ID = R_Request.R_Status_ID), ''N'') = ''Y'' THEN ''Closed''
      WHEN COALESCE(R_Request.AD_Role_ID, 0) = 1000012 THEN ''Response required''
      ELSE ''Awaiting worker''
    END)',
    updated = NOW(),
    updatedby = 100
WHERE columnname = 'AbERP_ChatAwaitingReply'
  AND ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'R_Request');

-- 4) Hide Send Reply when thread is closed (category closed status 1000002 or system 102)
UPDATE ad_field f
SET displaylogic = '@R_Status_ID@!102 & @R_Status_ID@!1000002',
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname = 'AbERP_SendRosteringReply';

-- 5) Migrate Rostering Chat threads wrongly closed with System 102 → tenant closed 1000002
UPDATE r_request r
SET r_status_id = 1000002
FROM r_requesttype rt
WHERE r.r_requesttype_id = rt.r_requesttype_id
  AND rt.name = 'Rostering Chat'
  AND r.r_status_id = 102
  AND r.isactive = 'Y';

SELECT 'close_proc' AS c, value, showhelp, classname FROM ad_process WHERE value = 'ROSTERING_CHAT_CLOSE';
SELECT 'awaiting' AS c, LEFT(columnsql, 200) FROM ad_column WHERE columnname = 'AbERP_ChatAwaitingReply';
SELECT 'migrated' AS c, COUNT(*) FROM r_request r
JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
WHERE rt.name = 'Rostering Chat' AND r.r_status_id = 1000002;
