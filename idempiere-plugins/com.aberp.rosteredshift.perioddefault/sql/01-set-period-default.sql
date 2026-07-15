-- SAW022: Shift (Rostered) — default Lookup to current pay period
--
-- Field DefaultValue on virtual AbERP_PR_Period_ID is NOT applied by Find/Lookup
-- on this build (verified with literal ID). Use shared AD_UserQuery IsDefault +
-- @SQL= EXISTS against AbERP_PR_Period (dynamic — no fortnight ID refresh).
-- User can switch to ** New Query ** or any other saved query for history/locations.

SET search_path TO adempiere;

DO $$
DECLARE
  v_field_uu   CONSTANT varchar := '9099644b-d5cf-4b32-9921-1776cac6bd66';
  v_tab_uu     CONSTANT varchar := '29867696-9561-462f-89f9-f92c26c8ea02';
  v_win_uu     CONSTANT varchar := '7c269a7e-65dd-4287-8d53-f7f3ca09ee00';
  v_query_uu   CONSTANT varchar := '6b2c9e11-4d8a-4f01-9b2e-a022shift001';
  v_query_name CONSTANT varchar := '* Current Pay Period';

  -- Find/UserQuery @SQL= fragment (dynamic current period by wall-clock)
  v_code CONSTANT text :=
    '@SQL=EXISTS (SELECT 1 FROM AbERP_PR_Period p'
    || ' WHERE p.IsActive=''Y'''
    || ' AND p.AD_Client_ID=AbERP_Rostered_Shift.AD_Client_ID'
    || ' AND LOCALTIMESTAMP >= p.StartDate'
    || ' AND LOCALTIMESTAMP <= p.EndDate'
    || ' AND AbERP_Rostered_Shift.StartDate >= p.StartDate'
    || ' AND AbERP_Rostered_Shift.StartDate <= p.EndDate)';

  -- Field default (best-effort for New / future Find behaviour; AS DefaultValue required)
  v_field_default CONSTANT text :=
    '@SQL=SELECT AbERP_PR_Period_ID AS DefaultValue FROM AbERP_PR_Period'
    || ' WHERE IsActive=''Y'''
    || ' AND AD_Client_ID=@#AD_Client_ID@'
    || ' AND @#Date@ >= StartDate'
    || ' AND @#Date@ <= EndDate'
    || ' ORDER BY StartDate'
    || ' LIMIT 1';

  v_tab_id    integer;
  v_window_id integer;
  v_table_id  integer;
  v_client_id integer;
  v_n         integer;
  v_qid       integer;
BEGIN
  SELECT t.ad_tab_id, w.ad_window_id, t.ad_table_id
    INTO v_tab_id, v_window_id, v_table_id
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE t.ad_tab_uu = v_tab_uu
    AND w.ad_window_uu = v_win_uu;

  IF v_tab_id IS NULL THEN
    RAISE EXCEPTION 'SAW022: Shift (Rostered) tab UU % / window UU % not found',
      v_tab_uu, v_win_uu;
  END IF;

  -- Prefer operating client that has pay periods; fall back by name
  SELECT COALESCE(
    (SELECT p.ad_client_id FROM aberp_pr_period p
      WHERE p.isactive = 'Y'
        AND LOCALTIMESTAMP >= p.startdate
        AND LOCALTIMESTAMP <= p.enddate
      ORDER BY p.ad_client_id LIMIT 1),
    (SELECT ad_client_id FROM ad_client WHERE name ILIKE 'HCO%' AND isactive = 'Y' ORDER BY ad_client_id LIMIT 1),
    (SELECT ad_client_id FROM ad_client WHERE name = 'AbilityERP' AND isactive = 'Y' ORDER BY ad_client_id LIMIT 1),
    (SELECT ad_client_id FROM ad_client WHERE ad_client_id > 11 AND isactive = 'Y' ORDER BY ad_client_id LIMIT 1)
  ) INTO v_client_id;

  IF v_client_id IS NULL THEN
    RAISE EXCEPTION 'SAW022: no client resolved for UserQuery';
  END IF;

  -- 1) Best-effort field default (selection column)
  UPDATE ad_field
     SET defaultvalue = v_field_default,
         isselectioncolumn = 'Y',
         updated = NOW(),
         updatedby = 100
   WHERE ad_field_uu = v_field_uu;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'SAW022: Roster Period field UU % not found', v_field_uu;
  END IF;

  -- 2) Upsert shared default UserQuery
  SELECT ad_userquery_id INTO v_qid
  FROM ad_userquery
  WHERE ad_userquery_uu = v_query_uu;

  IF v_qid IS NULL THEN
    SELECT ad_userquery_id INTO v_qid
    FROM ad_userquery
    WHERE ad_tab_id = v_tab_id
      AND name = v_query_name
      AND ad_user_id IS NULL
    LIMIT 1;
  END IF;

  IF v_qid IS NULL THEN
    INSERT INTO ad_userquery (
      ad_userquery_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, ad_user_id, ad_table_id, ad_tab_id, ad_window_id,
      ad_role_id, isdefault, code, ad_userquery_uu
    ) VALUES (
      (SELECT COALESCE(MAX(ad_userquery_id), 0) + 1 FROM ad_userquery),
      v_client_id, 0, 'Y',
      NOW(), 100, NOW(), 100,
      v_query_name,
      'SAW022: default Lookup filter — current AbERP pay period (clear via ** New Query ** or other saved queries).',
      NULL, v_table_id, v_tab_id, v_window_id,
      NULL, 'Y',
      v_code,
      v_query_uu
    );
    RAISE NOTICE 'SAW022: inserted UserQuery %', v_query_uu;
  ELSE
    UPDATE ad_userquery
       SET name = v_query_name,
           description = 'SAW022: default Lookup filter — current AbERP pay period (clear via ** New Query ** or other saved queries).',
           code = v_code,
           isdefault = 'Y',
           isactive = 'Y',
           ad_client_id = v_client_id,
           ad_tab_id = v_tab_id,
           ad_window_id = v_window_id,
           ad_table_id = v_table_id,
           ad_user_id = NULL,
           ad_userquery_uu = v_query_uu,
           updated = NOW(),
           updatedby = 100
     WHERE ad_userquery_id = v_qid;
    RAISE NOTICE 'SAW022: updated UserQuery id %', v_qid;
  END IF;

  -- Only one default on this tab
  UPDATE ad_userquery
     SET isdefault = 'N',
         updated = NOW(),
         updatedby = 100
   WHERE ad_tab_id = v_tab_id
     AND isdefault = 'Y'
     AND ad_userquery_uu IS DISTINCT FROM v_query_uu;

  RAISE NOTICE 'SAW022 apply OK (client %)', v_client_id;
END $$;
