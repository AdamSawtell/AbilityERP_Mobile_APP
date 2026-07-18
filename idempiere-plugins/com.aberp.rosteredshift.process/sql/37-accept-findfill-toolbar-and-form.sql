-- SAW011: Show Accept + Find and Fill on Response Log in GRID and form.
-- Root cause: Window-only buttons (IsToolbarButton=N) live in the form pane;
-- Response Log is usually left in Grid Toggle, so the form (and buttons) are display:none.
-- Set IsToolbarButton=B (Both) when available, else Y (toolbar/Process).
-- No DisplayLogic — always listed; Java enforces rules.
-- After apply: Cache Reset + reopen Shift (Rostered) → Response Log.

SET search_path TO adempiere;

DO $$
DECLARE
  v_tb CHAR(1) := 'Y';
BEGIN
  -- Prefer Both if the list/reference allows it on this build
  IF EXISTS (
    SELECT 1 FROM ad_ref_list rl
    JOIN ad_reference r ON r.ad_reference_id = rl.ad_reference_id
    WHERE r.name ILIKE '%ToolbarButton%' AND rl.value = 'B' AND rl.isactive = 'Y'
  ) OR EXISTS (
    SELECT 1 FROM ad_column
    WHERE columnname = 'IsToolbarButton' AND ad_reference_id = 200070
  ) THEN
    v_tb := 'B';
  END IF;

  UPDATE ad_column c
  SET istoolbarbutton = v_tb,
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
  SET istoolbarbutton = v_tb,
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

  RAISE NOTICE 'IsToolbarButton set to %', v_tb;
END $$;

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

-- Explicit tab toolbar buttons (grid-visible Process actions)
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

INSERT INTO ad_toolbarbutton (
  ad_toolbarbutton_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, componentname, action, ad_tab_id, ad_process_id,
  seqno, isadvancedbutton, isaddseparator, entitytype, iscustomization,
  displaylogic, ad_toolbarbutton_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_toolbarbutton_id), 0) + 1 FROM ad_toolbarbutton),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Find and Fill', 'Find and Fill', 'P', tab.ad_tab_id, p.ad_process_id,
  20, 'N', 'N', 'Ab_ERP', 'N',
  NULL,
  'a030f005-4330-4c01-f030-a012f0000005'
FROM ad_process p
CROSS JOIN ad_table tb
JOIN ad_tab tab ON tab.ad_table_id = tb.ad_table_id
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
WHERE p.value = 'AbERP_ResponseLog_FindFill'
  AND tb.tablename = 'AbERP_RosteredResponseLog'
  AND w.name = 'Shift (Rostered)' AND tab.name = 'Response Log' AND tab.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_toolbarbutton tb2
    WHERE tb2.ad_tab_id = tab.ad_tab_id AND tb2.name = 'Find and Fill'
  );

UPDATE ad_toolbarbutton tb
SET isactive = 'Y',
    action = 'P',
    displaylogic = NULL,
    ad_process_id = (SELECT ad_process_id FROM ad_process WHERE value = 'AbERP_ResponseLog_FindFill' LIMIT 1),
    updated = NOW(),
    updatedby = 100
FROM ad_tab tab
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
WHERE tb.ad_tab_id = tab.ad_tab_id
  AND w.name = 'Shift (Rostered)' AND tab.name = 'Response Log'
  AND tb.name = 'Find and Fill';

SELECT c.columnname, c.istoolbarbutton AS col_tb,
       f.isdisplayed, COALESCE(f.displaylogic,'(null)') AS dl
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE c.columnname IN ('AbERP_AcceptShiftRequest','AbERP_FindFillStaff')
ORDER BY c.columnname;

SELECT tb.name, tb.isactive, tb.action, p.value
FROM ad_toolbarbutton tb
JOIN ad_tab tab ON tab.ad_tab_id = tb.ad_tab_id
JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
LEFT JOIN ad_process p ON p.ad_process_id = tb.ad_process_id
WHERE w.name = 'Shift (Rostered)' AND tab.name = 'Response Log'
  AND tb.name IN ('Accept Shift Request','Find and Fill')
ORDER BY tb.name;
