-- =============================================================================
-- Rostering Chat — portable Application Dictionary install
-- =============================================================================
-- New window for rostering officers to manage mobile app chat threads.
-- Uses R_Request + R_RequestUpdate (same architecture as mobile Tasks API).
--
-- Run after JAR deploy:
--   psql -v ON_ERROR_STOP=1 -d idempiere -f install-rostering-chat.sql
--
-- Then restart iDempiere and log out/in on WebUI.
-- =============================================================================

SET search_path TO adempiere;

-- ---------------------------------------------------------------------------
-- 0. Request type — Rostering Chat (dedicated mobile chat threads)
-- ---------------------------------------------------------------------------
INSERT INTO r_requesttype (
  r_requesttype_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, description, isdefault, isselfservice,
  duedatetolerance, isemailwhenoverdue, isemailwhendue, isinvoiced,
  autoduedatedays, confidentialtype, isautochangerequest, isconfidentialinfo,
  r_statuscategory_id, isindexed, r_requesttype_uu,
  aberp_isrequest
)
SELECT
  (SELECT COALESCE(MAX(r_requesttype_id), 0) + 1 FROM r_requesttype),
  1000002, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Rostering Chat',
  'Mobile worker ↔ rostering officer chat thread (PWA Tasks page).',
  'N', 'Y',
  7, 'N', 'N', 'N',
  0, 'I', 'N', 'N',
  1000000, 'N',
  (
    substring(md5('AbERP_RosteringChat-requesttype'), 1, 8) || '-' ||
    substring(md5('AbERP_RosteringChat-requesttype'), 9, 4) || '-4c01-8100-000000000001'
  ),
  'Y'
WHERE NOT EXISTS (
  SELECT 1 FROM r_requesttype WHERE name = 'Rostering Chat'
);

UPDATE r_requesttype
SET isactive = 'Y',
    description = 'Mobile worker ↔ rostering officer chat thread (PWA Tasks page).',
    isselfservice = 'Y',
    aberp_isrequest = 'Y',
    updated = NOW(),
    updatedby = 100
WHERE name = 'Rostering Chat';

-- Role access for the new request type
INSERT INTO aberp_requesttype_role (
  aberp_requesttype_role_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, description, value, r_requesttype_id, ad_role_id,
  aberp_requesttype_role_uu
)
SELECT
  base.max_id + ROW_NUMBER() OVER (ORDER BY roles.ad_role_id),
  1000002, 0, 'Y',
  NOW(), 100, NOW(), 100,
  '', '', (base.max_id + ROW_NUMBER() OVER (ORDER BY roles.ad_role_id))::VARCHAR,
  rt.r_requesttype_id,
  roles.ad_role_id,
  (
    substring(md5('AbERP_RosteringChat-role-' || roles.ad_role_id::TEXT), 1, 8) || '-' ||
    substring(md5('AbERP_RosteringChat-role-' || roles.ad_role_id::TEXT), 9, 4) || '-4c02-8100-000000000002'
  )
FROM r_requesttype rt
CROSS JOIN (SELECT COALESCE(MAX(aberp_requesttype_role_id), 0) AS max_id FROM aberp_requesttype_role) base
CROSS JOIN (
  SELECT ad_role_id FROM ad_role
  WHERE name IN (
    'Rostering Officer', 'AbilityERP Admin', 'System Administrator', 'Support Worker'
  ) AND isactive = 'Y'
) roles
WHERE rt.name = 'Rostering Chat' AND rt.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM aberp_requesttype_role atr
    WHERE atr.r_requesttype_id = rt.r_requesttype_id
      AND atr.ad_role_id = roles.ad_role_id
      AND atr.isactive = 'Y'
  );

-- Move existing mobile chat threads off generic Action type
UPDATE r_request r
SET r_requesttype_id = rt.r_requesttype_id,
    updated = NOW(),
    updatedby = 100
FROM r_requesttype rt
WHERE rt.name = 'Rostering Chat' AND rt.isactive = 'Y'
  AND r.isactive = 'Y'
  AND r.aberp_rostered_shift_id IS NULL
  AND r.summary = 'Message to Rostering'
  AND r.r_requesttype_id <> rt.r_requesttype_id;

-- ---------------------------------------------------------------------------
-- 0b. Prerequisites
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_request_table_id INTEGER;
  v_source_window_id INTEGER;
  v_request_type_id INTEGER;
BEGIN
  SELECT ad_table_id INTO v_request_table_id
  FROM ad_table WHERE tablename = 'R_Request' AND isactive = 'Y' LIMIT 1;
  IF v_request_table_id IS NULL THEN
    RAISE EXCEPTION 'Table R_Request not found';
  END IF;

  SELECT w.ad_window_id INTO v_source_window_id
  FROM ad_window w
  JOIN ad_tab t ON t.ad_window_id = w.ad_window_id AND t.isactive = 'Y' AND t.tablevel = 0
  JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
  WHERE tb.tablename = 'R_Request' AND w.isactive = 'Y' AND w.name <> 'Rostering Chat'
  ORDER BY w.ad_window_id ASC
  LIMIT 1;
  IF v_source_window_id IS NULL THEN
    RAISE EXCEPTION 'Source Request window not found (need an existing R_Request window to clone fields from)';
  END IF;

  SELECT r_requesttype_id INTO v_request_type_id
  FROM r_requesttype
  WHERE name = 'Rostering Chat' AND isactive = 'Y'
  LIMIT 1;

  IF v_request_type_id IS NULL THEN
    RAISE EXCEPTION 'Request type Rostering Chat not found — section 0 install failed';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Window
