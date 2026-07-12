SET search_path TO adempiere;

-- Clean old inactive Message para; ensure Reply para exists
UPDATE ad_process_para pp
SET isactive = 'N',
    seqno = 90,
    updated = NOW(),
    updatedby = 100
FROM ad_process p
WHERE pp.ad_process_id = p.ad_process_id
  AND p.value = 'AbERP_RosteringChat_Send'
  AND pp.columnname = 'Message';

UPDATE ad_process p
SET showhelp = 'N',
    description = 'Sends the Reply field to the worker: creates an Updates row and clears the rostering queue.',
    updated = NOW(),
    updatedby = 100
WHERE p.value = 'AbERP_RosteringChat_Send';

-- Reuse existing para row if present (any columnname at seq 10), else insert
DO $$
DECLARE
  v_process_id INTEGER;
  v_para_id INTEGER;
BEGIN
  SELECT ad_process_id INTO v_process_id FROM ad_process WHERE value = 'AbERP_RosteringChat_Send' LIMIT 1;

  SELECT ad_process_para_id INTO v_para_id
  FROM ad_process_para
  WHERE ad_process_id = v_process_id AND columnname IN ('Reply', 'Message')
  ORDER BY CASE WHEN columnname = 'Reply' THEN 0 ELSE 1 END
  LIMIT 1;

  IF v_para_id IS NULL THEN
    SELECT ad_process_para_id INTO v_para_id
    FROM ad_process_para
    WHERE ad_process_id = v_process_id AND seqno = 10
    LIMIT 1;
  END IF;

  IF v_para_id IS NOT NULL THEN
    UPDATE ad_process_para
    SET name = 'Reply',
        description = 'Message to send to the worker (from Reply field).',
        columnname = 'Reply',
        isactive = 'Y',
        seqno = 10,
        defaultvalue = '@AbERP_RosteringReply@',
        fieldlength = 2000,
        ismandatory = 'N',
        ad_reference_id = COALESCE(
          (SELECT ad_reference_id FROM ad_reference WHERE name = 'Text' AND isactive = 'Y' LIMIT 1),
          14
        ),
        updated = NOW(),
        updatedby = 100
    WHERE ad_process_para_id = v_para_id;
  ELSE
    INSERT INTO ad_process_para (
      ad_process_para_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_process_id, seqno,
      ad_reference_id, columnname, iscentrallymaintained,
      fieldlength, ismandatory, isrange, entitytype,
      defaultvalue, isencrypted,
      ad_process_para_uu
    ) VALUES (
      (SELECT COALESCE(MAX(ad_process_para_id), 0) + 1 FROM ad_process_para),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Reply', 'Message to send to the worker (from Reply field).',
      v_process_id, 10,
      COALESCE(
        (SELECT ad_reference_id FROM ad_reference WHERE name = 'Text' AND isactive = 'Y' LIMIT 1),
        14
      ),
      'Reply', 'N',
      2000, 'N', 'N', 'Ab_ERP',
      '@AbERP_RosteringReply@', 'N',
      (
        substring(md5('AbERP_RosteringChat_Send-para-Reply'), 1, 8) || '-' ||
        substring(md5('AbERP_RosteringChat_Send-para-Reply'), 9, 4) || '-4f01-8501-000000000001'
      )
    );
  END IF;
END $$;

-- Ensure Updates parent link still correct after install
UPDATE ad_tab t
SET ad_column_id = (
      SELECT c.ad_column_id FROM ad_column c
      JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
      WHERE tb.tablename = 'R_RequestUpdate' AND c.columnname = 'R_Request_ID' LIMIT 1
    ),
    parent_column_id = (
      SELECT c.ad_column_id FROM ad_column c
      JOIN ad_table tb ON tb.ad_table_id = c.ad_table_id
      WHERE tb.tablename = 'R_Request' AND c.columnname = 'R_Request_ID' LIMIT 1
    ),
    whereclause = 'R_RequestUpdate.R_Request_ID=@R_Request_ID@',
    isreadonly = 'Y',
    isinsertrecord = 'N',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id AND w.name = 'Rostering Chat' AND t.name = 'Updates';

SELECT 'updates' AS check_type, t.ad_column_id, t.parent_column_id, t.whereclause
FROM ad_tab t JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat' AND t.name = 'Updates';

SELECT 'para' AS check_type, pp.columnname, pp.defaultvalue, pp.isactive, pp.seqno
FROM ad_process_para pp
JOIN ad_process p ON p.ad_process_id = pp.ad_process_id
WHERE p.value = 'AbERP_RosteringChat_Send';
