SET search_path TO adempiere;

-- Make Reply editable again (05-inbox-scale accidentally set isreadonly='Y' on it)

UPDATE ad_column c
SET isupdateable = 'Y',
    isalwaysupdateable = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'R_Request'
  AND c.columnname = 'AbERP_RosteringReply';

UPDATE ad_field f
SET isreadonly = 'N',
    isupdateable = 'Y',
    isdisplayed = 'Y',
    isdisplayedgrid = 'N',
    numlines = 3,
    columnspan = 3,
    isdefaultfocus = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND c.columnname = 'AbERP_RosteringReply';

-- Tab must allow edits (grid for triage; form for reply)
UPDATE ad_tab t
SET isreadonly = 'N',
    isinsertrecord = 'N',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND t.tablevel = 0;

SELECT 'field' AS check_type, f.name, f.isreadonly, f.isupdateable, f.isdisplayed
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname = 'AbERP_RosteringReply';

SELECT 'column' AS check_type, c.columnname, c.isupdateable, c.isalwaysupdateable
FROM ad_column c
JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
WHERE tb.tablename = 'R_Request' AND c.columnname = 'AbERP_RosteringReply';

SELECT 'tab' AS check_type, t.name, t.issinglerow, t.isreadonly
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat';
