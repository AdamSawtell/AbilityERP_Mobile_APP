SET search_path TO adempiere;

-- =============================================================================
-- Fix Updates parent link + Send to Worker process parameter / table binding
-- =============================================================================

-- 1. Updates tab: link only to the selected R_Request (like standard Request)
DO $$
DECLARE
  v_child_col_id INTEGER;
  v_parent_col_id INTEGER;
  v_updates_tab_id INTEGER;
BEGIN
  SELECT c.ad_column_id INTO v_child_col_id
  FROM ad_column c
  JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
  WHERE tb.tablename = 'R_RequestUpdate' AND c.columnname = 'R_Request_ID'
  LIMIT 1;

  SELECT c.ad_column_id INTO v_parent_col_id
  FROM ad_column c
  JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
  WHERE tb.tablename = 'R_Request' AND c.columnname = 'R_Request_ID'
  LIMIT 1;

  SELECT t.ad_tab_id INTO v_updates_tab_id
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE w.name = 'Rostering Chat' AND t.name = 'Updates'
  LIMIT 1;

  IF v_child_col_id IS NULL OR v_updates_tab_id IS NULL THEN
    RAISE EXCEPTION 'Could not resolve Updates tab / R_Request_ID column';
  END IF;

  -- Child FK column is the link; parent PK for explicit join; whereclause as safety net
  UPDATE ad_tab
  SET ad_column_id = v_child_col_id,
      parent_column_id = v_parent_col_id,
      whereclause = 'R_RequestUpdate.R_Request_ID=@R_Request_ID@',
      isreadonly = 'Y',
      isinsertrecord = 'N',
      issinglerow = 'N',
      orderbyclause = 'R_RequestUpdate.Created ASC',
      updated = NOW(),
      updatedby = 100
  WHERE ad_tab_id = v_updates_tab_id;

  -- Hidden link field required for parent-child in some iDempiere builds
  INSERT INTO ad_field (
    ad_field_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby,
    name, iscentrallymaintained, ad_tab_id, ad_column_id,
    isdisplayed, displaylength, isreadonly, seqno,
    issameline, isheading, isfieldonly, isencrypted, entitytype,
    isdisplayedgrid, xposition, numlines, columnspan,
    isquickentry, istoolbarbutton, ad_field_uu
  )
  SELECT
    (SELECT COALESCE(MAX(ad_field_id), 0) + 1 FROM ad_field),
    0, 0, 'Y', NOW(), 100, NOW(), 100,
    'Request', 'N', v_updates_tab_id, v_child_col_id,
    'N', 0, 'Y', 0,
    'N', 'N', 'N', 'N', 'Ab_ERP',
    'N', 1, 1, 1,
    'N', 'N',
    (
      substring(md5('AbERP_RosteringChat-updates-reqid'), 1, 8) || '-' ||
      substring(md5('AbERP_RosteringChat-updates-reqid'), 9, 4) || '-4e01-8401-000000000001'
    )
  WHERE NOT EXISTS (
    SELECT 1 FROM ad_field f
    WHERE f.ad_tab_id = v_updates_tab_id AND f.ad_column_id = v_child_col_id
  );
END $$;

-- 2. Bind Send process Reply parameter from form context (no ad_table_id — not in this iDempiere build)
UPDATE ad_process p
SET showhelp = 'N',
    description = 'Sends the Reply field to the worker: creates an Updates row and clears the rostering queue.',
    updated = NOW(),
    updatedby = 100
WHERE p.value = 'ROSTERING_CHAT_REPLY';

UPDATE ad_process p
SET showhelp = 'N',
    updated = NOW(),
    updatedby = 100
WHERE p.value = 'ROSTERING_CHAT_CLOSE';

-- Reply parameter: filled from @AbERP_RosteringReply@ when button is clicked (no dialog)
INSERT INTO ad_process_para (
  ad_process_para_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, description, ad_process_id, seqno,
  ad_reference_id, columnname, iscentrallymaintained,
  fieldlength, ismandatory, isrange, entitytype,
  defaultvalue, isencrypted,
  ad_process_para_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_process_para_id), 0) + 1 FROM ad_process_para),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'Reply', 'Message to send to the worker (from Reply field).',
  p.ad_process_id, 10,
  COALESCE(
    (SELECT ad_reference_id FROM ad_reference WHERE name = 'Text' AND isactive = 'Y' LIMIT 1),
    14
  ),
  'Reply', 'N',
  2000, 'N', 'N', 'Ab_ERP',
  '@AbERP_RosteringReply@', 'N',
  (
    substring(md5('ROSTERING_CHAT_REPLY-para-Reply'), 1, 8) || '-' ||
    substring(md5('ROSTERING_CHAT_REPLY-para-Reply'), 9, 4) || '-4f01-8501-000000000001'
  )
FROM ad_process p
WHERE p.value = 'ROSTERING_CHAT_REPLY'
  AND NOT EXISTS (
    SELECT 1 FROM ad_process_para pp
    WHERE pp.ad_process_id = p.ad_process_id AND pp.columnname = 'Reply' AND pp.isactive = 'Y'
  );

UPDATE ad_process_para pp
SET isactive = 'Y',
    defaultvalue = '@AbERP_RosteringReply@',
    fieldlength = 2000,
    ismandatory = 'N',
    updated = NOW(),
    updatedby = 100
FROM ad_process p
WHERE pp.ad_process_id = p.ad_process_id
  AND p.value = 'ROSTERING_CHAT_REPLY'
  AND pp.columnname = 'Reply';

-- Keep Reply field editable
UPDATE ad_field f
SET isreadonly = 'N',
    isupdateable = 'Y',
    isdisplayed = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
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

-- Verify
SELECT 'updates_tab' AS check_type, t.ad_column_id, t.parent_column_id, t.whereclause, t.isreadonly
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Updates';

SELECT 'process' AS check_type, p.value, p.ad_table_id, p.showhelp, pp.columnname, pp.defaultvalue
FROM ad_process p
LEFT JOIN ad_process_para pp ON pp.ad_process_id = p.ad_process_id AND pp.isactive = 'Y'
WHERE p.value = 'ROSTERING_CHAT_REPLY';
