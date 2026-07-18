-- SAW011: Accept on Response Log via detail toolbar Process (selected row)
-- + ensure Admin / AbilityERP Admin process access
-- Cache Reset + re-open Shift window after apply.

SET search_path TO adempiere;

-- Toolbar/Process on the selected response row (detail grid — Window buttons stay hidden)
UPDATE ad_column c
SET istoolbarbutton = 'Y',
    isactive = 'Y',
    isupdateable = 'Y',
    issyncdatabase = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'AbERP_RosteredResponseLog'
  AND c.columnname = 'AbERP_AcceptShiftRequest';

UPDATE ad_field f
SET istoolbarbutton = 'Y',
    isactive = 'Y',
    isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    isfieldonly = 'N',
    seqno = 55,
    seqnogrid = 35,
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

-- Mandatory: process access for Admin + AbilityERP Admin (and rostering roles when present)
INSERT INTO ad_process_access (
  ad_process_id, ad_role_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby, isreadwrite, ad_process_access_uu
)
SELECT p.ad_process_id, roles.ad_role_id, roles.ad_client_id, 0, 'Y',
  NOW(), 100, NOW(), 100, 'Y', NULL
FROM ad_process p
CROSS JOIN (
  SELECT ad_role_id, ad_client_id FROM ad_role
  WHERE name IN (
      'AbilityERP Admin',
      'Admin',
      'Rostering Officer',
      'Rostering',
      'Rostering TL'
    ) AND isactive = 'Y'
  UNION ALL
  SELECT 0, 0
) AS roles(ad_role_id, ad_client_id)
WHERE p.value = 'SHIFT_ACCEPT_REQUEST'
  AND NOT EXISTS (
    SELECT 1 FROM ad_process_access x
    WHERE x.ad_process_id = p.ad_process_id
      AND x.ad_role_id = roles.ad_role_id
      AND x.ad_client_id = roles.ad_client_id
  );

-- Re-activate if previously deactivated
UPDATE ad_process_access pa
SET isactive = 'Y', isreadwrite = 'Y', updated = NOW(), updatedby = 100
FROM ad_process p, ad_role r
WHERE pa.ad_process_id = p.ad_process_id
  AND pa.ad_role_id = r.ad_role_id
  AND p.value = 'SHIFT_ACCEPT_REQUEST'
  AND r.name IN ('AbilityERP Admin', 'Admin', 'Rostering', 'Rostering TL', 'Rostering Officer');

SELECT 'field' AS kind, f.name, f.istoolbarbutton, f.isdisplayed, f.isdisplayedgrid, f.displaylogic
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
WHERE f.ad_tab_id = 1000256 AND c.columnname = 'AbERP_AcceptShiftRequest'
UNION ALL
SELECT 'access', r.name, pa.isreadwrite, pa.isactive, NULL, NULL
FROM ad_process_access pa
JOIN ad_role r ON r.ad_role_id = pa.ad_role_id
JOIN ad_process p ON p.ad_process_id = pa.ad_process_id
WHERE p.value = 'SHIFT_ACCEPT_REQUEST' AND pa.isactive = 'Y'
ORDER BY 1, 2;
