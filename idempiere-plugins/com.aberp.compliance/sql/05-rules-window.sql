-- =============================================================================
-- SAW023 — Compliance Rules window (CRUD)
-- Window UU: 23a02306-c0d4-4f01-8e15-000000000001
-- Tab UU:    23a02316-c0d4-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_window_id),0)+1 FROM ad_window))
WHERE name='AD_Window' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_tab_id),0)+1 FROM ad_tab))
WHERE name='AD_Tab' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw023_field(
  p_tab_id INTEGER, p_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_seqno INTEGER, p_displayed CHAR, p_readonly CHAR DEFAULT 'N',
  p_sameline CHAR DEFAULT 'N', p_gridseq INTEGER DEFAULT NULL,
  p_displayedgrid CHAR DEFAULT NULL
) RETURNS void AS $$
DECLARE
  v_col_id INTEGER;
  v_field_id INTEGER;
  v_table_id INTEGER;
BEGIN
  SELECT ad_table_id INTO v_table_id FROM ad_tab WHERE ad_tab_id = p_tab_id;
  SELECT ad_column_id INTO v_col_id FROM ad_column
  WHERE ad_table_id = v_table_id AND columnname = p_columnname;
  IF v_col_id IS NULL THEN
    RAISE NOTICE 'SAW023 skip field % — column missing', p_columnname;
    RETURN;
  END IF;

  SELECT ad_field_id INTO v_field_id FROM ad_field WHERE ad_field_uu = p_uu;
  IF v_field_id IS NULL THEN
    SELECT ad_field_id INTO v_field_id FROM ad_field
    WHERE ad_tab_id = p_tab_id AND ad_column_id = v_col_id;
  END IF;

  IF v_field_id IS NULL THEN
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, iscentrallymaintained, ad_tab_id, ad_column_id,
      isdisplayed, displaylength, isreadonly, seqno, issameline,
      isheading, isfieldonly, isencrypted, entitytype,
      isdisplayedgrid, seqnogrid, xposition, columnspan, numlines, ad_field_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, 'Y', p_tab_id, v_col_id,
      p_displayed, 0, p_readonly, p_seqno, p_sameline,
      'N', 'N', 'N', 'Ab_ERP',
      COALESCE(p_displayedgrid, p_displayed), COALESCE(p_gridseq, p_seqno), 1, 2, 1, p_uu
    );
  ELSE
    UPDATE ad_field SET
      name = p_name,
      isdisplayed = p_displayed,
      isreadonly = p_readonly,
      seqno = p_seqno,
      issameline = p_sameline,
      isdisplayedgrid = COALESCE(p_displayedgrid, p_displayed),
      seqnogrid = COALESCE(p_gridseq, p_seqno),
      ad_field_uu = COALESCE(ad_field_uu, p_uu),
      updated = NOW()
    WHERE ad_field_id = v_field_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_window_uu CONSTANT TEXT := '23a02306-c0d4-4f01-8e15-000000000001';
  v_tab_uu    CONSTANT TEXT := '23a02316-c0d4-4f01-8e15-000000000001';
  v_window_id INTEGER;
  v_tab_id INTEGER;
  v_table_id INTEGER;