-- ---------------------------------------------------------------------------
INSERT INTO ad_window (
  ad_window_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, description, help, windowtype, issotrx,
  entitytype, processing, isdefault, winheight, winwidth,
  isbetafunctionality, ad_window_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_window_id), 0) + 1 FROM ad_window),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Rostering Chat',
  'Mobile worker chat threads between the PWA Tasks page and rostering officers.',
  'Filtered view of R_Request records with request type Rostering Chat. Type a reply in Last Result, then Send to Worker; Updates tab shows history.',
  'M', 'Y',
  'Ab_ERP', 'N', 'N', 0, 0,
  'N',
  (
    substring(md5('AbERP_RosteringChat-window'), 1, 8) || '-' ||
    substring(md5('AbERP_RosteringChat-window'), 9, 4) || '-4a01-8001-000000000001'
  )
WHERE NOT EXISTS (
  SELECT 1 FROM ad_window WHERE name = 'Rostering Chat'
);

UPDATE ad_window
SET isactive = 'Y',
    description = 'Mobile worker chat threads between the PWA Tasks page and rostering officers.',
    updated = NOW(),
    updatedby = 100
WHERE name = 'Rostering Chat';

-- ---------------------------------------------------------------------------
-- 2. Header tab (R_Request) with filter
-- ---------------------------------------------------------------------------
INSERT INTO ad_tab (
  ad_tab_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, description, ad_table_id, ad_window_id, seqno, tablevel,
  issinglerow, isinfotab, istranslationtab, isreadonly,
  ad_column_id, hastree, processing, importfields,
  issorttab, entitytype, isinsertrecord, isadvancedtab,
  parent_column_id, whereclause, orderbyclause,
  treedisplayedon, islookuponlyselection, isallowadvancedlookup,
  ad_tab_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_tab_id), 0) + 1 FROM ad_tab),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Chat', 'Mobile rostering chat threads', tb.ad_table_id, w.ad_window_id, 10, 0,
  'N', 'N', 'N', 'N',
  NULL, 'N', 'N', 'N',
  'N', 'Ab_ERP', 'N', 'N',
  NULL,
  'R_Request.R_RequestType_ID=0',
  'R_Request.DateLastAction DESC NULLS LAST, R_Request.Updated DESC',
  'B', 'N', 'Y',
  (
    substring(md5('AbERP_RosteringChat-header-tab'), 1, 8) || '-' ||
    substring(md5('AbERP_RosteringChat-header-tab'), 9, 4) || '-4a02-8002-000000000002'
  )
FROM ad_window w
CROSS JOIN ad_table tb
WHERE w.name = 'Rostering Chat'
  AND tb.tablename = 'R_Request' AND tb.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_tab t
    WHERE t.ad_window_id = w.ad_window_id AND t.name = 'Chat' AND t.tablevel = 0
  );

DO $$
DECLARE
  v_type_id INTEGER;
  v_where TEXT;
BEGIN
  SELECT rt.r_requesttype_id INTO v_type_id
  FROM r_requesttype rt
  WHERE rt.name = 'Rostering Chat' AND rt.isactive = 'Y'
  LIMIT 1;

  IF v_type_id IS NULL THEN
    RAISE EXCEPTION 'Request type Rostering Chat not found for tab filter';
  END IF;

  v_where := 'R_Request.R_RequestType_ID=' || v_type_id;

  UPDATE ad_tab t
  SET whereclause = v_where,
      orderbyclause = 'R_Request.DateLastAction DESC NULLS LAST, R_Request.Updated DESC',
      isinsertrecord = 'N',
      isreadonly = 'N',
      issinglerow = 'Y',
      updated = NOW(),
      updatedby = 100
  FROM ad_window w
  WHERE t.ad_window_id = w.ad_window_id
    AND w.name = 'Rostering Chat' AND t.name = 'Chat' AND t.tablevel = 0;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Updates tab (R_RequestUpdate) — read-only history
-- ---------------------------------------------------------------------------
INSERT INTO ad_tab (
  ad_tab_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, description, ad_table_id, ad_window_id, seqno, tablevel,
  issinglerow, isinfotab, istranslationtab, isreadonly,
  ad_column_id, hastree, processing, importfields,
  issorttab, entitytype, isinsertrecord, isadvancedtab,
  parent_column_id, whereclause, orderbyclause,
  treedisplayedon, islookuponlyselection, isallowadvancedlookup,
  ad_tab_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_tab_id), 0) + 1 FROM ad_tab),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Updates', 'Chat message history', utb.ad_table_id, w.ad_window_id, 20, 1,
  'N', 'N', 'N', 'Y',
  link_col.ad_column_id, 'N', 'N', 'N',
  'N', 'Ab_ERP', 'N', 'N',
  link_col.ad_column_id, NULL, 'R_RequestUpdate.Created ASC',
  'B', 'N', 'Y',
  (
    substring(md5('AbERP_RosteringChat-updates-tab'), 1, 8) || '-' ||
    substring(md5('AbERP_RosteringChat-updates-tab'), 9, 4) || '-4a03-8003-000000000003'
  )
FROM ad_window w
CROSS JOIN ad_table utb
CROSS JOIN ad_table rtb
JOIN ad_column link_col ON link_col.ad_table_id = utb.ad_table_id AND link_col.columnname = 'R_Request_ID'
WHERE w.name = 'Rostering Chat'
  AND utb.tablename = 'R_RequestUpdate' AND utb.isactive = 'Y'
  AND rtb.tablename = 'R_Request' AND rtb.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_tab t
    WHERE t.ad_window_id = w.ad_window_id AND t.name = 'Updates'
  );

