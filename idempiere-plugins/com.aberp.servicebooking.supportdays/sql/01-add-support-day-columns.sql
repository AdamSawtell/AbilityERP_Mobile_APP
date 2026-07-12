-- SAW009: physical columns + AD_Column for C_OrderLine Support Start/End Day
-- Display uses the same List as AbERP_ServicePattern.AbERP_RosterStartDay/EndDay
-- ("14 Day Roster Period" → names like 02 - Monday / 09 - Monday).
-- Stored value = list Value (pattern day number as text: '1'..'15'), not weekday-only text.
--
-- HCO / multi-client: if AD_Column already exists by ColumnName with a different UU,
-- UPDATE properties only — NEVER overwrite ad_column_uu.
SET search_path TO adempiere;

ALTER TABLE c_orderline
  ADD COLUMN IF NOT EXISTS aberp_support_start_day VARCHAR(5);

ALTER TABLE c_orderline
  ADD COLUMN IF NOT EXISTS aberp_support_end_day VARCHAR(5);

DO $$
DECLARE
  v_table NUMERIC;
  v_ref NUMERIC;
  v_el_start NUMERIC;
  v_el_end NUMERIC;
  v_seq_col INTEGER;
  v_uu_start CONSTANT VARCHAR := 'c0a90001-50a9-4009-a001-000000000001';
  v_uu_end   CONSTANT VARCHAR := 'c0a90002-50a9-4009-a001-000000000002';