BEGIN
  SELECT ad_table_id INTO v_table_id FROM ad_table WHERE tablename = 'AbERP_ComplianceRule';
  IF v_table_id IS NULL THEN
    RAISE EXCEPTION 'SAW023: AbERP_ComplianceRule missing — run 03 first';
  END IF;

  SELECT ad_window_id INTO v_window_id FROM ad_window WHERE ad_window_uu = v_window_uu;
  IF v_window_id IS NULL THEN
    SELECT ad_window_id INTO v_window_id FROM ad_window WHERE name = 'Compliance Rules' AND entitytype = 'Ab_ERP';
  END IF;

  IF v_window_id IS NULL THEN
    INSERT INTO ad_window (
      ad_window_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, windowtype, issotrx,
      entitytype, processing, isdefault, isbetafunctionality, ad_window_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Window' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Compliance Rules',
      'Configure NDIS compliance audit rules',
      'Admin-maintained rules evaluated by the Refresh Compliance process. Category, severity, weight, and source table drive scoring and drill-down.',
      'M', 'N',
      'Ab_ERP', 'N', 'N', 'N', v_window_uu
    ) RETURNING ad_window_id INTO v_window_id;
  ELSE
    UPDATE ad_window SET
      name = 'Compliance Rules',
      description = 'Configure NDIS compliance audit rules',
      entitytype = 'Ab_ERP',
      ad_window_uu = COALESCE(ad_window_uu, v_window_uu),
      isactive = 'Y',
      updated = NOW()
    WHERE ad_window_id = v_window_id;
  END IF;

  UPDATE ad_table SET ad_window_id = v_window_id, updated = NOW()
  WHERE ad_table_id = v_table_id;

  SELECT ad_tab_id INTO v_tab_id FROM ad_tab WHERE ad_tab_uu = v_tab_uu;
  IF v_tab_id IS NULL THEN
    SELECT ad_tab_id INTO v_tab_id FROM ad_tab
    WHERE ad_window_id = v_window_id AND ad_table_id = v_table_id AND seqno = 10;
  END IF;

  IF v_tab_id IS NULL THEN
    INSERT INTO ad_tab (
      ad_tab_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_table_id, ad_window_id, seqno,
      tablevel, issinglerow, isinfotab, istranslationtab, isreadonly,
      hastree, processing, issorttab, entitytype, isinsertrecord, isadvancedtab, ad_tab_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Tab' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Compliance Rule', 'Rule definition',
      v_table_id, v_window_id, 10,
      0, 'Y', 'N', 'N', 'N',
      'N', 'N', 'N', 'Ab_ERP', 'Y', 'N', v_tab_uu
    ) RETURNING ad_tab_id INTO v_tab_id;
  END IF;

  PERFORM pg_temp.saw023_field(v_tab_id,'23a02316-f001-4f01-8e15-000000000001','AbERP_ComplianceRule_ID','Compliance Rule',0,'N','Y','N',0,'N');
  PERFORM pg_temp.saw023_field(v_tab_id,'23a02316-f002-4f01-8e15-000000000001','AD_Client_ID','Client',5,'N','Y','N',0,'N');
  PERFORM pg_temp.saw023_field(v_tab_id,'23a02316-f003-4f01-8e15-000000000001','AD_Org_ID','Organization',8,'N','N','N',0,'N');
  PERFORM pg_temp.saw023_field(v_tab_id,'23a02316-f004-4f01-8e15-000000000001','Name','Name',10,'Y','N','N',10,'Y');
  PERFORM pg_temp.saw023_field(v_tab_id,'23a02316-f005-4f01-8e15-000000000001','IsActive','Active',20,'Y','N','Y',20,'Y');
  PERFORM pg_temp.saw023_field(v_tab_id,'23a02316-f006-4f01-8e15-000000000001','ComplianceCategory','Category',30,'Y','N','N',30,'Y');
  PERFORM pg_temp.saw023_field(v_tab_id,'23a02316-f007-4f01-8e15-000000000001','Severity','Severity',40,'Y','N','Y',40,'Y');
  PERFORM pg_temp.saw023_field(v_tab_id,'23a02316-f008-4f01-8e15-000000000001','Weight','Weight',50,'Y','N','N',50,'Y');
  PERFORM pg_temp.saw023_field(v_tab_id,'23a02316-f009-4f01-8e15-000000000001','DaysBeforeExpiry','Days Before Expiry',60,'Y','N','Y',60,'Y');
  PERFORM pg_temp.saw023_field(v_tab_id,'23a02316-f010-4f01-8e15-000000000001','AD_Table_ID','Source Table',70,'Y','N','N',70,'Y');
  PERFORM pg_temp.saw023_field(v_tab_id,'23a02316-f011-4f01-8e15-000000000001','AD_Window_ID','Drill-down Window',80,'Y','N','N',80,'Y');
  PERFORM pg_temp.saw023_field(v_tab_id,'23a02316-f012-4f01-8e15-000000000001','AD_InfoWindow_ID','Drill-down Info',90,'Y','N','Y',90,'Y');
  PERFORM pg_temp.saw023_field(v_tab_id,'23a02316-f013-4f01-8e15-000000000001','Description','Description',100,'Y','N','N',100,'Y');

  RAISE NOTICE 'SAW023 Rules window=% tab=%', v_window_id, v_tab_id;
END $$;