UPDATE ad_tab t
SET isreadonly = 'Y',
    isinsertrecord = 'N',
    orderbyclause = 'R_RequestUpdate.Created ASC',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id AND w.name = 'Rostering Chat' AND t.name = 'Updates';

-- ---------------------------------------------------------------------------
-- 4. Header fields (minimal set for rostering inbox)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_header_tab_id INTEGER;
  v_source_tab_id INTEGER;
  v_seq INTEGER := 10;
  v_col TEXT;
    v_cols TEXT[] := ARRAY[
    'DocumentNo', 'Summary', 'R_Status_ID', 'AD_User_ID', 'C_BPartner_ID',
    'LastResult', 'DateLastAction', 'Created', 'Updated', 'SalesRep_ID'
  ];
  v_readonly TEXT;
  v_display_grid TEXT;
BEGIN
  SELECT t.ad_tab_id INTO v_header_tab_id
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE w.name = 'Rostering Chat' AND t.name = 'Chat' AND t.tablevel = 0
  LIMIT 1;

  SELECT t.ad_tab_id INTO v_source_tab_id
  FROM ad_window w
  JOIN ad_tab t ON t.ad_window_id = w.ad_window_id AND t.isactive = 'Y' AND t.tablevel = 0
  JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
  WHERE tb.tablename = 'R_Request' AND w.isactive = 'Y' AND w.name <> 'Rostering Chat'
  ORDER BY w.ad_window_id ASC
  LIMIT 1;

  IF v_header_tab_id IS NULL THEN
    RAISE EXCEPTION 'Rostering Chat header tab not found';
  END IF;

  FOREACH v_col IN ARRAY v_cols LOOP
    v_display_grid := CASE
      WHEN v_col IN ('DocumentNo', 'Summary', 'R_Status_ID', 'AD_User_ID', 'LastResult', 'DateLastAction', 'Updated')
        THEN 'Y'
      ELSE 'N'
    END;

    v_readonly := 'Y';

    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, iscentrallymaintained,
      ad_tab_id, ad_column_id,
      isdisplayed, displaylength, isreadonly, seqno,
      issameline, isheading, isfieldonly, isencrypted, entitytype,
      isdisplayedgrid, xposition, numlines, columnspan,
      isquickentry, istoolbarbutton, isadvancedfield, isdefaultfocus,
      ad_field_uu
    )
    SELECT
      (SELECT COALESCE(MAX(ad_field_id), 0) + 1 FROM ad_field),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      COALESCE(sf.name, c.name), sf.description, sf.help, 'N',
      v_header_tab_id, c.ad_column_id,
      'Y', COALESCE(sf.displaylength, 0), v_readonly, v_seq,
      CASE WHEN v_col IN ('DateLastAction', 'Updated', 'SalesRep_ID') THEN 'Y' ELSE 'N' END,
      'N', 'N', 'N', 'Ab_ERP',
      v_display_grid, COALESCE(sf.xposition, 1), COALESCE(sf.numlines, 1), COALESCE(sf.columnspan, 1),
      'N', 'N', 'N', 'N',
      (
        substring(md5('AbERP_RosteringChat-field-' || v_col), 1, 8) || '-' ||
        substring(md5('AbERP_RosteringChat-field-' || v_col), 9, 4) || '-4a04-8004-' || lpad(v_seq::text, 12, '0')
      )
    FROM ad_column c
    JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id AND tb.tablename = 'R_Request'
    LEFT JOIN ad_field sf ON sf.ad_tab_id = v_source_tab_id AND sf.ad_column_id = c.ad_column_id AND sf.isactive = 'Y'
    WHERE c.columnname = v_col AND c.isactive = 'Y'
      AND NOT EXISTS (
        SELECT 1 FROM ad_field f
        WHERE f.ad_tab_id = v_header_tab_id AND f.ad_column_id = c.ad_column_id
      );

    v_seq := v_seq + 10;
  END LOOP;

  UPDATE ad_field f
  SET isreadonly = 'Y',
      isdisplayed = 'Y',
      isdisplayedgrid = 'Y',
      numlines = 2,
      columnspan = 3,
      isdefaultfocus = 'N',
      name = 'Last Result',
      description = 'Last message on this thread (updated when you Send to Worker).',
      updated = NOW(),
      updatedby = 100
  FROM ad_column c
  WHERE f.ad_column_id = c.ad_column_id
    AND f.ad_tab_id = v_header_tab_id
    AND c.columnname = 'LastResult';
END $$;

-- Last Result must be updateable at column level (core Request windows mark it read-only on field)
UPDATE ad_column c
SET isupdateable = 'Y',
    isalwaysupdateable = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_table tb
WHERE c.ad_table_id = tb.ad_table_id
  AND tb.tablename = 'R_Request'
  AND c.columnname = 'LastResult';

UPDATE ad_tab t
SET issinglerow = 'Y',
    isreadonly = 'N',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
  WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat'
  AND t.tablevel = 0;

-- ---------------------------------------------------------------------------
-- 5. Updates tab fields (read-only message history)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_updates_tab_id INTEGER;
  v_source_updates_tab_id INTEGER;
  v_seq INTEGER := 10;
  v_col TEXT;
  v_cols TEXT[] := ARRAY['Created', 'CreatedBy', 'Result'];