BEGIN
  SELECT ad_table_id INTO v_table
  FROM ad_table
  WHERE ad_table_uu = 'fbab5be2-21b0-4f4f-b070-cd9d77efa238'
     OR tablename = 'C_OrderLine'
  LIMIT 1;
  IF v_table IS NULL THEN
    RAISE EXCEPTION 'C_OrderLine not found';
  END IF;

  SELECT ad_reference_id INTO v_ref
  FROM ad_reference
  WHERE ad_reference_uu = '5ec1b0b5-7ce8-43dc-bf9d-77bc2d7afbbd';
  IF v_ref IS NULL THEN
    RAISE EXCEPTION '14 Day Roster Period reference UU not found';
  END IF;

  SELECT ad_element_id INTO v_el_start
  FROM ad_element
  WHERE ad_element_uu = 'ac9cf459-1755-4dfb-b46d-22091027402b'
     OR columnname = 'AbERP_Support_Start_Day'
  LIMIT 1;

  SELECT ad_element_id INTO v_el_end
  FROM ad_element
  WHERE ad_element_uu = 'fbe588b0-561d-437c-b84d-4328185f0e9b'
     OR columnname = 'AbERP_Support_End_Day'
  LIMIT 1;

  SELECT ad_sequence_id::integer INTO v_seq_col
  FROM ad_sequence
  WHERE name = 'AD_Column' AND istableid = 'Y'
  LIMIT 1;

  -- Support Start Day
  IF EXISTS (SELECT 1 FROM ad_column WHERE ad_column_uu = v_uu_start) THEN
    UPDATE ad_column SET
      name = 'Support Start Day',
      columnname = 'AbERP_Support_Start_Day',
      ad_table_id = v_table,
      ad_reference_id = 17,
      ad_reference_value_id = v_ref,
      fieldlength = GREATEST(fieldlength, 5),
      ad_element_id = v_el_start,
      entitytype = 'Ab_ERP',
      isupdateable = 'Y',
      ismandatory = 'N',
      isactive = 'Y',
      updated = NOW(),
      updatedby = 100
    WHERE ad_column_uu = v_uu_start;
  ELSIF EXISTS (
    SELECT 1 FROM ad_column
    WHERE ad_table_id = v_table AND columnname = 'AbERP_Support_Start_Day'
  ) THEN
    -- Keep client UU (HCO already has these columns).
    UPDATE ad_column SET
      name = 'Support Start Day',
      ad_reference_id = 17,
      ad_reference_value_id = v_ref,
      fieldlength = GREATEST(fieldlength, 5),
      ad_element_id = v_el_start,
      entitytype = 'Ab_ERP',
      isupdateable = 'Y',
      ismandatory = 'N',
      isactive = 'Y',
      columnsql = NULL,
      updated = NOW(),
      updatedby = 100
    WHERE ad_table_id = v_table AND columnname = 'AbERP_Support_Start_Day';
    RAISE NOTICE 'SAW009: kept existing AD_Column UU for AbERP_Support_Start_Day (did not overwrite)';
  ELSE
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, version, entitytype,
      columnname, ad_table_id, ad_reference_id, ad_reference_value_id,
      fieldlength, iskey, isparent, ismandatory, isupdateable,
      isidentifier, seqno, istranslated, isencrypted, isselectioncolumn,
      ad_element_id, issyncdatabase, isalwaysupdateable,
      isallowlogging, isallowcopy, seqnoselection, istoolbarbutton, issecure,
      ad_column_uu
    ) VALUES (
      nextid(v_seq_col, 'N'::varchar),
      0, 0, 'Y',
      NOW(), 100, NOW(), 100,
      'Support Start Day',
      'Service pattern start day (numbered day within the pattern)',
      'Same list as Booking Generator Service Pattern Start Day (14 Day Roster Period), e.g. 02 - Monday / 09 - Monday.',
      0, 'Ab_ERP',
      'AbERP_Support_Start_Day', v_table, 17, v_ref,
      5, 'N', 'N', 'N', 'Y',
      'N', 0, 'N', 'N', 'N',
      v_el_start, 'Y', 'N',
      'Y', 'Y', 0, 'N', 'N',
      v_uu_start
    );
  END IF;

  -- Support End Day
  IF EXISTS (SELECT 1 FROM ad_column WHERE ad_column_uu = v_uu_end) THEN
    UPDATE ad_column SET
      name = 'Support End Day',
      columnname = 'AbERP_Support_End_Day',
      ad_table_id = v_table,
      ad_reference_id = 17,
      ad_reference_value_id = v_ref,
      fieldlength = GREATEST(fieldlength, 5),
      ad_element_id = v_el_end,
      entitytype = 'Ab_ERP',
      isupdateable = 'Y',
      ismandatory = 'N',
      isactive = 'Y',
      updated = NOW(),
      updatedby = 100
    WHERE ad_column_uu = v_uu_end;
  ELSIF EXISTS (
    SELECT 1 FROM ad_column
    WHERE ad_table_id = v_table AND columnname = 'AbERP_Support_End_Day'
  ) THEN
    UPDATE ad_column SET
      name = 'Support End Day',
      ad_reference_id = 17,
      ad_reference_value_id = v_ref,
      fieldlength = GREATEST(fieldlength, 5),
      ad_element_id = v_el_end,
      entitytype = 'Ab_ERP',
      isupdateable = 'Y',
      ismandatory = 'N',
      isactive = 'Y',
      columnsql = NULL,
      updated = NOW(),
      updatedby = 100
    WHERE ad_table_id = v_table AND columnname = 'AbERP_Support_End_Day';
    RAISE NOTICE 'SAW009: kept existing AD_Column UU for AbERP_Support_End_Day (did not overwrite)';
  ELSE
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, version, entitytype,
      columnname, ad_table_id, ad_reference_id, ad_reference_value_id,
      fieldlength, iskey, isparent, ismandatory, isupdateable,
      isidentifier, seqno, istranslated, isencrypted, isselectioncolumn,
      ad_element_id, issyncdatabase, isalwaysupdateable,
      isallowlogging, isallowcopy, seqnoselection, istoolbarbutton, issecure,
      ad_column_uu
    ) VALUES (
      nextid(v_seq_col, 'N'::varchar),
      0, 0, 'Y',
      NOW(), 100, NOW(), 100,
      'Support End Day',
      'Service pattern end day (numbered day within the pattern)',
      'Same list as Booking Generator Service Pattern End Day (14 Day Roster Period), e.g. 02 - Monday / 09 - Monday.',
      0, 'Ab_ERP',
      'AbERP_Support_End_Day', v_table, 17, v_ref,
      5, 'N', 'N', 'N', 'Y',
      'N', 0, 'N', 'N', 'N',
      v_el_end, 'Y', 'N',
      'Y', 'Y', 0, 'N', 'N',
      v_uu_end
    );
  END IF;
END $$;
