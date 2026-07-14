-- =============================================================================
-- SAW019 — Fix new-record save (Org blank + Client=-1)
-- Root causes / symptoms → "Changes ignored":
--   1) AD_Org_ID defaulted to @#AD_Org_ID@ (=0 / blank) when login Org is *
--   2) AD_Client_ID had no default → PO Client=-1 → AccessTableNoUpdate missing=C
-- Fix: Client default @#AD_Client_ID@; Org SQL default to first real org;
--      table AccessLevel Client-only; DocumentNo sequences; IsActive default Y.
-- Fixed UU (System seed sequence row for first client only):
--   19a0190b-c0d4-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_sequence_id),0)+1 FROM ad_sequence))
WHERE name='AD_Sequence' AND istableid='Y';

DO $$
DECLARE
  v_table_id INTEGER;
  v_log_id INTEGER;
  v_seq_uu CONSTANT TEXT := '19a0190b-c0d4-4f01-8e15-000000000001';
  v_seq_id INTEGER;
  v_client_id INTEGER;
  v_first_client INTEGER;
BEGIN
  SELECT ad_table_id INTO v_table_id FROM ad_table WHERE tablename = 'AbERP_InvoiceCapture';
  IF v_table_id IS NULL THEN
    RAISE EXCEPTION 'SAW019: AbERP_InvoiceCapture table missing';
  END IF;
  SELECT ad_table_id INTO v_log_id FROM ad_table WHERE tablename = 'AbERP_InvoiceCaptureLog';

  -- Client-only access: Org * will not block save; still default a real org for neat data
  UPDATE ad_table SET
    accesslevel = '2',
    updated = NOW(),
    updatedby = 100
  WHERE ad_table_id = v_table_id;

  UPDATE ad_column SET
    defaultvalue = '@#AD_Client_ID@',
    updated = NOW(),
    updatedby = 100
  WHERE ad_table_id IN (v_table_id, v_log_id)
    AND columnname = 'AD_Client_ID';

  UPDATE ad_column SET
    isupdateable = 'Y',
    ismandatory = 'Y',
    defaultvalue = '@SQL=SELECT MIN(AD_Org_ID) FROM AD_Org WHERE AD_Client_ID=@#AD_Client_ID@ AND IsSummary=''N'' AND IsActive=''Y'' AND AD_Org_ID<>0',
    updated = NOW(),
    updatedby = 100
  WHERE ad_table_id = v_table_id
    AND columnname = 'AD_Org_ID';

  UPDATE ad_column SET
    defaultvalue = 'Y',
    updated = NOW(),
    updatedby = 100
  WHERE ad_table_id = v_table_id
    AND columnname = 'IsActive';

  SELECT MIN(ad_client_id) INTO v_first_client
  FROM ad_client WHERE isactive = 'Y' AND ad_client_id > 0;

  FOR v_client_id IN
    SELECT ad_client_id FROM ad_client WHERE isactive = 'Y' AND ad_client_id > 0
  LOOP
    SELECT ad_sequence_id INTO v_seq_id
    FROM ad_sequence
    WHERE name = 'DocumentNo_AbERP_InvoiceCapture'
      AND ad_client_id = v_client_id
    LIMIT 1;

    IF v_seq_id IS NULL THEN
      INSERT INTO ad_sequence (
        ad_sequence_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby,
        name, description, isautosequence,
        incrementno, startno, currentnext, currentnextsys,
        isaudited, istableid, prefix, suffix, startnewyear,
        ad_sequence_uu
      ) VALUES (
        nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Sequence' AND istableid = 'Y')::integer, 'N'),
        v_client_id, 0, 'Y',
        NOW(), 100, NOW(), 100,
        'DocumentNo_AbERP_InvoiceCapture',
        'SAW019 Invoice Capture DocumentNo',
        'Y',
        1, 1000000, 1000000, 1000000,
        'N', 'N', 'IC-', NULL, 'N',
        CASE WHEN v_client_id = v_first_client THEN v_seq_uu
             ELSE ('19a0190b-c0d4-4f01-8e15-' || lpad(v_client_id::text, 12, '0')) END
      );
    END IF;
  END LOOP;

  RAISE NOTICE 'SAW019 new-record Org/DocumentNo fix applied (table=%)', v_table_id;
END $$;