BEGIN
  SELECT t.ad_tab_id INTO v_updates_tab_id
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE w.name = 'Rostering Chat' AND t.name = 'Updates'
  LIMIT 1;

  SELECT t.ad_tab_id INTO v_source_updates_tab_id
  FROM ad_tab t
  JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
  WHERE tb.tablename = 'R_RequestUpdate' AND t.isactive = 'Y'
  ORDER BY t.ad_tab_id ASC
  LIMIT 1;

  IF v_updates_tab_id IS NULL THEN
    RAISE EXCEPTION 'Rostering Chat Updates tab not found';
  END IF;

  FOREACH v_col IN ARRAY v_cols LOOP
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
      COALESCE(sf.name, c.name), 'N', v_updates_tab_id, c.ad_column_id,
      'Y', COALESCE(sf.displaylength, 0), 'Y', v_seq,
      CASE WHEN v_col = 'CreatedBy' THEN 'Y' ELSE 'N' END,
      'N', 'N', 'N', 'Ab_ERP',
      'Y', COALESCE(sf.xposition, 1),
      CASE WHEN v_col = 'Result' THEN 5 ELSE COALESCE(sf.numlines, 1) END,
      CASE WHEN v_col = 'Result' THEN 5 ELSE COALESCE(sf.columnspan, 1) END,
      'N', 'N',
      (
        substring(md5('AbERP_RosteringChat-upd-field-' || v_col), 1, 8) || '-' ||
        substring(md5('AbERP_RosteringChat-upd-field-' || v_col), 9, 4) || '-4a05-8005-' || lpad(v_seq::text, 12, '0')
      )
    FROM ad_column c
    JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id AND tb.tablename = 'R_RequestUpdate'
    LEFT JOIN ad_field sf ON sf.ad_tab_id = v_source_updates_tab_id AND sf.ad_column_id = c.ad_column_id AND sf.isactive = 'Y'
    WHERE c.columnname = v_col AND c.isactive = 'Y'
      AND NOT EXISTS (
        SELECT 1 FROM ad_field f
        WHERE f.ad_tab_id = v_updates_tab_id AND f.ad_column_id = c.ad_column_id
      );

    v_seq := v_seq + 10;
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- 6. Processes
-- ---------------------------------------------------------------------------
INSERT INTO ad_process (
  ad_process_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  value, name, description,
  accesslevel, entitytype,
  isreport, isdirectprint,
  classname,
  isbetafunctionality, isserverprocess, showhelp,
  copyfromprocess, ad_process_uu,
  allowmultipleexecution, isprinterpreview
)
SELECT
  (SELECT COALESCE(MAX(ad_process_id), 0) + 1 FROM ad_process),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'ROSTERING_CHAT_REPLY', 'Send to Worker',
  'Send the Last Result reply to the worker: creates an update, assigns the worker as User/Contact, and clears Role.',
  '3', 'Ab_ERP',
  'N', 'N',
  'com.aberp.rostering.chat.process.SendRosteringReply',
  'N', 'N', 'S',
  'N',
  (
    substring(md5('ROSTERING_CHAT_REPLY-process'), 1, 8) || '-' ||
    substring(md5('ROSTERING_CHAT_REPLY-process'), 9, 4) || '-4b01-8101-000000000001'
  ),
  'P', 'N'
WHERE NOT EXISTS (
  SELECT 1 FROM ad_process WHERE value = 'ROSTERING_CHAT_REPLY'
);

INSERT INTO ad_process (
  ad_process_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  value, name, description,
  accesslevel, entitytype,
  isreport, isdirectprint,
  classname,
  isbetafunctionality, isserverprocess, showhelp,
  copyfromprocess, ad_process_uu,
  allowmultipleexecution, isprinterpreview
)
SELECT
  (SELECT COALESCE(MAX(ad_process_id), 0) + 1 FROM ad_process),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'ROSTERING_CHAT_CLOSE', 'Close Chat',
  'Close this mobile chat thread. The worker gets a fresh thread on their next message.',
  '3', 'Ab_ERP',
  'N', 'N',
  'com.aberp.rostering.chat.process.CloseRosteringChat',
  'N', 'N', 'S',
  'N',
  (
    substring(md5('ROSTERING_CHAT_CLOSE-process'), 1, 8) || '-' ||
    substring(md5('ROSTERING_CHAT_CLOSE-process'), 9, 4) || '-4b02-8102-000000000002'
  ),
  'P', 'N'
WHERE NOT EXISTS (
  SELECT 1 FROM ad_process WHERE value = 'ROSTERING_CHAT_CLOSE'
);

-- Send to Worker: no parameter dialog (reply typed in Last Result field)
UPDATE ad_process
SET name = 'Send to Worker',
    description = 'Send the Last Result reply to the worker: creates an update, assigns the worker as User/Contact, and clears Role.',
    showhelp = 'S',
    updated = NOW(),
    updatedby = 100
WHERE value = 'ROSTERING_CHAT_REPLY';

UPDATE ad_process_para pp
SET isactive = 'N', updated = NOW(), updatedby = 100
FROM ad_process p
WHERE pp.ad_process_id = p.ad_process_id
  AND p.value = 'ROSTERING_CHAT_REPLY'
  AND pp.columnname = 'Message';

UPDATE ad_element
SET name = 'Send to Worker', printname = 'Send to Worker', updated = NOW(), updatedby = 100
WHERE columnname = 'AbERP_SendRosteringReply';

-- ---------------------------------------------------------------------------
-- 7. Button columns on R_Request
-- ---------------------------------------------------------------------------
ALTER TABLE r_request
  ADD COLUMN IF NOT EXISTS aberp_sendrosteringreply character(1);

