-- =============================================================================
-- SAW016 — Leave Planning: AD Table + Columns (header)
-- Fixed UU: Table 16a01601-c0d4-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

CREATE OR REPLACE FUNCTION pg_temp.saw016_upsert_column(
  p_table_id INTEGER,
  p_uu TEXT,
  p_columnname TEXT,
  p_name TEXT,
  p_ref INTEGER,
  p_ref_value INTEGER,
  p_mandatory CHAR,
  p_updateable CHAR,
  p_seqno INTEGER,
  p_fieldlength INTEGER,
  p_columnsql TEXT DEFAULT NULL,
  p_isselection CHAR DEFAULT 'N',
  p_val_rule INTEGER DEFAULT NULL,
  p_isparent CHAR DEFAULT 'N',
  p_iskey CHAR DEFAULT 'N',
  p_isidentifier CHAR DEFAULT 'N'
) RETURNS void AS $$
DECLARE
  v_col_id INTEGER;
  v_el INTEGER;
BEGIN
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
      '16a01600-0000-4000-8000-' || lpad(substr(md5(p_columnname), 1, 12), 12, '0')
    ) RETURNING ad_element_id INTO v_el;
  END IF;

  SELECT ad_column_id INTO v_col_id FROM ad_column WHERE ad_column_uu = p_uu;
  IF v_col_id IS NULL THEN
    SELECT ad_column_id INTO v_col_id FROM ad_column
    WHERE ad_table_id = p_table_id AND columnname = p_columnname;
  END IF;

  IF v_col_id IS NULL THEN
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, version, entitytype, columnname, ad_table_id,
      ad_reference_id, ad_reference_value_id, ad_val_rule_id,
      fieldlength, iskey, isparent, ismandatory, isupdateable,
      isidentifier, seqno, istranslated, isencrypted, isselectioncolumn,
      ad_element_id, issyncdatabase, isalwaysupdateable,
      columnsql, isallowcopy, seqnoselection,
      istoolbarbutton, isautocomplete, ad_column_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, 0, 'Ab_ERP', p_columnname, p_table_id,
      p_ref, p_ref_value, p_val_rule,
      p_fieldlength, p_iskey, p_isparent, p_mandatory,
      CASE WHEN p_columnsql IS NOT NULL THEN 'N' ELSE p_updateable END,
      p_isidentifier, p_seqno, 'N', 'N', p_isselection,
      v_el, 'Y', 'N',
      p_columnsql, 'Y', p_seqno, 'N', 'N', p_uu
    );
  ELSE
    UPDATE ad_column SET
      name = p_name,
      ad_reference_id = p_ref,
      ad_reference_value_id = p_ref_value,
      ad_val_rule_id = p_val_rule,
      fieldlength = p_fieldlength,
      ismandatory = p_mandatory,
      isupdateable = CASE WHEN p_columnsql IS NOT NULL THEN 'N' ELSE p_updateable END,
      isidentifier = p_isidentifier,
      iskey = p_iskey,
      isparent = p_isparent,
      isselectioncolumn = p_isselection,
      columnsql = p_columnsql,
      entitytype = 'Ab_ERP',
      ad_column_uu = COALESCE(ad_column_uu, p_uu),
      updated = NOW(),
      updatedby = 100
    WHERE ad_column_id = v_col_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_table_uu CONSTANT TEXT := '16a01601-c0d4-4f01-8e15-000000000001';
  v_table_id INTEGER;
  v_ref_approver INTEGER;
  v_ref_bpl INTEGER;
  v_val_loc INTEGER;
  v_sum_status TEXT;
  v_sum_type TEXT;
