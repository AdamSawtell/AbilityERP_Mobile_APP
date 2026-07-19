-- SAW027 — add medical audit terms (HCO) + plant activity text + verify
SET search_path TO adempiere;

DO $$
DECLARE
  v_client_id INTEGER := 1000003; -- HCO
  v_user INTEGER := 100;
  r RECORD;
  v_id INTEGER;
  v_act INTEGER;
  v_seq INTEGER;
BEGIN
  SELECT ad_sequence_id INTO v_seq
  FROM ad_sequence
  WHERE name = 'AbERP_ActivityAuditTerm' AND istableid = 'Y';

  FOR r IN
    SELECT * FROM (VALUES
      ('27a027b1-c0d4-4f01-8e15-000000000001', 'Seizure', 'Seizure or epileptic event', 'IN', 'HI', 'EW'),
      ('27a027b2-c0d4-4f01-8e15-000000000001', 'Chest pain', 'Chest pain reported', 'IN', 'HI', 'EP'),
      ('27a027b3-c0d4-4f01-8e15-000000000001', 'Stroke', 'Stroke symptoms or diagnosis', 'IN', 'CR', 'EW'),
      ('27a027b4-c0d4-4f01-8e15-000000000001', 'Unconscious', 'Loss of consciousness', 'IN', 'CR', 'EW'),
      ('27a027b5-c0d4-4f01-8e15-000000000001', 'Allergic reaction', 'Allergic reaction', 'SF', 'HI', 'EP'),
      ('27a027b6-c0d4-4f01-8e15-000000000001', 'Insulin', 'Insulin administration concern', 'CM', 'MD', 'EW'),
      ('27a027b7-c0d4-4f01-8e15-000000000001', 'Choking', 'Choking incident', 'SF', 'HI', 'EW'),
      ('27a027b8-c0d4-4f01-8e15-000000000001', 'Fracture', 'Fracture or broken bone', 'SF', 'HI', 'EW'),
      ('27a027b9-c0d4-4f01-8e15-000000000001', 'Paramedic', 'Paramedic attendance', 'IN', 'HI', 'EW'),
      ('27a027ba-c0d4-4f01-8e15-000000000001', 'Blood pressure', 'Blood pressure concern', 'SF', 'MD', 'EP')
    ) AS t(uu, word, descr, cat, risk, mtype)
  LOOP
    SELECT aberp_activityauditterm_id INTO v_id
    FROM aberp_activityauditterm
    WHERE ad_client_id = v_client_id
      AND lower(auditword) = lower(r.word)
      AND ad_org_id = 0
    LIMIT 1;

    IF v_id IS NULL THEN
      INSERT INTO aberp_activityauditterm (
        aberp_activityauditterm_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby, aberp_activityauditterm_uu,
        auditword, description, category, risklevel, matchtype, validfrom
      ) VALUES (
        nextidfunc(v_seq, 'N'),
        v_client_id, 0, 'Y',
        NOW(), v_user, NOW(), v_user,
        substring(r.uu from 1 for 24) || lpad(to_hex(v_client_id::integer), 12, '0'),
        r.word, r.descr, r.cat, r.risk, r.mtype, date_trunc('day', NOW())
      );
      RAISE NOTICE 'Inserted term: %', r.word;
    ELSE
      UPDATE aberp_activityauditterm SET
        description = r.descr, category = r.cat, risklevel = r.risk,
        matchtype = r.mtype, isactive = 'Y', updated = NOW()
      WHERE aberp_activityauditterm_id = v_id;
      RAISE NOTICE 'Updated term: %', r.word;
    END IF;
  END LOOP;

  -- Plant medical phrases on a recent HCO activity (bump Updated for nightly)
  SELECT c_contactactivity_id INTO v_act
  FROM c_contactactivity
  WHERE ad_client_id = v_client_id AND isactive = 'Y'
  ORDER BY updated DESC
  LIMIT 1;

  IF v_act IS NULL THEN
    RAISE EXCEPTION 'No HCO Contact Activity for medical term smoke';
  END IF;

  UPDATE c_contactactivity
  SET description = left(
        'SAW027 medical smoke: client had a seizure then chest pain; paramedic attended. Possible stroke. Insulin concern noted.',
        255),
      comments = left(
        COALESCE(comments,'') || ' Also reported choking risk and high blood pressure.',
        2000),
      updated = NOW(),
      updatedby = v_user
  WHERE c_contactactivity_id = v_act;

  RAISE NOTICE 'Planted medical text on activity %', v_act;
END $$;

SELECT auditword, category, risklevel, matchtype
FROM aberp_activityauditterm
WHERE ad_client_id = 1000003 AND isactive = 'Y'
ORDER BY auditword;

SELECT c_contactactivity_id, left(description,120) AS descr, left(comments,80) AS comments, updated
FROM c_contactactivity
WHERE ad_client_id = 1000003
ORDER BY updated DESC
LIMIT 1;