ALTER TABLE r_request
  ADD COLUMN IF NOT EXISTS aberp_closerosteringchat character(1);

ALTER TABLE r_request
  ADD COLUMN IF NOT EXISTS aberp_rosteringreply VARCHAR(2000);

INSERT INTO ad_element (
  ad_element_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  columnname, entitytype, name, printname, ad_element_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_element_id), 0) + 1 FROM ad_element),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'AbERP_RosteringReply', 'Ab_ERP', 'Reply', 'Reply',
  (
    substring(md5('AbERP_RosteringReply-element'), 1, 8) || '-' ||
    substring(md5('AbERP_RosteringReply-element'), 9, 4) || '-4c04-8204-000000000004'
  )
WHERE NOT EXISTS (
  SELECT 1 FROM ad_element WHERE columnname = 'AbERP_RosteringReply'
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
  ad_column_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_column_id), 0) + 1 FROM ad_column),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'Reply', 'Ab_ERP', 'AbERP_RosteringReply', tb.ad_table_id,
  COALESCE(
    (SELECT ad_reference_id FROM ad_reference WHERE name = 'Text' AND isactive = 'Y' LIMIT 1),
    14
  ),
  2000, 0,
  'N', 'N', 'N', 'Y', 'N', 0,
  'N', 'N', 'N',
  e.ad_element_id, 'Y', 'Y',
  'N', 'Y', 'Y',
  'N', 'N', 'N', 'N',
  (
    substring(md5('AbERP_RosteringReply-col'), 1, 8) || '-' ||
    substring(md5('AbERP_RosteringReply-col'), 9, 4) || '-4c05-8205-000000000005'
  )
FROM ad_element e
CROSS JOIN ad_table tb
WHERE e.columnname = 'AbERP_RosteringReply'
  AND tb.tablename = 'R_Request' AND tb.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_column c
    WHERE c.columnname = 'AbERP_RosteringReply' AND c.ad_table_id = tb.ad_table_id
  );

UPDATE ad_column c
SET isupdateable = 'Y', isalwaysupdateable = 'Y', updated = NOW(), updatedby = 100
FROM ad_table tb, ad_element e
WHERE c.ad_table_id = tb.ad_table_id AND tb.tablename = 'R_Request'
  AND c.ad_element_id = e.ad_element_id AND e.columnname = 'AbERP_RosteringReply';

INSERT INTO ad_element (
  ad_element_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  columnname, entitytype, name, printname, ad_element_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_element_id), 0) + 1 FROM ad_element),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'AbERP_SendRosteringReply', 'Ab_ERP', 'Send to Worker', 'Send to Worker',
  (
    substring(md5('AbERP_SendRosteringReply-element'), 1, 8) || '-' ||
    substring(md5('AbERP_SendRosteringReply-element'), 9, 4) || '-4c01-8201-000000000001'
  )
WHERE NOT EXISTS (
  SELECT 1 FROM ad_element WHERE columnname = 'AbERP_SendRosteringReply'
);

INSERT INTO ad_element (
  ad_element_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  columnname, entitytype, name, printname, ad_element_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_element_id), 0) + 1 FROM ad_element),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'AbERP_CloseRosteringChat', 'Ab_ERP', 'Close Chat', 'Close Chat',
  (
    substring(md5('AbERP_CloseRosteringChat-element'), 1, 8) || '-' ||
    substring(md5('AbERP_CloseRosteringChat-element'), 9, 4) || '-4c02-8202-000000000002'
  )
WHERE NOT EXISTS (
  SELECT 1 FROM ad_element WHERE columnname = 'AbERP_CloseRosteringChat'
);

INSERT INTO ad_column (
  ad_column_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, entitytype, columnname, ad_table_id,
  ad_reference_id, fieldlength, version,
  iskey, isparent, ismandatory, isupdateable, isidentifier, seqno,
  istranslated, isencrypted, isselectioncolumn,
  ad_element_id, ad_process_id, issyncdatabase, isalwaysupdateable,
  isautocomplete, isallowlogging, isallowcopy,
  istoolbarbutton, issecure, fkconstrainttype, ishtml,
  ad_column_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_column_id), 0) + 1 FROM ad_column),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'Send to Worker', 'Ab_ERP', 'AbERP_SendRosteringReply', tb.ad_table_id,
  COALESCE(
    (SELECT ad_reference_id FROM ad_reference WHERE name = 'Button' AND isactive = 'Y' LIMIT 1),
    28
  ),
  1, 0,
  'N', 'N', 'N', 'Y', 'N', 0,
  'N', 'N', 'N',
  e.ad_element_id, p.ad_process_id, 'Y', 'N',
  'N', 'Y', 'N',
  'B', 'N', 'N', 'N',
  (
    substring(md5('AbERP_SendRosteringReply-col'), 1, 8) || '-' ||
    substring(md5('AbERP_SendRosteringReply-col'), 9, 4) || '-4c03-8203-000000000003'
  )
FROM ad_element e
JOIN ad_process p ON p.value = 'ROSTERING_CHAT_REPLY'
CROSS JOIN ad_table tb
WHERE e.columnname = 'AbERP_SendRosteringReply'
  AND tb.tablename = 'R_Request' AND tb.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_column c
    WHERE c.columnname = 'AbERP_SendRosteringReply' AND c.ad_table_id = tb.ad_table_id
  );

