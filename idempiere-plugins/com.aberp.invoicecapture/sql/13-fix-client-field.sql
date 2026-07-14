-- =============================================================================
-- SAW019 — Hidden AD_Client_ID field on Invoice Capture tab
-- Without this field (like native windows), WebUI leaves AD_Client_ID=-1 on New
-- → MRole AccessTableNoUpdate missing=C → "Changes ignored".
-- Also ensures column default @#AD_Client_ID@.
-- Fixed UU: 19a019f0-0017-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

UPDATE ad_sequence SET currentnext = GREATEST(currentnext, (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';

DO $$
DECLARE
  v_tab_uu CONSTANT TEXT := '19a01904-c0d4-4f01-8e15-000000000001';
  v_field_uu CONSTANT TEXT := '19a019f0-0017-4f01-8e15-000000000001';
  v_tab INTEGER;
  v_table INTEGER;
  v_col INTEGER;
  v_field INTEGER;
BEGIN
  SELECT t.ad_tab_id, t.ad_table_id INTO v_tab, v_table
  FROM ad_tab t
  WHERE t.ad_tab_uu = v_tab_uu
  LIMIT 1;

  IF v_tab IS NULL THEN
    SELECT t.ad_tab_id, t.ad_table_id INTO v_tab, v_table
    FROM ad_tab t
    JOIN ad_table tb ON tb.ad_table_id = t.ad_table_id
    WHERE tb.tablename = 'AbERP_InvoiceCapture' AND t.seqno = 10
    LIMIT 1;
  END IF;

  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'SAW019: Invoice Capture tab missing';
  END IF;

  UPDATE ad_column SET
    defaultvalue = '@#AD_Client_ID@',
    updated = NOW(),
    updatedby = 100
  WHERE ad_table_id = v_table AND columnname = 'AD_Client_ID';

  SELECT ad_column_id INTO v_col
  FROM ad_column
  WHERE ad_table_id = v_table AND columnname = 'AD_Client_ID';

  IF v_col IS NULL THEN
    RAISE EXCEPTION 'SAW019: AD_Client_ID column missing on AbERP_InvoiceCapture';
  END IF;

  SELECT ad_field_id INTO v_field FROM ad_field WHERE ad_field_uu = v_field_uu;
  IF v_field IS NULL THEN
    SELECT ad_field_id INTO v_field
    FROM ad_field
    WHERE ad_tab_id = v_tab AND ad_column_id = v_col;
  END IF;

  IF v_field IS NULL THEN
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
      'Client', 'Y', v_tab, v_col,
      'N', 22, 'Y', 5, 'N',
      'N', 'N', 'N', 'Ab_ERP',
      'N', 0, 1, 2, 1, v_field_uu
    );
  ELSE
    UPDATE ad_field SET
      ad_tab_id = v_tab,
      ad_column_id = v_col,
      name = 'Client',
      isdisplayed = 'N',
      isreadonly = 'Y',
      seqno = 5,
      isdisplayedgrid = 'N',
      entitytype = 'Ab_ERP',
      ad_field_uu = COALESCE(ad_field_uu, v_field_uu),
      updated = NOW(),
      updatedby = 100
    WHERE ad_field_id = v_field;
  END IF;

  RAISE NOTICE 'SAW019 Client field ensured on tab=%', v_tab;
END $$;
