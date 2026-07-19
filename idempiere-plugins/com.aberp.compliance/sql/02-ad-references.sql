-- =============================================================================
-- SAW023 — AD_Reference list definitions
-- Category 23a02320 / Severity 23a02321 / Status 23a02322 / TrafficLight 23a02323
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_reference_id),0)+1 FROM ad_reference))
WHERE name='AD_Reference' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_ref_list_id),0)+1 FROM ad_ref_list))
WHERE name='AD_Ref_List' AND istableid='Y';

CREATE OR REPLACE FUNCTION pg_temp.saw023_list_ref(
  p_uu TEXT, p_name TEXT, p_desc TEXT
) RETURNS INTEGER AS $$
DECLARE
  v_ref INTEGER;
BEGIN
  SELECT ad_reference_id INTO v_ref FROM ad_reference WHERE ad_reference_uu = p_uu;
  IF v_ref IS NULL THEN
    SELECT ad_reference_id INTO v_ref FROM ad_reference WHERE name = p_name LIMIT 1;
  END IF;

  IF v_ref IS NULL THEN
    INSERT INTO ad_reference (
      ad_reference_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, validationtype, entitytype, ad_reference_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Reference' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_name, p_desc, 'L', 'Ab_ERP', p_uu
    ) RETURNING ad_reference_id INTO v_ref;
  ELSE
    UPDATE ad_reference SET
      name = p_name,
      description = p_desc,
      validationtype = 'L',
      entitytype = 'Ab_ERP',
      ad_reference_uu = COALESCE(ad_reference_uu, p_uu),
      isactive = 'Y',
      updated = NOW()
    WHERE ad_reference_id = v_ref;
  END IF;
  RETURN v_ref;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.saw023_list_val(
  p_ref INTEGER, p_uu TEXT, p_value TEXT, p_name TEXT, p_seq INTEGER
) RETURNS void AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ad_ref_list WHERE ad_reference_id = p_ref AND value = p_value) THEN
    INSERT INTO ad_ref_list (
      ad_ref_list_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      value, name, description, ad_reference_id, entitytype, ad_ref_list_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Ref_List' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      p_value, p_name, p_name, p_ref, 'Ab_ERP', p_uu
    );
  ELSE
    UPDATE ad_ref_list SET
      name = p_name,
      isactive = 'Y',
      entitytype = 'Ab_ERP',
      ad_ref_list_uu = COALESCE(ad_ref_list_uu, p_uu),
      updated = NOW()
    WHERE ad_reference_id = p_ref AND value = p_value;
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  v_cat INTEGER;
  v_sev INTEGER;
  v_sts INTEGER;
  v_tl  INTEGER;
BEGIN
  v_cat := pg_temp.saw023_list_ref(
    '23a02320-c0d4-4f01-8e15-000000000001',
    'AbERP_ComplianceCategory',
    'Compliance category (Workforce/Participant/Incident/Rostering/Financials/Documentation)');
  PERFORM pg_temp.saw023_list_val(v_cat,'23a02320-0001-4f01-8e15-000000000001','W','Employee',10);
  PERFORM pg_temp.saw023_list_val(v_cat,'23a02320-0002-4f01-8e15-000000000001','P','Client',20);
  PERFORM pg_temp.saw023_list_val(v_cat,'23a02320-0003-4f01-8e15-000000000001','I','Incidents',30);
  PERFORM pg_temp.saw023_list_val(v_cat,'23a02320-0004-4f01-8e15-000000000001','R','Rostering',40);
  PERFORM pg_temp.saw023_list_val(v_cat,'23a02320-0005-4f01-8e15-000000000001','F','Financials',50);
  PERFORM pg_temp.saw023_list_val(v_cat,'23a02320-0006-4f01-8e15-000000000001','D','Documentation',60);
  PERFORM pg_temp.saw023_list_val(v_cat,'23a02320-0007-4f01-8e15-000000000001','L','Support Location',70);

  v_sev := pg_temp.saw023_list_ref(
    '23a02321-c0d4-4f01-8e15-000000000001',
    'AbERP_Severity',
    'Compliance finding severity');
  PERFORM pg_temp.saw023_list_val(v_sev,'23a02321-0001-4f01-8e15-000000000001','CRIT','Critical',10);
  PERFORM pg_temp.saw023_list_val(v_sev,'23a02321-0002-4f01-8e15-000000000001','HIGH','High',20);
  PERFORM pg_temp.saw023_list_val(v_sev,'23a02321-0003-4f01-8e15-000000000001','MED','Medium',30);
  PERFORM pg_temp.saw023_list_val(v_sev,'23a02321-0004-4f01-8e15-000000000001','LOW','Low',40);

  v_sts := pg_temp.saw023_list_ref(
    '23a02322-c0d4-4f01-8e15-000000000001',
    'AbERP_ComplianceStatus',
    'Compliance result status');
  PERFORM pg_temp.saw023_list_val(v_sts,'23a02322-0001-4f01-8e15-000000000001','C','Compliant',10);
  PERFORM pg_temp.saw023_list_val(v_sts,'23a02322-0002-4f01-8e15-000000000001','WARN','Warning',20);
  PERFORM pg_temp.saw023_list_val(v_sts,'23a02322-0003-4f01-8e15-000000000001','NC','Non-Compliant',30);
  PERFORM pg_temp.saw023_list_val(v_sts,'23a02322-0004-4f01-8e15-000000000001','CRIT','Critical',40);

  v_tl := pg_temp.saw023_list_ref(
    '23a02323-c0d4-4f01-8e15-000000000001',
    'AbERP_TrafficLight',
    'Audit readiness traffic light');
  PERFORM pg_temp.saw023_list_val(v_tl,'23a02323-0001-4f01-8e15-000000000001','G','Green',10);
  PERFORM pg_temp.saw023_list_val(v_tl,'23a02323-0002-4f01-8e15-000000000001','A','Amber',20);
  PERFORM pg_temp.saw023_list_val(v_tl,'23a02323-0003-4f01-8e15-000000000001','R','Red',30);

  RAISE NOTICE 'SAW023 refs cat=% sev=% sts=% tl=%', v_cat, v_sev, v_sts, v_tl;
END $$;