INSERT INTO ad_column (
  ad_column_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, entitytype, columnname, ad_table_id,
  ad_reference_id, fieldlength, version,
  iskey, isparent, ismandatory, isupdateable, isidentifier, seqno,
  istranslated, isencrypted, isselectioncolumn,
  ad_element_id, ad_process_id, issyncdatabase, isalwaysupdateable,
  isautocomplete, isallowlogging, isallowcopy,
  istoolbarbutton, issecure, fkconstrainttype, ishtml,
  ad_column_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_column_id), 0) + 1 FROM ad_column),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'Close Chat', 'Ab_ERP', 'AbERP_CloseRosteringChat', tb.ad_table_id,
  COALESCE(
    (SELECT ad_reference_id FROM ad_reference WHERE name = 'Button' AND isactive = 'Y' LIMIT 1),
    28
  ),
  1, 0,
  'N', 'N', 'N', 'Y', 'N', 0,
  'N', 'N', 'N',
  e.ad_element_id, p.ad_process_id, 'Y', 'N',
  'N', 'Y', 'N',
  'B', 'N', 'N', 'N',
  (
    substring(md5('AbERP_CloseRosteringChat-col'), 1, 8) || '-' ||
    substring(md5('AbERP_CloseRosteringChat-col'), 9, 4) || '-4c04-8204-000000000004'
  )
FROM ad_element e
JOIN ad_process p ON p.value = 'ROSTERING_CHAT_CLOSE'
CROSS JOIN ad_table tb
WHERE e.columnname = 'AbERP_CloseRosteringChat'
  AND tb.tablename = 'R_Request' AND tb.isactive = 'Y'
  AND NOT EXISTS (
    SELECT 1 FROM ad_column c
    WHERE c.columnname = 'AbERP_CloseRosteringChat' AND c.ad_table_id = tb.ad_table_id
  );

-- Editable Reply field (compose message here) — after AbERP_RosteringReply column exists
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
    isdisplayed, displaylength, isreadonly, seqno,
    issameline, isheading, isfieldonly, isencrypted, entitytype,
    isdisplayedgrid, xposition, numlines, columnspan,
    isquickentry, istoolbarbutton, isadvancedfield, isdefaultfocus,
    isupdateable, ad_field_uu
  )
  SELECT
    (SELECT COALESCE(MAX(ad_field_id), 0) + 1 FROM ad_field),
    0, 0, 'Y', NOW(), 100, NOW(), 100,
    'Reply', 'Type your reply here, then click Send to Worker.', 'N',
    v_header_tab_id, c.ad_column_id,
    'Y', 0, 'N', 55,
    'N', 'N', 'N', 'N', 'Ab_ERP',
    'Y', 1, 3, 3,
    'N', 'N', 'N', 'Y',
    'Y',
    (
      substring(md5('AbERP_RosteringReply-field'), 1, 8) || '-' ||
      substring(md5('AbERP_RosteringReply-field'), 9, 4) || '-4c06-8206-000000000006'
    )
  FROM ad_column c
  JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id AND tb.tablename = 'R_Request'
  WHERE c.columnname = 'AbERP_RosteringReply' AND c.isactive = 'Y'
    AND NOT EXISTS (
      SELECT 1 FROM ad_field f
      WHERE f.ad_tab_id = v_header_tab_id AND f.ad_column_id = c.ad_column_id
    );

  UPDATE ad_field f
  SET isreadonly = 'N',
      isupdateable = 'Y',
      isdisplayed = 'Y',
      isdisplayedgrid = 'Y',
      numlines = 3,
      columnspan = 3,
      isdefaultfocus = 'Y',
      name = 'Reply',
      description = 'Type your reply here, then click Send to Worker.',
      updated = NOW(),
      updatedby = 100
  FROM ad_column c
  WHERE f.ad_column_id = c.ad_column_id
    AND f.ad_tab_id = v_header_tab_id
    AND c.columnname = 'AbERP_RosteringReply';
END $$;

-- Button fields on Chat tab
DO $$
DECLARE
  v_closed_status_id INTEGER;
  v_closed_logic TEXT;
