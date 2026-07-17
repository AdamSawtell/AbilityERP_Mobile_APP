-- =============================================================================
-- SAW027 — Seed sample audit terms (org 0 = all orgs for client)
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_client_id INTEGER;
  v_user INTEGER := 100;
  r RECORD;
  c RECORD;
  v_id INTEGER;
BEGIN
  FOR c IN
    SELECT ad_client_id FROM ad_client WHERE ad_client_id > 11 ORDER BY ad_client_id
  LOOP
    v_client_id := c.ad_client_id;

  FOR r IN
    SELECT * FROM (VALUES
      ('27a027a1-c0d4-4f01-8e15-000000000001', 'Hospital', 'Hospital admission or attendance', 'IN', 'HI', 'EW'),
      ('27a027a2-c0d4-4f01-8e15-000000000001', 'Ambulance', 'Ambulance attendance', 'IN', 'HI', 'EW'),
      ('27a027a3-c0d4-4f01-8e15-000000000001', 'Emergency Department', 'ED / hospital emergency', 'IN', 'HI', 'EP'),
      ('27a027a4-c0d4-4f01-8e15-000000000001', 'Police', 'Police involvement', 'IN', 'HI', 'EW'),
      ('27a027a5-c0d4-4f01-8e15-000000000001', 'Fall', 'Client fall', 'SF', 'MD', 'EW'),
      ('27a027a6-c0d4-4f01-8e15-000000000001', 'Injury', 'Injury noted', 'SF', 'MD', 'EW'),
      ('27a027a7-c0d4-4f01-8e15-000000000001', 'Medication error', 'Medication error', 'CM', 'HI', 'EP'),
      ('27a027a8-c0d4-4f01-8e15-000000000001', 'Restrictive practice', 'Restrictive practice', 'CM', 'CR', 'EP'),
      ('27a027a9-c0d4-4f01-8e15-000000000001', 'Abuse', 'Abuse allegation or concern', 'CM', 'CR', 'EW'),
      ('27a027aa-c0d4-4f01-8e15-000000000001', 'Neglect', 'Neglect concern', 'CM', 'CR', 'EW'),
      ('27a027ab-c0d4-4f01-8e15-000000000001', 'Missing person', 'Missing person', 'IN', 'CR', 'EP')
    ) AS t(uu, word, descr, cat, risk, mtype)
  LOOP
    -- Per-client UU: suffix with client id hex so rows do not collide across clients
    SELECT aberp_activityauditterm_id INTO v_id
    FROM aberp_activityauditterm
    WHERE ad_client_id = v_client_id AND lower(auditword) = lower(r.word) AND ad_org_id = 0
    LIMIT 1;

    IF v_id IS NULL THEN
      INSERT INTO aberp_activityauditterm (
        aberp_activityauditterm_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_activityauditterm_uu,
        auditword, description, category, risklevel, matchtype, validfrom
      ) VALUES (
        nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AbERP_ActivityAuditTerm' AND istableid = 'Y')::integer, 'N'),
        v_client_id, 0, 'Y',
        NOW(), v_user, NOW(), v_user,
        substring(r.uu from 1 for 24) || lpad(to_hex(v_client_id::integer), 12, '0'),
        r.word, r.descr, r.cat, r.risk, r.mtype, date_trunc('day', NOW())
      );
    ELSE
      UPDATE aberp_activityauditterm SET
        auditword = r.word, description = r.descr, category = r.cat,
        risklevel = r.risk, matchtype = r.mtype,
        updated = NOW()
      WHERE aberp_activityauditterm_id = v_id;
    END IF;
  END LOOP;

  RAISE NOTICE 'SAW027 seed terms ready for client %', v_client_id;
  END LOOP;
END $$;
