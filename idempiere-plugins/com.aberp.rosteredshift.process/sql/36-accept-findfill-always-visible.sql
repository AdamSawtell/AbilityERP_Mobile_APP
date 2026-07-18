-- SAW011: Keep Accept + Find and Fill Window buttons always visible on Response Log.
-- Match Employee → Clock In (no DisplayLogic). Java still rejects reviewed / invalid rows.
-- After apply: Cache Reset or logout/reopen Shift (Rostered).

SET search_path TO adempiere;

UPDATE ad_column c
SET istoolbarbutton = 'B',
    isactive = 'Y',
    isalwaysupdateable = 'Y',
    isupdateable = 'Y',
    ad_process_id = (SELECT ad_process_id FROM ad_process WHERE value = 'SHIFT_ACCEPT_REQUEST' LIMIT 1),
    updated = NOW(),
    updatedby = 100
FROM ad_table t
WHERE c.ad_table_id = t.ad_table_id
  AND t.tablename = 'AbERP_RosteredResponseLog'
  AND c.columnname = 'AbERP_AcceptShiftRequest';

UPDATE ad_column c
SET istoolbarbutton = 'B',
    isactive = 'Y',
    isalwaysupdateable = 'Y',
    isupdateable = 'Y',
    ad_process_id = (SELECT ad_process_id FROM ad_process WHERE value = 'AbERP_ResponseLog_FindFill' LIMIT 1),
    updated = NOW(),
    updatedby = 100
FROM ad_table t
WHERE c.ad_table_id = t.ad_table_id
  AND t.tablename = 'AbERP_RosteredResponseLog'
  AND c.columnname = 'AbERP_FindFillStaff';

UPDATE ad_field f
SET istoolbarbutton = NULL,
    isactive = 'Y',
    isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    displaylogic = NULL,
    seqno = 55,
    seqnogrid = 35,
    xposition = 4,
    columnspan = 2,
    updated = NOW(),
    updatedby = 100
FROM ad_tab tab
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id,
     ad_column c
WHERE f.ad_tab_id = tab.ad_tab_id
  AND f.ad_column_id = c.ad_column_id
  AND w.name = 'Shift (Rostered)' AND tab.name = 'Response Log'
  AND c.columnname = 'AbERP_AcceptShiftRequest';

UPDATE ad_field f
SET istoolbarbutton = NULL,
    isactive = 'Y',
    isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    displaylogic = NULL,
    seqno = 68,
    seqnogrid = 40,
    xposition = 5,
    columnspan = 2,
    updated = NOW(),
    updatedby = 100
FROM ad_tab tab
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id,
     ad_column c
WHERE f.ad_tab_id = tab.ad_tab_id
  AND f.ad_column_id = c.ad_column_id
  AND w.name = 'Shift (Rostered)' AND tab.name = 'Response Log'
  AND c.columnname = 'AbERP_FindFillStaff';

UPDATE ad_toolbarbutton tb
SET isactive = 'Y',
    action = 'P',
    displaylogic = NULL,
    ad_process_id = (SELECT ad_process_id FROM ad_process WHERE value = 'SHIFT_ACCEPT_REQUEST' LIMIT 1),
    updated = NOW(),
    updatedby = 100
FROM ad_tab tab
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
WHERE tb.ad_tab_id = tab.ad_tab_id
  AND w.name = 'Shift (Rostered)' AND tab.name = 'Response Log'
  AND tb.name = 'Accept Shift Request';

-- Stop install SQL from re-hiding Accept on redeploy
UPDATE ad_field f
SET displaylogic = NULL
FROM ad_column c
WHERE f.ad_column_id = c.ad_column_id
  AND c.columnname = 'AbERP_AcceptShiftRequest'
  AND f.displaylogic IS NOT DISTINCT FROM '@IsReviewed@!Y';

UPDATE ad_field f
SET displaylogic = NULL
FROM ad_column c
WHERE f.ad_column_id = c.ad_column_id
  AND c.columnname = 'AbERP_FindFillStaff'
  AND f.displaylogic IS NOT DISTINCT FROM '@IsReviewed@!Y';

SELECT c.columnname, f.isdisplayed, f.istoolbarbutton AS fld_tb, c.istoolbarbutton AS col_tb,
       f.xposition, COALESCE(f.displaylogic,'(null)') AS dl
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE c.columnname IN ('AbERP_AcceptShiftRequest','AbERP_FindFillStaff')
ORDER BY c.columnname;