BEGIN
  SELECT r_status_id INTO v_closed_status_id
  FROM r_status WHERE isactive = 'Y' AND name = 'Closed'
  ORDER BY r_status_id ASC LIMIT 1;
  v_closed_logic := COALESCE(v_closed_status_id::TEXT, '102');

  INSERT INTO ad_field (
    ad_field_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby,
    name, iscentrallymaintained, ad_tab_id, ad_column_id,
    isdisplayed, displaylogic, displaylength, isreadonly, seqno,
    issameline, isheading, isfieldonly, isencrypted, entitytype,
    isdisplayedgrid, xposition, numlines, columnspan,
    isquickentry, istoolbarbutton, isdefaultfocus, ad_field_uu
  )
  SELECT
    (SELECT COALESCE(MAX(ad_field_id), 0) + 1 FROM ad_field),
    0, 0, 'Y', NOW(), 100, NOW(), 100,
    'Send to Worker', 'N', tab.ad_tab_id, c.ad_column_id,
    'Y', '@R_Status_ID@<>' || v_closed_logic, 1, 'N', 120,
    'N', 'N', 'N', 'N', 'Ab_ERP',
    'Y', 1, 1, 2,
    'N', 'N', 'Y',
    (
      substring(md5('AbERP_SendRosteringReply-field'), 1, 8) || '-' ||
      substring(md5('AbERP_SendRosteringReply-field'), 9, 4) || '-4d01-8301-000000000001'
    )
  FROM ad_column c
  CROSS JOIN ad_table tb
  JOIN ad_tab tab ON tab.ad_table_id = tb.ad_table_id
  JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
  WHERE c.columnname = 'AbERP_SendRosteringReply'
    AND c.ad_table_id = tb.ad_table_id
    AND tb.tablename = 'R_Request'
    AND w.name = 'Rostering Chat' AND tab.name = 'Chat'
    AND NOT EXISTS (
      SELECT 1 FROM ad_field f
      WHERE f.ad_tab_id = tab.ad_tab_id AND f.ad_column_id = c.ad_column_id
    );

  INSERT INTO ad_field (
    ad_field_id, ad_client_id, ad_org_id, isactive,
    created, createdby, updated, updatedby,
    name, iscentrallymaintained, ad_tab_id, ad_column_id,
    isdisplayed, displaylogic, displaylength, isreadonly, seqno,
    issameline, isheading, isfieldonly, isencrypted, entitytype,
    isdisplayedgrid, xposition, numlines, columnspan,
    isquickentry, istoolbarbutton, ad_field_uu
  )
  SELECT
    (SELECT COALESCE(MAX(ad_field_id), 0) + 1 FROM ad_field),
    0, 0, 'Y', NOW(), 100, NOW(), 100,
    'Close Chat', 'N', tab.ad_tab_id, c.ad_column_id,
    'Y', '@R_Status_ID@<>' || v_closed_logic, 1, 'N', 120,
    'Y', 'N', 'N', 'N', 'Ab_ERP',
    'Y', 3, 1, 2,
    'N', 'N',
    (
      substring(md5('AbERP_CloseRosteringChat-field'), 1, 8) || '-' ||
      substring(md5('AbERP_CloseRosteringChat-field'), 9, 4) || '-4d02-8302-000000000002'
    )
  FROM ad_column c
  CROSS JOIN ad_table tb
  JOIN ad_tab tab ON tab.ad_table_id = tb.ad_table_id
  JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
  WHERE c.columnname = 'AbERP_CloseRosteringChat'
    AND c.ad_table_id = tb.ad_table_id
    AND tb.tablename = 'R_Request'
    AND w.name = 'Rostering Chat' AND tab.name = 'Chat'
    AND NOT EXISTS (
      SELECT 1 FROM ad_field f
      WHERE f.ad_tab_id = tab.ad_tab_id AND f.ad_column_id = c.ad_column_id
    );

  UPDATE ad_field f
  SET displaylogic = '@R_Status_ID@<>' || v_closed_logic,
      isdisplayed = 'Y',
      isdisplayedgrid = 'Y',
      name = CASE WHEN c.columnname = 'AbERP_SendRosteringReply' THEN 'Send to Worker' ELSE f.name END,
      updated = NOW(),
      updatedby = 100
  FROM ad_tab tab
  JOIN ad_window w ON w.ad_window_id = tab.ad_window_id
  JOIN ad_column c ON c.columnname IN ('AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat')
  WHERE f.ad_tab_id = tab.ad_tab_id
    AND f.ad_column_id = c.ad_column_id
    AND w.name = 'Rostering Chat' AND tab.name = 'Chat';
END $$;

-- ---------------------------------------------------------------------------
-- 8. Process access
-- ---------------------------------------------------------------------------
INSERT INTO ad_process_access (
  ad_process_id, ad_role_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby, isreadwrite, ad_process_access_uu
)
SELECT p.ad_process_id, roles.ad_role_id, roles.ad_client_id, 0, 'Y',
  NOW(), 100, NOW(), 100, 'Y', NULL
FROM ad_process p
CROSS JOIN (
  SELECT ad_role_id, ad_client_id FROM ad_role
  WHERE name IN ('AbilityERP Admin', 'Rostering Officer') AND isactive = 'Y'
  UNION ALL
  SELECT 0, 0
) AS roles(ad_role_id, ad_client_id)
WHERE p.value IN ('ROSTERING_CHAT_REPLY', 'ROSTERING_CHAT_CLOSE')
  AND NOT EXISTS (
    SELECT 1 FROM ad_process_access x
    WHERE x.ad_process_id = p.ad_process_id
      AND x.ad_role_id = roles.ad_role_id
      AND x.ad_client_id = roles.ad_client_id
  );

-- ---------------------------------------------------------------------------
-- 9. Window access
-- ---------------------------------------------------------------------------
INSERT INTO ad_window_access (
  ad_window_id, ad_role_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby, isreadwrite, ad_window_access_uu
)
SELECT w.ad_window_id, roles.ad_role_id, roles.ad_client_id, 0, 'Y',
  NOW(), 100, NOW(), 100, 'Y', NULL
FROM ad_window w
CROSS JOIN (
  SELECT ad_role_id, ad_client_id FROM ad_role
  WHERE name IN ('AbilityERP Admin', 'Rostering Officer') AND isactive = 'Y'
  UNION ALL
  SELECT 0, 0
) AS roles(ad_role_id, ad_client_id)
WHERE w.name = 'Rostering Chat'
  AND NOT EXISTS (
    SELECT 1 FROM ad_window_access x
    WHERE x.ad_window_id = w.ad_window_id
      AND x.ad_role_id = roles.ad_role_id
      AND x.ad_client_id = roles.ad_client_id
  );

