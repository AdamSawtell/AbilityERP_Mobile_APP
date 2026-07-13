SET search_path TO adempiere;

-- =============================================================================
-- SAW013: Match Create Request From Template popup to window Request Type
--
-- Popup param RequestTemplate_ID currently lists ALL IsTemplate='Y' requests.
-- That lets users pick a template whose R_RequestType_ID differs from the
-- AbERP_ShiftChange.R_RequestType_ID (record/request mismatch).
--
-- Fix (AD only, no JAR):
--   1. New AbERP val rule: templates for @R_RequestType_ID@ only
--   2. Point CreateRequestFromTemplate para at that rule (leave shared rule alone)
--   3. DefaultValue SQL selects the matching template for the window type
-- =============================================================================

DO $$
DECLARE
  v_process NUMERIC;
  v_para NUMERIC;
  v_rule NUMERIC;
  v_seq_rule INTEGER;
  v_uu_rule CONSTANT VARCHAR := 'a0130004-5a01-4e13-a013-000000000004';
  v_uu_para CONSTANT VARCHAR := '13425072-7cf3-4cf0-8ff4-d3c1f00ef393';
  v_uu_process CONSTANT VARCHAR := '3a8e1690-80f7-41b5-9ed9-96f5f3796823';
  v_code CONSTANT TEXT :=
    'R_Request.IsTemplate=''Y'' AND R_Request.R_RequestType_ID=@R_RequestType_ID@';
  v_default CONSTANT TEXT :=
    '@SQL=SELECT R_Request_ID FROM R_Request WHERE R_Request.IsActive=''Y'' AND R_Request.IsTemplate=''Y'' AND R_Request.R_RequestType_ID=@R_RequestType_ID@ ORDER BY Created DESC FETCH FIRST 1 ROWS ONLY';
BEGIN
  SELECT ad_process_id INTO v_process
  FROM ad_process
  WHERE ad_process_uu = v_uu_process
     OR value = 'CreateRequestFromTemplate'
  LIMIT 1;
  IF v_process IS NULL THEN
    RAISE EXCEPTION 'SAW013: process CreateRequestFromTemplate not found';
  END IF;

  SELECT ad_process_para_id INTO v_para
  FROM ad_process_para
  WHERE ad_process_para_uu = v_uu_para
     OR (ad_process_id = v_process AND columnname = 'RequestTemplate_ID')
  LIMIT 1;
  IF v_para IS NULL THEN
    RAISE EXCEPTION 'SAW013: process para RequestTemplate_ID not found';
  END IF;

  SELECT ad_sequence_id::integer INTO v_seq_rule
  FROM ad_sequence
  WHERE name = 'AD_Val_Rule' AND istableid = 'Y'
  LIMIT 1;

  IF EXISTS (SELECT 1 FROM ad_val_rule WHERE ad_val_rule_uu = v_uu_rule) THEN
    UPDATE ad_val_rule SET
      name = 'R_Request Template of Window Request Type',
      description = 'SAW013: template requests matching window @R_RequestType_ID@',
      code = v_code,
      entitytype = 'Ab_ERP',
      updated = NOW(),
      updatedby = 100
    WHERE ad_val_rule_uu = v_uu_rule
    RETURNING ad_val_rule_id INTO v_rule;
  ELSE
    v_rule := nextid(v_seq_rule, 'N');
    INSERT INTO ad_val_rule (
      ad_val_rule_id, ad_val_rule_uu, ad_client_id, ad_org_id,
      isactive, created, createdby, updated, updatedby,
      name, description, type, code, entitytype
    ) VALUES (
      v_rule, v_uu_rule, 0, 0,
      'Y', NOW(), 100, NOW(), 100,
      'R_Request Template of Window Request Type',
      'SAW013: template requests matching window @R_RequestType_ID@',
      'S', v_code, 'Ab_ERP'
    );
  END IF;

  UPDATE ad_process_para SET
    ad_val_rule_id = v_rule,
    defaultvalue = v_default,
    updated = NOW(),
    updatedby = 100
  WHERE ad_process_para_id = v_para;

  RAISE NOTICE 'SAW013: RequestTemplate_ID para % now uses val rule % (UU %)',
    v_para, v_rule, v_uu_rule;
END $$;

-- Verify
SELECT pp.columnname, pp.defaultvalue, vr.name AS valrule, vr.code, vr.ad_val_rule_uu
FROM ad_process_para pp
JOIN ad_process p ON p.ad_process_id = pp.ad_process_id
LEFT JOIN ad_val_rule vr ON vr.ad_val_rule_id = pp.ad_val_rule_id
WHERE p.value = 'CreateRequestFromTemplate'
  AND pp.columnname = 'RequestTemplate_ID';
