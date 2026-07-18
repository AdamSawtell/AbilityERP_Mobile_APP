-- SAW011: Fix Accept button visibility on Response Log
-- 1) IsToolbarButton=Y (Toolbar) so Accept appears under Response Log Process (gear) menu
-- 2) Displaylogic uses unquoted list Value: @AbERP_RosteredResponse@=REQ
-- 3) Null-safe: @IsReviewed@!Y & @IsSuperseded@!Y
-- Cache Reset + re-open window after apply.

SET search_path TO adempiere;

UPDATE ad_field f
SET istoolbarbutton = 'Y',
    isactive = 'Y',
    isdisplayed = 'Y',
    isdisplayedgrid = 'N',
    isfieldonly = 'N',
    seqno = 55,
    columnspan = 2,
    xposition = 1,
    displaylogic = '@AbERP_RosteredResponse@=REQ & @IsReviewed@!Y & @IsSuperseded@!Y',
    updated = NOW(),
    updatedby = 100
FROM ad_tab tab
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id,
     ad_column c
WHERE f.ad_tab_id = tab.ad_tab_id
  AND f.ad_column_id = c.ad_column_id
  AND w.name = 'Shift (Rostered)' AND tab.name = 'Response Log'
  AND c.columnname = 'AbERP_AcceptShiftRequest';

UPDATE ad_column c
SET istoolbarbutton = 'Y',
    isactive = 'Y',
    isupdateable = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'AbERP_RosteredResponseLog'
  AND c.columnname = 'AbERP_AcceptShiftRequest';

UPDATE ad_toolbarbutton tb
SET isactive = 'Y',
    action = 'P',
    displaylogic = '@AbERP_RosteredResponse@=REQ & @IsReviewed@!Y & @IsSuperseded@!Y',
    updated = NOW(),
    updatedby = 100
FROM ad_tab tab
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
WHERE tb.ad_tab_id = tab.ad_tab_id
  AND w.name = 'Shift (Rostered)' AND tab.name = 'Response Log'
  AND tb.name = 'Accept Shift Request';

SELECT 'field' AS kind, f.name, f.istoolbarbutton, f.displaylogic
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Shift (Rostered)' AND t.name = 'Response Log'
  AND c.columnname = 'AbERP_AcceptShiftRequest'
UNION ALL
SELECT 'toolbar', tb.name, tb.action, tb.displaylogic
FROM ad_toolbarbutton tb
JOIN ad_tab t ON t.ad_tab_id = tb.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Shift (Rostered)' AND t.name = 'Response Log'
  AND tb.name = 'Accept Shift Request';