-- ---------------------------------------------------------------------------
-- 10. Menu entry (under same parent as Shift (Rostered))
-- ---------------------------------------------------------------------------
INSERT INTO ad_menu (
  ad_menu_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, description, issummary, issotrx, isreadonly,
  action, ad_window_id, entitytype, iscentrallymaintained,
  ad_menu_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_menu_id), 0) + 1 FROM ad_menu),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'Rostering Chat',
  'Mobile worker chat inbox for rostering officers',
  'N', 'Y', 'N',
  'W', w.ad_window_id, 'Ab_ERP', 'Y',
  (
    substring(md5('AbERP_RosteringChat-menu'), 1, 8) || '-' ||
    substring(md5('AbERP_RosteringChat-menu'), 9, 4) || '-4e01-8401-000000000001'
  )
FROM ad_window w
WHERE w.name = 'Rostering Chat'
  AND NOT EXISTS (
    SELECT 1 FROM ad_menu m WHERE m.name = 'Rostering Chat' AND m.action = 'W'
  );

UPDATE ad_menu m
SET ad_window_id = w.ad_window_id,
    isactive = 'Y',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE m.name = 'Rostering Chat' AND m.action = 'W' AND w.name = 'Rostering Chat';

-- Place menu in tree next to Shift (Rostered) when possible
DO $$
DECLARE
  v_shift_menu_id INTEGER;
  v_shift_parent_id INTEGER;
  v_shift_seq INTEGER;
  v_chat_menu_id INTEGER;
  v_tree_id INTEGER;
BEGIN
  SELECT m.ad_menu_id, tn.parent_id, tn.seqno, tn.ad_tree_id
  INTO v_shift_menu_id, v_shift_parent_id, v_shift_seq, v_tree_id
  FROM ad_menu m
  JOIN ad_window w ON w.ad_window_id = m.ad_window_id
  JOIN ad_treenodemm tn ON tn.node_id = m.ad_menu_id AND tn.isactive = 'Y'
  WHERE w.name = 'Shift (Rostered)' AND m.isactive = 'Y'
  LIMIT 1;

  SELECT ad_menu_id INTO v_chat_menu_id
  FROM ad_menu WHERE name = 'Rostering Chat' AND action = 'W' LIMIT 1;

  IF v_chat_menu_id IS NOT NULL AND v_shift_parent_id IS NOT NULL AND v_tree_id IS NOT NULL THEN
    INSERT INTO ad_treenodemm (
      ad_tree_id, node_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      parent_id, seqno, ad_treenodemm_uu
    )
    SELECT
      v_tree_id, v_chat_menu_id, 0, 0, 'Y',
      NOW(), 100, NOW(), 100,
      v_shift_parent_id, COALESCE(v_shift_seq, 0) + 5,
      (
        substring(md5('AbERP_RosteringChat-tree-' || v_chat_menu_id::text), 1, 8) || '-' ||
        substring(md5('AbERP_RosteringChat-tree-' || v_chat_menu_id::text), 9, 4) || '-4e02-8402-000000000002'
      )
    WHERE NOT EXISTS (
      SELECT 1 FROM ad_treenodemm tn
      WHERE tn.ad_tree_id = v_tree_id AND tn.node_id = v_chat_menu_id
    );

    UPDATE ad_treenodemm
    SET parent_id = v_shift_parent_id,
        seqno = COALESCE(v_shift_seq, 0) + 5,
        isactive = 'Y',
        updated = NOW(),
        updatedby = 100
    WHERE ad_tree_id = v_tree_id AND node_id = v_chat_menu_id;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 11. Verify
-- ---------------------------------------------------------------------------
SELECT 'Window' AS check_type, w.ad_window_id, w.name, w.isactive
FROM ad_window w WHERE w.name = 'Rostering Chat';

SELECT 'Tabs' AS check_type, w.name AS window_name, t.name AS tab_name, t.whereclause, t.orderbyclause
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat'
ORDER BY t.seqno;

SELECT 'Processes' AS check_type, p.value, p.classname, p.isactive
FROM ad_process p
WHERE p.value IN ('ROSTERING_CHAT_REPLY', 'ROSTERING_CHAT_CLOSE');

SELECT 'Process access' AS check_type, p.value, r.name AS role_name
FROM ad_process_access pa
JOIN ad_process p ON p.ad_process_id = pa.ad_process_id
JOIN ad_role r ON r.ad_role_id = pa.ad_role_id
WHERE p.value IN ('ROSTERING_CHAT_REPLY', 'ROSTERING_CHAT_CLOSE') AND pa.isactive = 'Y'
ORDER BY p.value, r.name;

SELECT 'Button fields' AS check_type, f.name, f.isdisplayed, f.displaylogic
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat'
  AND c.columnname IN ('AbERP_SendRosteringReply', 'AbERP_CloseRosteringChat');

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ad_window WHERE name = 'Rostering Chat' AND isactive = 'Y') THEN
    RAISE EXCEPTION 'Install FAILED: Rostering Chat window not created';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM ad_process WHERE value = 'ROSTERING_CHAT_REPLY' AND isactive = 'Y'
  ) THEN
    RAISE EXCEPTION 'Install FAILED: ROSTERING_CHAT_REPLY process not created';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM r_requesttype WHERE name = 'Rostering Chat' AND isactive = 'Y'
  ) THEN
    RAISE EXCEPTION 'Install FAILED: Rostering Chat request type not created';
  END IF;
  RAISE NOTICE 'Rostering Chat install completed successfully';
END $$;

SELECT 'Request type' AS check_type, rt.r_requesttype_id, rt.name, rt.isactive,
       (SELECT COUNT(*) FROM r_request r WHERE r.r_requesttype_id = rt.r_requesttype_id AND r.isactive = 'Y') AS thread_count
FROM r_requesttype rt
WHERE rt.name = 'Rostering Chat';
