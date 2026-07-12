-- SAW009: AD_Field on Service Booking → Service Booking Line
-- Resolve columns by owned UU first, else by ColumnName (keep client column UU).
-- If a field already exists on the tab for that column, update it — do not overwrite field UU.
SET search_path TO adempiere;

DO $$
DECLARE
  v_tab NUMERIC;
  v_col_start NUMERIC;
  v_col_end NUMERIC;
  v_seq_field INTEGER;
  v_field NUMERIC;
  v_uu_f_start CONSTANT VARCHAR := 'c0a90003-50a9-4009-a001-000000000003';
  v_uu_f_end   CONSTANT VARCHAR := 'c0a90004-50a9-4009-a001-000000000004';
  v_uu_c_start CONSTANT VARCHAR := 'c0a90001-50a9-4009-a001-000000000001';
  v_uu_c_end   CONSTANT VARCHAR := 'c0a90002-50a9-4009-a001-000000000002';
BEGIN
  SELECT ad_tab_id INTO v_tab
  FROM ad_tab
  WHERE ad_tab_uu = '8b044105-bc30-4f81-b0d6-a45835d82f98';
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'Service Booking Line tab not found';
  END IF;

  SELECT ad_column_id INTO v_col_start
  FROM ad_column WHERE ad_column_uu = v_uu_c_start;
  IF v_col_start IS NULL THEN
    SELECT c.ad_column_id INTO v_col_start
    FROM ad_column c
    JOIN ad_table t ON t.ad_table_id = c.ad_table_id
    WHERE t.tablename = 'C_OrderLine' AND c.columnname = 'AbERP_Support_Start_Day';
  END IF;
  IF v_col_start IS NULL THEN
    RAISE EXCEPTION 'AD_Column AbERP_Support_Start_Day on C_OrderLine not found — run 01 first';
  END IF;

  SELECT ad_column_id INTO v_col_end
  FROM ad_column WHERE ad_column_uu = v_uu_c_end;
  IF v_col_end IS NULL THEN
    SELECT c.ad_column_id INTO v_col_end
    FROM ad_column c
    JOIN ad_table t ON t.ad_table_id = c.ad_table_id
    WHERE t.tablename = 'C_OrderLine' AND c.columnname = 'AbERP_Support_End_Day';
  END IF;
  IF v_col_end IS NULL THEN
    RAISE EXCEPTION 'AD_Column AbERP_Support_End_Day on C_OrderLine not found — run 01 first';
  END IF;

  SELECT ad_sequence_id::integer INTO v_seq_field
  FROM ad_sequence
  WHERE name = 'AD_Field' AND istableid = 'Y'
  LIMIT 1;

  -- Support Start Day field
  SELECT ad_field_id INTO v_field FROM ad_field WHERE ad_field_uu = v_uu_f_start;
  IF v_field IS NULL THEN
    SELECT ad_field_id INTO v_field
    FROM ad_field
    WHERE ad_tab_id = v_tab AND ad_column_id = v_col_start
    LIMIT 1;
  END IF;

  IF v_field IS NOT NULL THEN
    UPDATE ad_field SET
      name = 'Support Start Day',
      ad_tab_id = v_tab,
      ad_column_id = v_col_start,
      isdisplayed = 'Y',
      isdisplayedgrid = 'Y',
      seqno = 405,
      seqnogrid = 405,
      isreadonly = 'N',
      isactive = 'Y',
      entitytype = 'Ab_ERP',
      updated = NOW(),
      updatedby = 100
    WHERE ad_field_id = v_field;
    -- do not set ad_field_uu
  ELSE
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, iscentrallymaintained,
      ad_tab_id, ad_column_id, isdisplayed, displaylength,
      isreadonly, seqno, sortno, entitytype, isdisplayedgrid,
      seqnogrid, xposition, columnspan, numlines, isquickentry,
      isupdateable, isheading, isfieldonly, isencrypted,
      ad_field_uu
    ) VALUES (
      nextid(v_seq_field, 'N'::varchar),
      0, 0, 'Y',
      NOW(), 100, NOW(), 100,
      'Support Start Day',
      'Service pattern start day (numbered day within the pattern)',
      'Displays the same numbered day as Booking Generator Service Pattern Start Day.',
      'Y',
      v_tab, v_col_start, 'Y', 20,
      'N', 405, NULL, 'Ab_ERP', 'Y',
      405, 1, 2, 1, 'N',
      'Y', 'N', 'N', 'N',
      v_uu_f_start
    );
  END IF;

  -- Support End Day field
  v_field := NULL;
  SELECT ad_field_id INTO v_field FROM ad_field WHERE ad_field_uu = v_uu_f_end;
  IF v_field IS NULL THEN
    SELECT ad_field_id INTO v_field
    FROM ad_field
    WHERE ad_tab_id = v_tab AND ad_column_id = v_col_end
    LIMIT 1;
  END IF;

  IF v_field IS NOT NULL THEN
    UPDATE ad_field SET
      name = 'Support End Day',
      ad_tab_id = v_tab,
      ad_column_id = v_col_end,
      isdisplayed = 'Y',
      isdisplayedgrid = 'Y',
      seqno = 410,
      seqnogrid = 410,
      isreadonly = 'N',
      isactive = 'Y',
      entitytype = 'Ab_ERP',
      updated = NOW(),
      updatedby = 100
    WHERE ad_field_id = v_field;
  ELSE
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, iscentrallymaintained,
      ad_tab_id, ad_column_id, isdisplayed, displaylength,
      isreadonly, seqno, sortno, entitytype, isdisplayedgrid,
      seqnogrid, xposition, columnspan, numlines, isquickentry,
      isupdateable, isheading, isfieldonly, isencrypted,
      ad_field_uu
    ) VALUES (
      nextid(v_seq_field, 'N'::varchar),
      0, 0, 'Y',
      NOW(), 100, NOW(), 100,
      'Support End Day',
      'Service pattern end day (numbered day within the pattern)',
      'Displays the same numbered day as Booking Generator Service Pattern End Day.',
      'Y',
      v_tab, v_col_end, 'Y', 20,
      'N', 410, NULL, 'Ab_ERP', 'Y',
      410, 4, 2, 1, 'N',
      'Y', 'N', 'N', 'N',
      v_uu_f_end
    );
  END IF;
END $$;
