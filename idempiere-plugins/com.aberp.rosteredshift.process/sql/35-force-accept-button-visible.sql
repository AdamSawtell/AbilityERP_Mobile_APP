-- SAW011: Accept Shift Request — Window button on Response Log.
-- Match Employee → Clock In: column IsToolbarButton=N, field IsToolbarButton NULL.
-- Place right of Employee (xposition=4).
-- No DisplayLogic (same as Clock In). Java still enforces rules.
-- After apply: Cache Reset or reopen window (or restart iDempiere).

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

INSERT INTO ad_process_access (
  ad_process_id, ad_role_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby, isreadwrite, ad_process_access_uu
)
SELECT p.ad_process_id, r.ad_role_id, r.ad_client_id, 0, 'Y',
  NOW(), 100, NOW(), 100, 'Y', NULL
FROM ad_process p
CROSS JOIN ad_role r
WHERE p.value = 'SHIFT_ACCEPT_REQUEST'
  AND r.name IN ('Admin', 'AbilityERP Admin', 'Rostering', 'Rostering TL', 'Rostering Officer')
  AND r.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_process_access x
    WHERE x.ad_process_id = p.ad_process_id AND x.ad_role_id = r.ad_role_id
  );

UPDATE ad_process_access pa
SET isactive = 'Y', isreadwrite = 'Y', updated = NOW(), updatedby = 100
FROM ad_process p, ad_role r
WHERE pa.ad_process_id = p.ad_process_id AND pa.ad_role_id = r.ad_role_id
  AND p.value = 'SHIFT_ACCEPT_REQUEST'
  AND r.name IN ('Admin', 'AbilityERP Admin', 'Rostering', 'Rostering TL', 'Rostering Officer');

SELECT f.name, f.isdisplayed, f.istoolbarbutton AS fld_tb, c.istoolbarbutton AS col_tb,
       f.xposition, COALESCE(f.displaylogic,'(null)') AS dl
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE c.columnname = 'AbERP_AcceptShiftRequest';
