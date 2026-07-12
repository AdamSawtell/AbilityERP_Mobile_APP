SET search_path TO adempiere;

DO $$
DECLARE
  v_table NUMERIC;
  v_rec NUMERIC;
  v_client NUMERIC;
  v_org NUMERIC;
  v_rtype NUMERIC;
  v_status NUMERIC;
BEGIN
  SELECT ad_table_id INTO v_table FROM ad_table WHERE tablename = 'AbERP_ShiftChange';
  SELECT r.record_id, r.ad_client_id, r.ad_org_id, r.r_requesttype_id, r.r_status_id
    INTO v_rec, v_client, v_org, v_rtype, v_status
  FROM r_request r
  WHERE r.ad_table_id = v_table AND r.isactive = 'Y' AND r.record_id > 0
  LIMIT 1;

  BEGIN
    INSERT INTO r_request (
      r_request_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      documentno, r_requesttype_id, r_status_id, ad_table_id, record_id, summary, priority,
      salesrep_id, r_request_uu
    ) VALUES (
      nextid((SELECT ad_sequence_id::int FROM ad_sequence WHERE name = 'R_Request' AND istableid = 'Y' LIMIT 1), 'N'::varchar),
      v_client, v_org, 'Y', NOW(), 100, NOW(), 100,
      'SAW013-DUP-TEST', v_rtype, v_status,
      v_table, v_rec, 'SAW013 dup test should fail', '3',
      100, 'a013dup0-0000-4000-8000-000000000001'
    );
    RAISE EXCEPTION 'SAW013 FAIL: duplicate insert was allowed for record %', v_rec;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLERRM LIKE 'A request already exists%' THEN
        RAISE NOTICE 'SAW013 PASS: trigger blocked duplicate: %', SQLERRM;
      ELSE
        RAISE;
      END IF;
  END;
END $$;
