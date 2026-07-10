SET search_path TO adempiere;

-- Limit Status dropdown on Rostering Chat to open + closed options officers need
DO $$
DECLARE
  v_rule_id INTEGER;
  v_rule_uu TEXT := substring(md5('AbERP_RosteringChat-status-rule'),1,8)||'-'||
                    substring(md5('AbERP_RosteringChat-status-rule'),9,4)||'-4a18-8018-000000000018';
BEGIN
  SELECT ad_val_rule_id INTO v_rule_id FROM ad_val_rule WHERE name = 'AbERP Rostering Chat Status';
  IF v_rule_id IS NULL THEN
    INSERT INTO ad_val_rule (
      ad_val_rule_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, type, code, entitytype, ad_val_rule_uu
    ) VALUES (
      (SELECT COALESCE(MAX(ad_val_rule_id),0)+1 FROM ad_val_rule),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP Rostering Chat Status',
      'Open / working / closed statuses for mobile rostering chat',
      'S',
      'R_Status.IsActive=''Y'' AND (R_Status.IsClosed=''Y'' OR R_Status.Name IN (''Open - Awaiting Action'',''Working On It'',''Awaiting Info'',''On Hold'',''Closed'',''Complete (Close Request)''))',
      'Ab_ERP',
      v_rule_uu
    );
    SELECT ad_val_rule_id INTO v_rule_id FROM ad_val_rule WHERE name = 'AbERP Rostering Chat Status';
  ELSE
    UPDATE ad_val_rule
    SET code = 'R_Status.IsActive=''Y'' AND (R_Status.IsClosed=''Y'' OR R_Status.Name IN (''Open - Awaiting Action'',''Working On It'',''Awaiting Info'',''On Hold'',''Closed'',''Complete (Close Request)''))',
        updated = NOW(), updatedby = 100
    WHERE ad_val_rule_id = v_rule_id;
  END IF;

  UPDATE ad_field f
  SET ad_val_rule_id = v_rule_id,
      updated = NOW(), updatedby = 100
  FROM ad_column c, ad_tab t, ad_window w
  WHERE f.ad_column_id = c.ad_column_id
    AND f.ad_tab_id = t.ad_tab_id
    AND t.ad_window_id = w.ad_window_id
    AND w.name = 'Rostering Chat' AND t.name = 'Chat'
    AND c.columnname = 'R_Status_ID';
END $$;

SELECT f.name, f.ad_val_rule_id, v.name, v.code
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
LEFT JOIN ad_val_rule v ON v.ad_val_rule_id = f.ad_val_rule_id
WHERE w.name='Rostering Chat' AND t.name='Chat' AND c.columnname='R_Status_ID';
