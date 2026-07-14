-- =============================================================================
-- SAW019 — CaptureStatus list reference
-- UU: 19a01907-c0d4-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_reference_id),0)+1 FROM ad_reference))
WHERE name='AD_Reference' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_ref_list_id),0)+1 FROM ad_ref_list))
WHERE name='AD_Ref_List' AND istableid='Y';

DO $$
DECLARE
  v_uu CONSTANT TEXT := '19a01907-c0d4-4f01-8e15-000000000001';
  v_ref INTEGER;
  r RECORD;
BEGIN
  SELECT ad_reference_id INTO v_ref FROM ad_reference WHERE ad_reference_uu = v_uu;
  IF v_ref IS NULL THEN
    SELECT ad_reference_id INTO v_ref FROM ad_reference WHERE name = 'AbERP_InvoiceCapture_Status' LIMIT 1;
  END IF;

  IF v_ref IS NULL THEN
    INSERT INTO ad_reference (
      ad_reference_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, validationtype, entitytype, ad_reference_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Reference' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_InvoiceCapture_Status', 'Invoice Capture processing status',
      'L', 'Ab_ERP', v_uu
    ) RETURNING ad_reference_id INTO v_ref;
  ELSE
    UPDATE ad_reference SET
      name = 'AbERP_InvoiceCapture_Status',
      validationtype = 'L',
      entitytype = 'Ab_ERP',
      ad_reference_uu = COALESCE(ad_reference_uu, v_uu),
      isactive = 'Y',
      updated = NOW()
    WHERE ad_reference_id = v_ref;
  END IF;

  FOR r IN
    SELECT * FROM (VALUES
      ('PE', 'Pending', 10),
      ('PR', 'Processing', 20),
      ('RR', 'Requires Review', 30),
      ('VN', 'Vendor Not Matched', 40),
      ('VF', 'Validation Failed', 50),
      ('ER', 'Processing Error', 60),
      ('DU', 'Possible Duplicate', 70),
      ('PU', 'PDF Unreadable', 80),
      ('OK', 'Successfully Processed', 90)
    ) AS t(value, name, seq)
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM ad_ref_list WHERE ad_reference_id = v_ref AND value = r.value
    ) THEN
      INSERT INTO ad_ref_list (
        ad_ref_list_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby,
        value, name, description, ad_reference_id, validfrom, validto,
        entitytype, ad_ref_list_uu
      ) VALUES (
        nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Ref_List' AND istableid = 'Y')::integer, 'N'),
        0, 0, 'Y', NOW(), 100, NOW(), 100,
        r.value, r.name, r.name, v_ref, NULL, NULL,
        'Ab_ERP', '19a01907-' || lpad(r.seq::text, 4, '0') || '-4f01-8e15-000000000001'
      );
    ELSE
      UPDATE ad_ref_list SET
        name = r.name,
        isactive = 'Y',
        entitytype = 'Ab_ERP',
        updated = NOW()
      WHERE ad_reference_id = v_ref AND value = r.value;
    END IF;
  END LOOP;

  RAISE NOTICE 'SAW019 status reference ready id=%', v_ref;
END $$;
