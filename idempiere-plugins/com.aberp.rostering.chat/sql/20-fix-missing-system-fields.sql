SET search_path TO adempiere;

-- Add missing system columns to Rostering Chat / Chat tab (hidden)
-- Missing these commonly causes WebUI Save to discard changes ("Changes ignored")

DO $$
DECLARE
  v_tab_id INTEGER;
  v_table_id INTEGER;
  v_field_id INTEGER;
  v_col RECORD;
  v_seq INTEGER := 900;
BEGIN
  SELECT t.ad_tab_id, t.ad_table_id INTO v_tab_id, v_table_id
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE w.name = 'Rostering Chat' AND t.name = 'Chat'
  LIMIT 1;

  IF v_tab_id IS NULL THEN
    RAISE EXCEPTION 'Chat tab not found';
  END IF;

  FOR v_col IN
    SELECT c.ad_column_id, c.columnname, c.name, c.ad_reference_id, c.fieldlength, c.isupdateable
    FROM ad_column c
    WHERE c.ad_table_id = v_table_id
      AND c.columnname IN (
        'AD_Client_ID','AD_Org_ID','IsActive','Created','CreatedBy','Updated','UpdatedBy','Processed'
      )
      AND NOT EXISTS (
        SELECT 1 FROM ad_field f
        WHERE f.ad_tab_id = v_tab_id AND f.ad_column_id = c.ad_column_id AND f.isactive = 'Y'
      )
  LOOP
    SELECT COALESCE(MAX(ad_field_id), 0) + 1 INTO v_field_id FROM ad_field;
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help,
      isdisplayed, displaylength, isreadonly, seqno,
      sortno, ad_tab_id, ad_column_id, issameline,
      isheading, isfieldonly, isencrypted, entitytype,
      obscuretype, ad_reference_id, ismandatory, included_tab_id,
      defaultvalue, displaylogic, ad_fieldgroup_id,
      iscentrallymaintained, ad_field_uu
    ) VALUES (
      v_field_id, 0, 0, 'Y',
      NOW(), 100, NOW(), 100,
      v_col.name, NULL, NULL,
      'N', COALESCE(v_col.fieldlength, 14), 'Y', v_seq,
      NULL, v_tab_id, v_col.ad_column_id, 'N',
      'N', 'N', 'N', 'U',
      NULL, NULL, NULL, NULL,
      NULL, NULL, NULL,
      'Y',
      substring(md5(v_col.columnname || '-rostering-chat-field'), 1, 8) || '-' ||
      substring(md5(v_col.columnname || '-rostering-chat-field'), 9, 4) || '-4c10-8210-' ||
      lpad(to_hex(v_field_id), 12, '0')
    );
    -- bump sequence
    UPDATE ad_sequence SET currentnext = GREATEST(currentnext, v_field_id + 1)
    WHERE name = 'AD_Field' AND ad_client_id = 0;
    v_seq := v_seq + 10;
    RAISE NOTICE 'Added field % (%)', v_col.columnname, v_field_id;
  END LOOP;
END $$;

-- Updates is message history only (read-only)
UPDATE ad_tab t
SET isreadonly = 'Y',
    isinsertrecord = 'N',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Updates';

UPDATE ad_field f
SET isreadonly = 'Y',
    isupdateable = 'N',
    updated = NOW(),
    updatedby = 100
FROM ad_tab t, ad_window w
WHERE f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Updates';

SELECT c.columnname,
  EXISTS (
    SELECT 1 FROM ad_field f
    JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
    JOIN ad_window w ON w.ad_window_id = t.ad_window_id
    WHERE w.name='Rostering Chat' AND t.name='Chat' AND f.ad_column_id=c.ad_column_id AND f.isactive='Y'
  ) AS on_tab
FROM ad_column c
JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
WHERE tb.tablename='R_Request'
  AND c.columnname IN ('R_Request_ID','Updated','UpdatedBy','Created','CreatedBy','AD_Client_ID','AD_Org_ID','IsActive','Processed');
