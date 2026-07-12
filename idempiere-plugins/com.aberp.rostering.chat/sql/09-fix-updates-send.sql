SET search_path TO adempiere;

-- =============================================================================
-- Fix Updates parent link (match working Request pattern) + reliable Send params
-- =============================================================================

-- 1. Updates tab: link via child FK only (IsParent=Y). Clear whereclause that
--    becomes R_Request_ID=0 when context is missing and hides all rows.
UPDATE ad_tab t
SET ad_column_id = (
      SELECT c.ad_column_id FROM ad_column c
      JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
      WHERE tb.tablename = 'R_RequestUpdate' AND c.columnname = 'R_Request_ID' LIMIT 1
    ),
    parent_column_id = NULL,
    whereclause = NULL,
    issinglerow = 'N',
    isreadonly = 'Y',
    isinsertrecord = 'N',
    orderbyclause = 'R_RequestUpdate.Created ASC',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Updates';

UPDATE ad_column c
SET isparent = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'R_RequestUpdate'
  AND c.columnname = 'R_Request_ID';

-- Ensure hidden R_Request_ID field exists on Updates (needed for parent link)
DO $$
DECLARE
  v_tab_id INTEGER;
  v_col_id INTEGER;
BEGIN
  SELECT t.ad_tab_id INTO v_tab_id
  FROM ad_tab t JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE w.name = 'Rostering Chat' AND t.name = 'Updates' LIMIT 1;

  SELECT c.ad_column_id INTO v_col_id
  FROM ad_column c JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
  WHERE tb.tablename = 'R_RequestUpdate' AND c.columnname = 'R_Request_ID' LIMIT 1;

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
    'Request', 'N', v_tab_id, v_col_id,
    'N', 14, 'Y', 0,
    'N', 'N', 'N', 'N', 'Ab_ERP',
    'N', 1, 1, 1,
    'N', 'N',
    substring(md5('AbERP_RosteringChat-upd-req'), 1, 8) || '-' ||
    substring(md5('AbERP_RosteringChat-upd-req'), 9, 4) || '-4e11-8411-000000000011'
  WHERE NOT EXISTS (
    SELECT 1 FROM ad_field f WHERE f.ad_tab_id = v_tab_id AND f.ad_column_id = v_col_id
  );
END $$;

-- 2. Send process: show dialog with Request + Reply filled from context
UPDATE ad_process
SET showhelp = 'Y',
    description = 'Sends your reply to the worker and saves it on the Updates tab.',
    updated = NOW(),
    updatedby = 100
WHERE value = 'AbERP_RosteringChat_Send';

UPDATE ad_process
SET showhelp = 'Y',
    updated = NOW(),
    updatedby = 100
WHERE value = 'AbERP_RosteringChat_Close';

-- R_Request_ID parameter (hidden from user via displaylogic, filled from context)
DO $$
DECLARE
  v_process_id INTEGER;
  v_para_id INTEGER;
  v_table_id INTEGER;
BEGIN
  SELECT ad_process_id INTO v_process_id FROM ad_process WHERE value = 'AbERP_RosteringChat_Send' LIMIT 1;
  SELECT ad_table_id INTO v_table_id FROM ad_table WHERE tablename = 'R_Request' LIMIT 1;

  SELECT ad_process_para_id INTO v_para_id
  FROM ad_process_para
  WHERE ad_process_id = v_process_id AND columnname = 'R_Request_ID'
  LIMIT 1;

  IF v_para_id IS NULL THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_process_id, seqno,
      ad_reference_id, ad_reference_value_id, columnname, iscentrallymaintained,
      fieldlength, ismandatory, isrange, entitytype,
      defaultvalue, displaylogic, isencrypted,
      ad_process_para_uu
    ) VALUES (
      (SELECT COALESCE(MAX(ad_process_para_id), 0) + 1 FROM ad_process_para),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Chat', 'Chat thread to reply on',
      v_process_id, 5,
      19, -- Table Direct
      NULL,
      'R_Request_ID', 'N',
      22, 'Y', 'N', 'Ab_ERP',
      '@R_Request_ID@', '@0@=1', -- hide (always false displaylogic)
      'N',
      substring(md5('AbERP_RosteringChat_Send-para-req'), 1, 8) || '-' ||
      substring(md5('AbERP_RosteringChat_Send-para-req'), 9, 4) || '-4f11-8511-000000000011'
    );
  ELSE
    UPDATE ad_process_para
    SET isactive = 'Y',
        seqno = 5,
        ismandatory = 'Y',
        defaultvalue = '@R_Request_ID@',
        displaylogic = '@0@=1',
        ad_reference_id = 19,
        updated = NOW(),
        updatedby = 100
    WHERE ad_process_para_id = v_para_id;
  END IF;

  -- Reply parameter visible
  SELECT ad_process_para_id INTO v_para_id
  FROM ad_process_para
  WHERE ad_process_id = v_process_id AND columnname = 'Reply'
  LIMIT 1;

  IF v_para_id IS NULL THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_process_id, seqno,
      ad_reference_id, columnname, iscentrallymaintained,
      fieldlength, ismandatory, isrange, entitytype,
      defaultvalue, isencrypted,
      ad_process_para_uu
    ) VALUES (
      (SELECT COALESCE(MAX(ad_process_para_id), 0) + 1 FROM ad_process_para),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Reply', 'Message to send to the worker',
      v_process_id, 10,
      COALESCE((SELECT ad_reference_id FROM ad_reference WHERE name = 'Text' LIMIT 1), 14),
      'Reply', 'N',
      2000, 'Y', 'N', 'Ab_ERP',
      '@AbERP_RosteringReply@', 'N',
      substring(md5('AbERP_RosteringChat_Send-para-Reply2'), 1, 8) || '-' ||
      substring(md5('AbERP_RosteringChat_Send-para-Reply2'), 9, 4) || '-4f12-8512-000000000012'
    );
  ELSE
    UPDATE ad_process_para
    SET isactive = 'Y',
        seqno = 10,
        ismandatory = 'Y',
        defaultvalue = '@AbERP_RosteringReply@',
        fieldlength = 2000,
        updated = NOW(),
        updatedby = 100
    WHERE ad_process_para_id = v_para_id;
  END IF;
