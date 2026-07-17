-- =============================================================================
-- SAW028 — Fix Activity Links display (real-column DisplayLogic + placement)
-- Hidden virtual ColumnSQL IDs often never enter WebUI context, so buttons stay hidden.
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_tab INTEGER;
  v_fg INTEGER;
BEGIN
  SELECT ad_tab_id INTO v_tab FROM ad_tab WHERE ad_tab_uu = '86e6abdc-cd6e-4003-bbcb-860df46ed682';
  IF v_tab IS NULL THEN
    SELECT t.ad_tab_id INTO v_tab
    FROM ad_tab t
    JOIN ad_window w ON w.ad_window_id = t.ad_window_id
    WHERE w.ad_window_uu = 'e5e62a4b-bd38-49d6-b2e7-e5a44e194b0e'
       OR w.name = 'Activity Viewer'
    ORDER BY t.seqno
    LIMIT 1;
  END IF;
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'SAW028-17: Activity Viewer tab missing';
  END IF;

  SELECT ad_fieldgroup_id INTO v_fg FROM ad_fieldgroup
  WHERE ad_fieldgroup_uu = '28a028fg-0001-4f01-8e15-000000000001'
     OR (name = 'Activity Links' AND entitytype = 'Ab_ERP')
  LIMIT 1;

  -- Place links early (after Comments) so the group is visible without scrolling past AD5 fields
  UPDATE ad_field SET
    name = 'Client',
    seqno = 112,
    seqnogrid = 112,
    issameline = 'N',
    xposition = 1,
    columnspan = 2,
    displaylogic = '@C_BPartner_ID@>0',
    ad_fieldgroup_id = v_fg,
    isdisplayed = 'Y',
    istoolbarbutton = 'B',
    updated = NOW()
  WHERE ad_field_uu = '28a02851-b001-4f01-8e15-000000000001'
     OR (ad_tab_id = v_tab AND name = 'Client' AND ad_column_id IN (
          SELECT ad_column_id FROM ad_column WHERE columnname = 'AbERP_OpenClient'));

  -- Link Employee ID must be on-tab and "displayed" (with 1=2) so WebUI loads
  -- ColumnSQL into context — IsDisplayed=N virtuals often never evaluate DisplayLogic.
  UPDATE ad_field SET
    name = 'Link Employee ID',
    seqno = 993,
    seqnogrid = 993,
    isdisplayed = 'Y',
    isdisplayedgrid = 'N',
    isreadonly = 'Y',
    displaylogic = '1=2',
    ad_fieldgroup_id = NULL,
    updated = NOW()
  WHERE ad_field_uu = '28a02851-f002-4f01-8e15-000000000001'
     OR (ad_tab_id = v_tab AND ad_column_id IN (
          SELECT ad_column_id FROM ad_column WHERE columnname = 'AbERP_LinkEmployee_ID'));

  UPDATE ad_field SET
    name = 'Link Client ID',
    seqno = 992,
    seqnogrid = 992,
    isdisplayed = 'Y',
    isdisplayedgrid = 'N',
    isreadonly = 'Y',
    displaylogic = '1=2',
    ad_fieldgroup_id = NULL,
    updated = NOW()
  WHERE ad_field_uu = '28a02851-f001-4f01-8e15-000000000001'
     OR (ad_tab_id = v_tab AND ad_column_id IN (
          SELECT ad_column_id FROM ad_column WHERE columnname = 'AbERP_LinkClient_ID'));

  UPDATE ad_field SET
    name = 'Employee',
    seqno = 114,
    seqnogrid = 114,
    issameline = 'Y',
    xposition = 4,
    columnspan = 2,
    -- LinkEmployee ColumnSQL when loaded; also AbERP_User_BP_ID / Staff (fields on tab)
    displaylogic = '@AbERP_LinkEmployee_ID@>0 | @AbERP_User_BP_ID@>0 | @C_BPartner_Staff_ID@>0',
    ad_fieldgroup_id = v_fg,
    isdisplayed = 'Y',
    istoolbarbutton = 'B',
    updated = NOW()
  WHERE ad_field_uu = '28a02851-b002-4f01-8e15-000000000001'
     OR (ad_tab_id = v_tab AND name = 'Employee' AND ad_column_id IN (
          SELECT ad_column_id FROM ad_column WHERE columnname = 'AbERP_OpenEmployee'));

  UPDATE ad_field SET
    name = 'Support Location',
    seqno = 116,
    seqnogrid = 116,
    issameline = 'Y',
    xposition = 7,
    columnspan = 2,
    displaylogic = '@AbERP_Support_Location_ID@>0',
    ad_fieldgroup_id = v_fg,
    isdisplayed = 'Y',
    istoolbarbutton = 'B',
    updated = NOW()
  WHERE ad_field_uu = '28a02851-b003-4f01-8e15-000000000001'
     OR (ad_tab_id = v_tab AND ad_column_id IN (
          SELECT ad_column_id FROM ad_column WHERE columnname = 'AbERP_OpenSupportLocation'));

  -- Also tighten Client button to resolved client BP when helper is available
  UPDATE ad_field SET
    displaylogic = '@AbERP_LinkClient_ID@>0',
    updated = NOW()
  WHERE ad_field_uu = '28a02851-b001-4f01-8e15-000000000001'
     OR (ad_tab_id = v_tab AND ad_column_id IN (
          SELECT ad_column_id FROM ad_column WHERE columnname = 'AbERP_OpenClient'));

  RAISE NOTICE 'SAW028-17 Activity Links display fixed (tab=%)', v_tab;
END $$;
