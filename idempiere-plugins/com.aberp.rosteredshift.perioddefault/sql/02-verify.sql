-- SAW022 verify
SET search_path TO adempiere;

SELECT f.ad_field_uu, left(f.defaultvalue, 80) AS field_default
FROM ad_field f
WHERE f.ad_field_uu = '9099644b-d5cf-4b32-9921-1776cac6bd66';

SELECT u.ad_userquery_uu, u.name, u.isdefault, u.isactive,
       left(u.description, 100) AS description, left(u.code, 80) AS code
FROM ad_userquery u
WHERE u.ad_userquery_uu = '6b2c9e11-4d8a-4f01-9b2e-a022shift001';

SELECT t.name, t.description, left(t.help, 120) AS help
FROM ad_tab t
WHERE t.ad_tab_uu = '29867696-9561-462f-89f9-f92c26c8ea02';

DO $$
DECLARE
  v_dv text;
  v_code text;
  v_def char(1);
  v_name text;
  v_help text;
BEGIN
  SELECT defaultvalue INTO v_dv
  FROM ad_field WHERE ad_field_uu = '9099644b-d5cf-4b32-9921-1776cac6bd66';
  IF v_dv IS NULL OR v_dv NOT ILIKE '%AS DefaultValue%' THEN
    RAISE EXCEPTION 'SAW022 verify FAILED: field default missing: %', v_dv;
  END IF;

  SELECT code, isdefault, name INTO v_code, v_def, v_name
  FROM ad_userquery
  WHERE ad_userquery_uu = '6b2c9e11-4d8a-4f01-9b2e-a022shift001';

  IF v_code IS NULL
     OR v_code NOT ILIKE '%AbERP_PR_Period%'
     OR v_code NOT ILIKE '%AbERP_isShowingAsAvailable%'
     OR v_def <> 'Y'
     OR v_name IS DISTINCT FROM '* Current period - available only' THEN
    RAISE EXCEPTION 'SAW022 verify FAILED: UserQuery name/code/default: name=% isdefault=% code=%',
      v_name, v_def, v_code;
  END IF;

  SELECT help INTO v_help FROM ad_tab WHERE ad_tab_uu = '29867696-9561-462f-89f9-f92c26c8ea02';
  IF v_help IS NULL OR v_help NOT ILIKE '%available%' THEN
    RAISE EXCEPTION 'SAW022 verify FAILED: tab Help missing explainer: %', v_help;
  END IF;

  RAISE NOTICE 'SAW022 verify OK';
END $$;