END $$;

-- Same R_Request_ID param for Close
DO $$
DECLARE
  v_process_id INTEGER;
  v_para_id INTEGER;
BEGIN
  SELECT ad_process_id INTO v_process_id FROM ad_process WHERE value = 'AbERP_RosteringChat_Close' LIMIT 1;

  SELECT ad_process_para_id INTO v_para_id
  FROM ad_process_para
  WHERE ad_process_id = v_process_id AND columnname = 'R_Request_ID'
  LIMIT 1;

  IF v_para_id IS NULL THEN
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_process_id, seqno,
      ad_reference_id, columnname, iscentrallymaintained,
      fieldlength, ismandatory, isrange, entitytype,
      defaultvalue, displaylogic, isencrypted,
      ad_process_para_uu
    ) VALUES (
      (SELECT COALESCE(MAX(ad_process_para_id), 0) + 1 FROM ad_process_para),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Chat', 'Chat thread to close',
      v_process_id, 5,
      19, 'R_Request_ID', 'N',
      22, 'Y', 'N', 'Ab_ERP',
      '@R_Request_ID@', '@0@=1', 'N',
      substring(md5('AbERP_RosteringChat_Close-para-req'), 1, 8) || '-' ||
      substring(md5('AbERP_RosteringChat_Close-para-req'), 9, 4) || '-4f13-8513-000000000013'
    );
  ELSE
    UPDATE ad_process_para
    SET isactive = 'Y', defaultvalue = '@R_Request_ID@', ismandatory = 'Y',
        displaylogic = '@0@=1', updated = NOW(), updatedby = 100
    WHERE ad_process_para_id = v_para_id;
  END IF;
END $$;

-- Keep Reply field editable on form
UPDATE ad_field f
SET isreadonly = 'N', isupdateable = 'Y', isdisplayed = 'Y',
    updated = NOW(), updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname = 'AbERP_RosteringReply';

-- Sync sequences
UPDATE ad_sequence s
SET currentnext = GREATEST(s.currentnext, COALESCE((SELECT MAX(r_request_id)+s.incrementno FROM r_request), s.currentnext))
WHERE s.name = 'R_Request';
UPDATE ad_sequence s
SET currentnext = GREATEST(s.currentnext, COALESCE((SELECT MAX(r_requestupdate_id)+s.incrementno FROM r_requestupdate), s.currentnext))
WHERE s.name = 'R_RequestUpdate';

SELECT 'updates' AS check_type, t.ad_column_id, t.parent_column_id, t.whereclause, t.issinglerow
FROM ad_tab t JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Updates';

SELECT 'paras' AS check_type, p.value, pp.seqno, pp.columnname, pp.defaultvalue, pp.ismandatory, pp.displaylogic
FROM ad_process p
JOIN ad_process_para pp ON pp.ad_process_id = p.ad_process_id AND pp.isactive = 'Y'
WHERE p.value IN ('AbERP_RosteringChat_Send', 'AbERP_RosteringChat_Close')
ORDER BY p.value, pp.seqno;
