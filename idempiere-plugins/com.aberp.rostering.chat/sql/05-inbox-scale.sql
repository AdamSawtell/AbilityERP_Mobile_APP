SET search_path TO adempiere;

-- Rostering Chat inbox at scale: multi-row grid, awaiting-reply flag, priority sort.

-- ---------------------------------------------------------------------------
-- 1. Virtual column — Awaiting Reply (computed from queue + status)
-- ---------------------------------------------------------------------------
INSERT INTO ad_element (
  ad_element_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  columnname, entitytype, name, printname, ad_element_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_element_id), 0) + 1 FROM ad_element),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'AbERP_ChatAwaitingReply', 'Ab_ERP', 'Awaiting Reply', 'Awaiting Reply',
  (
    substring(md5('AbERP_ChatAwaitingReply-element'), 1, 8) || '-' ||
    substring(md5('AbERP_ChatAwaitingReply-element'), 9, 4) || '-4d01-8301-000000000001'
  )
WHERE NOT EXISTS (
  SELECT 1 FROM ad_element WHERE columnname = 'AbERP_ChatAwaitingReply'
);

INSERT INTO ad_column (
  ad_column_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, entitytype, columnname, ad_table_id,
  ad_reference_id, fieldlength, version,
  iskey, isparent, ismandatory, isupdateable, isidentifier, seqno,
  istranslated, isencrypted, isselectioncolumn,
  ad_element_id, issyncdatabase, isalwaysupdateable,
  isautocomplete, isallowlogging, isallowcopy,
  istoolbarbutton, issecure, fkconstrainttype, ishtml,
  columnsql, ad_column_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_column_id), 0) + 1 FROM ad_column),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'Awaiting Reply', 'Ab_ERP', 'AbERP_ChatAwaitingReply', tb.ad_table_id,
  COALESCE(
    (SELECT ad_reference_id FROM ad_reference WHERE name = 'String' AND isactive = 'Y' LIMIT 1),
    10
  ),
  60, 0,
  'N', 'N', 'N', 'N', 'N', 0,
  'N', 'N', 'Y',
  e.ad_element_id, 'N', 'N',
  'N', 'Y', 'N',
  'N', 'N', 'N', 'N',
  '(SELECT CASE
      WHEN R_Request.R_Status_ID = 102 THEN ''Closed''
      WHEN COALESCE(R_Request.AD_Role_ID, 0) = 1000012 THEN ''Awaiting Rostering''
      ELSE ''Awaiting Worker''
    END)',
  (
    substring(md5('AbERP_ChatAwaitingReply-col'), 1, 8) || '-' ||
    substring(md5('AbERP_ChatAwaitingReply-col'), 9, 4) || '-4d02-8302-000000000002'
  )
FROM ad_element e
CROSS JOIN ad_table tb
WHERE e.columnname = 'AbERP_ChatAwaitingReply'
  AND tb.tablename = 'R_Request' AND tb.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_column c
    WHERE c.columnname = 'AbERP_ChatAwaitingReply' AND c.ad_table_id = tb.ad_table_id
  );

UPDATE ad_column c
SET columnsql = '(SELECT CASE
      WHEN R_Request.R_Status_ID = 102 THEN ''Closed''
      WHEN COALESCE(R_Request.AD_Role_ID, 0) = 1000012 THEN ''Awaiting Rostering''
      ELSE ''Awaiting Worker''
    END)',
    isselectioncolumn = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb, ad_element e
WHERE c.ad_table_id = tb.ad_table_id AND tb.tablename = 'R_Request'
  AND c.ad_element_id = e.ad_element_id AND e.columnname = 'AbERP_ChatAwaitingReply';

-- ---------------------------------------------------------------------------
-- 2. Multi-row inbox tab — awaiting rostering first, then most recent activity
-- ---------------------------------------------------------------------------
UPDATE ad_tab t
SET issinglerow = 'N',
    orderbyclause = '(CASE WHEN R_Request.R_Status_ID <> 102 AND COALESCE(R_Request.AD_Role_ID,0)=1000012 THEN 0 ELSE 1 END), R_Request.DateLastAction DESC NULLS LAST, R_Request.Updated DESC',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND t.tablevel = 0;

