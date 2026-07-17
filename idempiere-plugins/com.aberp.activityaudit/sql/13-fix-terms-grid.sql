-- =============================================================================
-- SAW027 — Fix Activity Audit Terms grid toggle
-- Root causes: missing PK field on tab + IsSingleRow=Y (form-only).
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw027_field(
  p_tab_id INTEGER, p_uu TEXT, p_columnname TEXT, p_name TEXT,
  p_seqno INTEGER, p_displayed CHAR, p_readonly CHAR DEFAULT 'N',
  p_sameline CHAR DEFAULT 'N', p_gridseq INTEGER DEFAULT NULL,
  p_displayedgrid CHAR DEFAULT NULL, p_numlines INTEGER DEFAULT 1
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
    RAISE NOTICE 'SAW027 skip field % — column missing', p_columnname;
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
      COALESCE(p_displayedgrid, p_displayed), COALESCE(p_gridseq, p_seqno), 1, 2, p_numlines, p_uu
    );
  ELSE
    UPDATE ad_field SET
      name = p_name, isdisplayed = p_displayed, isreadonly = p_readonly,
      seqno = p_seqno, issameline = p_sameline,
      isdisplayedgrid = COALESCE(p_displayedgrid, p_displayed),
      seqnogrid = COALESCE(p_gridseq, p_seqno),
      numlines = p_numlines,
      ad_field_uu = COALESCE(ad_field_uu, p_uu), updated = NOW()
    WHERE ad_field_id = v_field_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_tab INTEGER;
  v_table INTEGER;
BEGIN
  SELECT ad_tab_id INTO v_tab FROM ad_tab WHERE ad_tab_uu = '27a02741-c0d4-4f01-8e15-000000000001';
  IF v_tab IS NULL THEN
    SELECT t.ad_tab_id INTO v_tab
    FROM ad_tab t
    JOIN ad_window w ON w.ad_window_id = t.ad_window_id
    WHERE w.name = 'Activity Audit Terms' AND t.name = 'Audit Terms'
    LIMIT 1;
  END IF;
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'SAW027: Activity Audit Terms tab missing';
  END IF;

  SELECT ad_table_id INTO v_table FROM ad_tab WHERE ad_tab_id = v_tab;

  UPDATE ad_tab SET
    issinglerow = 'N',
    orderbyclause = 'AD_Org_ID, AuditWord, AbERP_ActivityAuditTerm_ID',
    isinfotab = 'N',
    isreadonly = 'N',
    updated = NOW()
  WHERE ad_tab_id = v_tab;

  UPDATE ad_table SET ishighvolume = 'N', updated = NOW()
  WHERE ad_table_id = v_table;

  -- Required identity fields so WebUI grid can bind rows
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f000-4f01-8e15-000000000001',
    'AbERP_ActivityAuditTerm_ID','Activity Audit Term',0,'N','Y','N',0,'N');
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f00c-4f01-8e15-000000000001',
    'AD_Client_ID','Client',5,'N','Y','N',5,'N');

  -- Keep primary grid columns visible
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f001-4f01-8e15-000000000001','AD_Org_ID','Organisation',10,'Y','N','N',10,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f002-4f01-8e15-000000000001','AuditWord','Audit Word or Phrase',20,'Y','N','N',20,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f003-4f01-8e15-000000000001','Description','Description',30,'Y','N','N',30,'Y',3);
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f004-4f01-8e15-000000000001','Category','Category',40,'Y','N','Y',40,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f005-4f01-8e15-000000000001','RiskLevel','Risk Level',50,'Y','N','Y',50,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f006-4f01-8e15-000000000001','MatchType','Match Type',60,'Y','N','N',60,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f007-4f01-8e15-000000000001','IsActive','Active',70,'Y','N','Y',70,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f008-4f01-8e15-000000000001','ValidFrom','Effective From',80,'Y','N','N',80,'Y');
  PERFORM pg_temp.saw027_field(v_tab,'27a02741-f009-4f01-8e15-000000000001','ValidTo','Effective To',90,'Y','N','Y',90,'Y');

  RAISE NOTICE 'SAW027 Terms grid fix applied (tab=%)', v_tab;
END $$;
