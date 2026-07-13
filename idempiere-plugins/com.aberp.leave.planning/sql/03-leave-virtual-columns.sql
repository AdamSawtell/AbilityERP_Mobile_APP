-- =============================================================================
-- SAW016 — Virtual display columns on AbERP_Unavailability_Leave (planning tab)
-- Hidden on Unavailability & Leave windows; shown only on Leave Planning Leave tab.
-- =============================================================================
SET search_path TO adempiere;

CREATE OR REPLACE FUNCTION pg_temp.saw016_upsert_leave_col(
  p_uu TEXT,
  p_columnname TEXT,
  p_name TEXT,
  p_ref INTEGER,
  p_ref_value INTEGER,
  p_fieldlength INTEGER,
  p_columnsql TEXT,
  p_isselection CHAR DEFAULT 'N'
) RETURNS void AS $$
DECLARE
  v_table_id INTEGER;
  v_col_id INTEGER;
  v_el INTEGER;
BEGIN
  SELECT ad_table_id INTO v_table_id FROM ad_table WHERE tablename = 'AbERP_Unavailability_Leave';
  IF v_table_id IS NULL THEN
    RAISE EXCEPTION 'AbERP_Unavailability_Leave missing';
  END IF;

  SELECT ad_element_id INTO v_el FROM ad_element WHERE columnname = p_columnname LIMIT 1;
  IF v_el IS NULL THEN
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, ad_element_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_columnname, 'Ab_ERP', p_name, p_name,
      '16a01600-0000-4001-8000-' || lpad(substr(md5(p_columnname), 1, 12), 12, '0')
    ) RETURNING ad_element_id INTO v_el;
  END IF;

  SELECT ad_column_id INTO v_col_id FROM ad_column WHERE ad_column_uu = p_uu;
  IF v_col_id IS NULL THEN
    SELECT ad_column_id INTO v_col_id FROM ad_column
    WHERE ad_table_id = v_table_id AND columnname = p_columnname;
  END IF;

  IF v_col_id IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, version, entitytype, columnname, ad_table_id,
      ad_reference_id, ad_reference_value_id, fieldlength,
      iskey, isparent, ismandatory, isupdateable, isidentifier, seqno,
      istranslated, isencrypted, isselectioncolumn, ad_element_id,
      issyncdatabase, isalwaysupdateable, columnsql,
      isallowcopy, istoolbarbutton, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, 0, 'Ab_ERP', p_columnname, v_table_id,
      p_ref, p_ref_value, p_fieldlength,
      'N', 'N', 'N', 'N', 'N', 999,
      'N', 'N', p_isselection, v_el,
      'Y', 'N', p_columnsql,
      'N', 'N', p_uu
    );
  ELSE
    UPDATE ad_column SET
      name = p_name,
      columnsql = p_columnsql,
      ad_reference_id = p_ref,
      ad_reference_value_id = p_ref_value,
      fieldlength = p_fieldlength,
      isupdateable = 'N',
      isselectioncolumn = p_isselection,
      entitytype = 'Ab_ERP',
      ad_column_uu = COALESCE(ad_column_uu, p_uu),
      updated = NOW(),
      updatedby = 100
    WHERE ad_column_id = v_col_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  -- Employee Number = AD_User.Value
  PERFORM pg_temp.saw016_upsert_leave_col(
    '16a016lc-0001-4f01-8e15-000000000001',
    'AbERP_LP_EmployeeNumber', 'Employee Number', 10, NULL, 40,
    '(SELECT u.Value FROM AD_User u WHERE u.AD_User_ID=AbERP_Unavailability_Leave.AbERP_User_Contact_ID)',
    'Y'
  );

  -- Service Location = Partner Location name on the employee user
  PERFORM pg_temp.saw016_upsert_leave_col(
    '16a016lc-0002-4f01-8e15-000000000001',
    'AbERP_LP_ServiceLocation', 'Service Location', 10, NULL, 120,
    '(SELECT bpl.Name FROM AD_User u JOIN C_BPartner_Location bpl ON bpl.C_BPartner_Location_ID=u.C_BPartner_Location_ID WHERE u.AD_User_ID=AbERP_Unavailability_Leave.AbERP_User_Contact_ID)',
    'Y'
  );

  -- Calendar Days (inclusive date span)
  PERFORM pg_temp.saw016_upsert_leave_col(
    '16a016lc-0003-4f01-8e15-000000000001',
    'AbERP_LP_CalendarDays', 'Calendar Days', 11, NULL, 10,
    '((AbERP_Unavailability_Leave.EndDate::date - AbERP_Unavailability_Leave.StartDate::date) + 1)',
    'N'
  );

  -- Ensure selection columns on leave for Find filters
  UPDATE ad_column c SET isselectioncolumn = 'Y', updated = NOW(), updatedby = 100
  FROM ad_table t
  WHERE t.ad_table_id = c.ad_table_id
    AND t.tablename = 'AbERP_Unavailability_Leave'
    AND c.columnname IN (
      'AbERP_User_Contact_ID',
      'AbERP_Unavailability_Type_ID',
      'AbERP_ApproverStatus',
      'AbERP_SubmitterStatus',
      'StartDate',
      'EndDate'
    );

  RAISE NOTICE 'SAW016 leave virtual columns ready';
END $$;
