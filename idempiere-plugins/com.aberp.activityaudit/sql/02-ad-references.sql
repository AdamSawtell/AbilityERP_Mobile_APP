-- =============================================================================
-- SAW027 — list references
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_reference_id),0)+1 FROM ad_reference))
WHERE name='AD_Reference' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_ref_list_id),0)+1 FROM ad_ref_list))
WHERE name='AD_Ref_List' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw027_ref(
  p_uu TEXT, p_name TEXT, p_desc TEXT
) RETURNS INTEGER AS $$
DECLARE
  v_id INTEGER;
BEGIN
  SELECT ad_reference_id INTO v_id FROM ad_reference WHERE ad_reference_uu = p_uu;
  IF v_id IS NULL THEN
    SELECT ad_reference_id INTO v_id FROM ad_reference WHERE name = p_name AND validationtype = 'L';
  END IF;
  IF v_id IS NULL THEN
    INSERT INTO ad_reference (
      ad_reference_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, validationtype, vformat, entitytype, ad_reference_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Reference' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, p_desc, NULL, 'L', NULL, 'Ab_ERP', p_uu
    ) RETURNING ad_reference_id INTO v_id;
  ELSE
    UPDATE ad_reference SET
      name = p_name, description = p_desc, entitytype = 'Ab_ERP',
      ad_reference_uu = COALESCE(ad_reference_uu, p_uu), updated = NOW()
    WHERE ad_reference_id = v_id;
  END IF;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw027_list(
  p_ref INTEGER, p_uu TEXT, p_value TEXT, p_name TEXT, p_seq INTEGER
) RETURNS void AS $$
DECLARE
  v_id INTEGER;
BEGIN
  SELECT ad_ref_list_id INTO v_id FROM ad_ref_list WHERE ad_ref_list_uu = p_uu;
  IF v_id IS NULL THEN
    SELECT ad_ref_list_id INTO v_id FROM ad_ref_list
    WHERE ad_reference_id = p_ref AND value = p_value;
  END IF;
  IF v_id IS NULL THEN
    INSERT INTO ad_ref_list (
      ad_ref_list_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      value, name, description, ad_reference_id, validfrom, validto,
      entitytype, ad_ref_list_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Ref_List' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_value, p_name, NULL, p_ref, NULL, NULL,
      'Ab_ERP', p_uu
    );
  ELSE
    UPDATE ad_ref_list SET
      name = p_name, value = p_value, entitytype = 'Ab_ERP',
      ad_ref_list_uu = COALESCE(ad_ref_list_uu, p_uu), updated = NOW()
    WHERE ad_ref_list_id = v_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_mt INTEGER;
  v_rl INTEGER;
  v_cat INTEGER;
  v_rs INTEGER;
  v_ar INTEGER;
  v_tr INTEGER;
BEGIN
  v_mt := pg_temp.saw027_ref('27a02720-c0d4-4f01-8e15-000000000001', 'AbERP_ActivityAudit_MatchType', 'Activity Audit match type');
  PERFORM pg_temp.saw027_list(v_mt, '27a02720-l001-4f01-8e15-000000000001', 'EW', 'Exact Word', 10);
  PERFORM pg_temp.saw027_list(v_mt, '27a02720-l002-4f01-8e15-000000000001', 'EP', 'Exact Phrase', 20);
  PERFORM pg_temp.saw027_list(v_mt, '27a02720-l003-4f01-8e15-000000000001', 'CT', 'Contains', 30);

  v_rl := pg_temp.saw027_ref('27a02721-c0d4-4f01-8e15-000000000001', 'AbERP_ActivityAudit_RiskLevel', 'Activity Audit risk level');
  PERFORM pg_temp.saw027_list(v_rl, '27a02721-l001-4f01-8e15-000000000001', 'LO', 'Low', 10);
  PERFORM pg_temp.saw027_list(v_rl, '27a02721-l002-4f01-8e15-000000000001', 'MD', 'Medium', 20);
  PERFORM pg_temp.saw027_list(v_rl, '27a02721-l003-4f01-8e15-000000000001', 'HI', 'High', 30);
  PERFORM pg_temp.saw027_list(v_rl, '27a02721-l004-4f01-8e15-000000000001', 'CR', 'Critical', 40);

  v_cat := pg_temp.saw027_ref('27a02722-c0d4-4f01-8e15-000000000001', 'AbERP_ActivityAudit_Category', 'Activity Audit category');
  PERFORM pg_temp.saw027_list(v_cat, '27a02722-l001-4f01-8e15-000000000001', 'IN', 'Incident Risk', 10);
  PERFORM pg_temp.saw027_list(v_cat, '27a02722-l002-4f01-8e15-000000000001', 'CM', 'Compliance', 20);
  PERFORM pg_temp.saw027_list(v_cat, '27a02722-l003-4f01-8e15-000000000001', 'SF', 'Safety', 30);
  PERFORM pg_temp.saw027_list(v_cat, '27a02722-l004-4f01-8e15-000000000001', 'OT', 'Other', 40);

  v_rs := pg_temp.saw027_ref('27a02723-c0d4-4f01-8e15-000000000001', 'AbERP_ActivityAudit_ReviewStatus', 'Activity Audit review status');
  PERFORM pg_temp.saw027_list(v_rs, '27a02723-l001-4f01-8e15-000000000001', 'NW', 'New', 10);
  PERFORM pg_temp.saw027_list(v_rs, '27a02723-l002-4f01-8e15-000000000001', 'UR', 'Under Review', 20);
  PERFORM pg_temp.saw027_list(v_rs, '27a02723-l003-4f01-8e15-000000000001', 'NF', 'Reviewed — No Further Action', 30);
  PERFORM pg_temp.saw027_list(v_rs, '27a02723-l004-4f01-8e15-000000000001', 'FU', 'Follow-Up Required', 40);
  PERFORM pg_temp.saw027_list(v_rs, '27a02723-l005-4f01-8e15-000000000001', 'IR', 'Incident Required', 50);
  PERFORM pg_temp.saw027_list(v_rs, '27a02723-l006-4f01-8e15-000000000001', 'ES', 'Escalated', 60);
  PERFORM pg_temp.saw027_list(v_rs, '27a02723-l007-4f01-8e15-000000000001', 'CO', 'Completed', 70);

  v_ar := pg_temp.saw027_ref('27a02724-c0d4-4f01-8e15-000000000001', 'AbERP_ActivityAudit_Result', 'Activity Audit processing result');
  PERFORM pg_temp.saw027_list(v_ar, '27a02724-l001-4f01-8e15-000000000001', 'NM', 'No Match', 10);
  PERFORM pg_temp.saw027_list(v_ar, '27a02724-l002-4f01-8e15-000000000001', 'MT', 'Match', 20);
  PERFORM pg_temp.saw027_list(v_ar, '27a02724-l003-4f01-8e15-000000000001', 'ER', 'Error', 30);

  v_tr := pg_temp.saw027_ref('27a02725-c0d4-4f01-8e15-000000000001', 'AbERP_ActivityAudit_Trigger', 'Activity Audit run trigger');
  PERFORM pg_temp.saw027_list(v_tr, '27a02725-l001-4f01-8e15-000000000001', 'NT', 'Nightly', 10);
  PERFORM pg_temp.saw027_list(v_tr, '27a02725-l002-4f01-8e15-000000000001', 'HI', 'Historical', 20);
  PERFORM pg_temp.saw027_list(v_tr, '27a02725-l003-4f01-8e15-000000000001', 'MN', 'Manual', 30);

  RAISE NOTICE 'SAW027 references ready';
END $$;
