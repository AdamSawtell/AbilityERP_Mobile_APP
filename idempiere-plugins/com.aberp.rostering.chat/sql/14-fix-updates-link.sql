SET search_path TO adempiere;

-- Match working standard Request > Updates tab linkage
UPDATE ad_tab t
SET ad_column_id = NULL,
    parent_column_id = NULL,
    whereclause = NULL,
    isreadonly = 'N',
    isinsertrecord = 'Y',
    issinglerow = 'N',
    orderbyclause = 'R_RequestUpdate.Created ASC',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Updates';

-- Ensure Chat tab has hidden R_Request_ID so context @R_Request_ID@ is populated
INSERT INTO ad_field (
  ad_field_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, iscentrallymaintained, ad_tab_id, ad_column_id,
  isdisplayed, displaylength, isreadonly, seqno, defaultvalue,
  issameline, isheading, isfieldonly, isencrypted, entitytype,
  isdisplayedgrid, xposition, numlines, columnspan,
  isquickentry, istoolbarbutton, ad_field_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'Request', 'N', t.ad_tab_id, c.ad_column_id,
  'N', 14, 'Y', 0, NULL,
  'N', 'N', 'N', 'N', 'Ab_ERP',
  'N', 1, 1, 1, 'N', 'N',
  substring(md5('AbERP_RosteringChat-chat-reqid'), 1, 8) || '-' ||
  substring(md5('AbERP_RosteringChat-chat-reqid'), 9, 4) || '-4a17-8017-000000000017'
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
JOIN ad_column c ON c.ad_table_id = t.ad_table_id AND c.columnname = 'R_Request_ID'
WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND NOT EXISTS (
    SELECT 1 FROM ad_field f WHERE f.ad_tab_id = t.ad_tab_id AND f.ad_column_id = c.ad_column_id
  );

-- Now set explicit child link + whereclause with context (after Chat has key field)
UPDATE ad_tab t
SET ad_column_id = (
      SELECT c.ad_column_id FROM ad_column c
      JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
      WHERE tb.tablename = 'R_RequestUpdate' AND c.columnname = 'R_Request_ID' LIMIT 1
    ),
    parent_column_id = NULL,
    whereclause = 'R_RequestUpdate.R_Request_ID=@R_Request_ID@',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Updates';

-- Result editable; ensure insertable
UPDATE ad_field f
SET isreadonly = 'N', isupdateable = 'Y', isdisplayed = 'Y', isdisplayedgrid = 'Y',
    updated = NOW(), updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Updates'
  AND c.columnname = 'Result';

SELECT t.name, t.ad_column_id, t.parent_column_id, t.whereclause, t.isinsertrecord, t.isreadonly
FROM ad_tab t JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat';

SELECT 'chat_has_reqid' AS c, COUNT(*) 
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name='Rostering Chat' AND t.name='Chat' AND c.columnname='R_Request_ID';