-- ---------------------------------------------------------------------------
-- 3. Grid columns for triage; detail-only fields for reply/actions
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_header_tab_id INTEGER;
BEGIN
  SELECT t.ad_tab_id INTO v_header_tab_id
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE w.name = 'Rostering Chat' AND t.name = 'Chat' AND t.tablevel = 0
  LIMIT 1;

  INSERT INTO ad_field (
    ad_field_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby,
    name, description, iscentrallymaintained,
    ad_tab_id, ad_column_id,
    isdisplayed, displaylength, isreadonly, seqno, sortno,
    issameline, isheading, isfieldonly, isencrypted, entitytype,
    isdisplayedgrid, xposition, numlines, columnspan,
    isquickentry, istoolbarbutton, isadvancedfield, isdefaultfocus,
    ad_field_uu
  )
  SELECT
    (SELECT COALESCE(MAX(ad_field_id), 0) + 1 FROM ad_field),
    0, 0, 'Y', NOW(), 100, NOW(), 100,
    'Awaiting Reply', 'Who needs to respond next on this thread.', 'N',
    v_header_tab_id, c.ad_column_id,
    'Y', 20, 'Y', 25, 0,
    'N', 'N', 'N', 'N', 'Ab_ERP',
    'Y', 1, 1, 1,
    'N', 'N', 'N', 'N',
    (
      substring(md5('AbERP_ChatAwaitingReply-field'), 1, 8) || '-' ||
      substring(md5('AbERP_ChatAwaitingReply-field'), 9, 4) || '-4d03-8303-000000000003'
    )
  FROM ad_column c
  JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id AND tb.tablename = 'R_Request'
  WHERE c.columnname = 'AbERP_ChatAwaitingReply' AND c.isactive = 'Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_field f
      WHERE f.ad_tab_id = v_header_tab_id AND f.ad_column_id = c.ad_column_id
    );
END $$;

UPDATE ad_field f
SET isdisplayed = 'Y',
    isreadonly = CASE c.columnname
      WHEN 'AbERP_RosteringReply' THEN 'N'
      WHEN 'AbERP_SendRosteringReply' THEN 'N'
      WHEN 'AbERP_CloseRosteringChat' THEN 'N'
      ELSE 'Y'
    END,
    isupdateable = CASE c.columnname
      WHEN 'AbERP_RosteringReply' THEN 'Y'
      ELSE COALESCE(f.isupdateable, 'N')
    END,
    seqno = CASE c.columnname
      WHEN 'AD_User_ID' THEN 10
      WHEN 'R_Status_ID' THEN 20
      WHEN 'AbERP_ChatAwaitingReply' THEN 25
      WHEN 'LastResult' THEN 30
      WHEN 'DateLastAction' THEN 40
      WHEN 'AbERP_RosteringReply' THEN 55
      WHEN 'AbERP_SendRosteringReply' THEN 110
      WHEN 'AbERP_CloseRosteringChat' THEN 130
      ELSE f.seqno
    END,
    sortno = CASE c.columnname
      WHEN 'AbERP_ChatAwaitingReply' THEN 10
      WHEN 'DateLastAction' THEN 20
      WHEN 'AD_User_ID' THEN 30
      ELSE COALESCE(f.sortno, 0)
    END,
    name = CASE c.columnname
      WHEN 'AD_User_ID' THEN 'Worker'
      WHEN 'LastResult' THEN 'Last Message'
      WHEN 'DateLastAction' THEN 'Last Activity'
      ELSE f.name
    END,
    numlines = CASE c.columnname
      WHEN 'LastResult' THEN 2
      WHEN 'AbERP_RosteringReply' THEN 3
      ELSE COALESCE(f.numlines, 1)
    END,
    columnspan = CASE c.columnname
      WHEN 'LastResult' THEN 3
      WHEN 'AbERP_RosteringReply' THEN 3
      ELSE COALESCE(f.columnspan, 1)
    END,
    isdisplayedgrid = CASE c.columnname
      WHEN 'AbERP_RosteringReply' THEN 'N'
      WHEN 'AbERP_SendRosteringReply' THEN 'N'
      WHEN 'AbERP_CloseRosteringChat' THEN 'N'
      ELSE 'Y'
    END,
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND c.columnname IN (
    'AD_User_ID', 'R_Status_ID', 'AbERP_ChatAwaitingReply',
    'LastResult', 'DateLastAction',
    'AbERP_RosteringReply', 'AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat'
  );

-- Reply must stay editable (do not fold into the read-only grid field update above)
UPDATE ad_field f
SET isreadonly = 'N',
    isupdateable = 'Y',
    isdisplayed = 'Y',
    isdisplayedgrid = 'N',
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

UPDATE ad_column c
SET isupdateable = 'Y',
    isalwaysupdateable = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'R_Request'
  AND c.columnname = 'AbERP_RosteringReply';

-- Re-show Last Message + Last Activity in grid (hidden by earlier trim)
UPDATE ad_field f
SET isdisplayed = 'Y',
    isdisplayedgrid = 'Y',
    isreadonly = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND c.columnname IN ('LastResult', 'DateLastAction');

SELECT 'Inbox tab' AS check_type, t.issinglerow, t.orderbyclause
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat';

SELECT 'Grid fields' AS check_type, f.name, f.isdisplayedgrid, f.seqno
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND f.isactive = 'Y' AND f.isdisplayed = 'Y'
ORDER BY f.seqno;