BEGIN
  SELECT ad_reference_id INTO v_ref_approver
  FROM ad_reference WHERE name = 'AbERP_ApproverStatus_List' LIMIT 1;
  IF v_ref_approver IS NULL THEN
    RAISE EXCEPTION 'SAW016: AbERP_ApproverStatus_List reference missing';
  END IF;

  SELECT ad_reference_id INTO v_ref_bpl
  FROM ad_reference
  WHERE ad_reference_uu = '68166de3-765e-44a8-bee6-fc57170b70d8'
     OR name = 'C_BPartner Location'
  LIMIT 1;
  IF v_ref_bpl IS NULL THEN
    RAISE EXCEPTION 'SAW016: C_BPartner Location reference missing';
  END IF;

  SELECT ad_val_rule_id INTO v_val_loc
  FROM ad_val_rule WHERE ad_val_rule_uu = '16a01606-c0d4-4f01-8e15-000000000001';
  IF v_val_loc IS NULL THEN
    INSERT INTO ad_val_rule (
      ad_val_rule_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, type, code, entitytype, ad_val_rule_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Val_Rule' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP Leave Planning Support Locations',
      'Active Support Locations only (same filter as Support Location window)',
      'S',
      'C_BPartner_Location.C_BPartner_Location_ID IN (SELECT C_BPartner_Location_ID FROM AbERP_Support_Location WHERE IsActive=''Y'' AND C_BPartner_Location_ID IS NOT NULL)',
      'Ab_ERP',
      '16a01606-c0d4-4f01-8e15-000000000001'
    ) RETURNING ad_val_rule_id INTO v_val_loc;
  END IF;

  SELECT ad_table_id INTO v_table_id FROM ad_table WHERE ad_table_uu = v_table_uu;
  IF v_table_id IS NULL THEN
    SELECT ad_table_id INTO v_table_id FROM ad_table WHERE tablename = 'AbERP_Leave_Planning';
  END IF;

  IF v_table_id IS NULL THEN
    INSERT INTO ad_table (
      ad_table_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, tablename,
      isview, accesslevel, entitytype, ad_window_id,
      issecurityenabled, isdeleteable, ishighvolume, importtable,
      ischangelog, replicationtype, ad_table_uu,
      copycolumnsfromtable, iscentrallymaintained
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Table' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Leave Planning',
      'Workforce leave planning criteria (date range + service locations)',
      'Select a planning period and service locations to review overlapping leave.',
      'AbERP_Leave_Planning',
      'N', '3', 'Ab_ERP', NULL,
      'N', 'Y', 'N', 'N',
      'Y', 'L', v_table_uu,
      'N', 'Y'
    ) RETURNING ad_table_id INTO v_table_id;
  ELSE
    UPDATE ad_table SET
      name = 'Leave Planning',
      description = 'Workforce leave planning criteria (date range + service locations)',
      entitytype = 'Ab_ERP',
      accesslevel = '3',
      ad_table_uu = COALESCE(ad_table_uu, v_table_uu),
      updated = NOW(),
      updatedby = 100
    WHERE ad_table_id = v_table_id;
  END IF;

  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0001-4f01-8e15-000000000001','AbERP_Leave_Planning_ID','Leave Planning',13,NULL,'Y','N',0,22,NULL,'N',NULL,'N','Y','N');
  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0002-4f01-8e15-000000000001','AD_Client_ID','Client',19,NULL,'Y','N',10,22,NULL,'N',129,'N','N','N');
  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0003-4f01-8e15-000000000001','AD_Org_ID','Organization',19,NULL,'Y','N',20,22,NULL,'N',104,'N','N','N');
  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0004-4f01-8e15-000000000001','IsActive','Active',20,NULL,'Y','Y',30,1,NULL,'N',NULL,'N','N','N');
  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0005-4f01-8e15-000000000001','Created','Created',16,NULL,'Y','N',40,7,NULL,'N',NULL,'N','N','N');
  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0006-4f01-8e15-000000000001','CreatedBy','Created By',18,110,'Y','N',50,22,NULL,'N',NULL,'N','N','N');
  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0007-4f01-8e15-000000000001','Updated','Updated',16,NULL,'Y','N',60,7,NULL,'N',NULL,'N','N','N');
  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0008-4f01-8e15-000000000001','UpdatedBy','Updated By',18,110,'Y','N',70,22,NULL,'N',NULL,'N','N','N');
  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0009-4f01-8e15-000000000001','AbERP_Leave_Planning_UU','AbERP_Leave_Planning_UU',10,NULL,'N','Y',80,36,NULL,'N',NULL,'N','N','N');
  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0010-4f01-8e15-000000000001','Name','Name',10,NULL,'N','Y',90,120,NULL,'Y',NULL,'N','N','Y');
  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0011-4f01-8e15-000000000001','StartDate','Start Date',15,NULL,'Y','Y',100,7,NULL,'Y',NULL,'N','N','N');
  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0012-4f01-8e15-000000000001','EndDate','End Date',15,NULL,'Y','Y',110,7,NULL,'Y',NULL,'N','N','N');
  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0013-4f01-8e15-000000000001','IsAllLocations','All Locations',20,NULL,'Y','Y',120,1,NULL,'N',NULL,'N','N','N');
  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0014-4f01-8e15-000000000001','C_BPartner_Location_IDs','Service Locations',200162,v_ref_bpl,'N','Y',130,4000,NULL,'N',v_val_loc,'N','N','N');
  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0015-4f01-8e15-000000000001','AbERP_FilterApproverStatus','Filter Approver Status',17,v_ref_approver,'N','Y',140,4,NULL,'Y',NULL,'N','N','N');
  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0016-4f01-8e15-000000000001','AbERP_FilterUnavailability_Type_ID','Filter Leave Type',19,NULL,'N','Y',150,22,NULL,'Y',NULL,'N','N','N');

  v_sum_status := 'aberp_lp_summary_by_status(AbERP_Leave_Planning.AbERP_Leave_Planning_ID)';
  v_sum_type := 'aberp_lp_summary_by_type(AbERP_Leave_Planning.AbERP_Leave_Planning_ID)';

  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0017-4f01-8e15-000000000001','AbERP_SummaryByStatus','Summary by Approver Status',14,NULL,'N','N',160,2000,v_sum_status,'N',NULL,'N','N','N');
  PERFORM pg_temp.saw016_upsert_column(v_table_id,'16a016c0-0018-4f01-8e15-000000000001','AbERP_SummaryByType','Summary by Status + Leave Type',14,NULL,'N','N',170,4000,v_sum_type,'N',NULL,'N','N','N');

  RAISE NOTICE 'SAW016 AD table/columns ready (table_id=%)', v_table_id;
END $$;
