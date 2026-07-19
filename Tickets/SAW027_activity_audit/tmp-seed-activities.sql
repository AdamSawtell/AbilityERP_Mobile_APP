-- SAW027 — seed ~10 Contact Activities with audit words + client/location/employee
-- Safe for re-run: tags description with SAW027-SEED and refreshes Updated.
SET search_path TO adempiere;

DO $$
DECLARE
  v_client INTEGER := 1000003;
  v_user INTEGER := 100;
  r RECORD;
  v_i INTEGER := 0;
  v_words TEXT[] := ARRAY[
    'Fall',
    'Hospital',
    'Ambulance',
    'Seizure',
    'Medication error',
    'Police',
    'Choking',
    'Stroke',
    'Neglect',
    'Paramedic'
  ];
  v_texts TEXT[] := ARRAY[
    'SAW027-SEED: Client had a fall in the bathroom during personal care.',
    'SAW027-SEED: Client attended hospital for assessment after feeling unwell.',
    'SAW027-SEED: Ambulance called to support location; staff waited with client.',
    'SAW027-SEED: Brief seizure observed; client recovered and resting.',
    'SAW027-SEED: Possible medication error — dose checked and supervisor notified.',
    'SAW027-SEED: Police attended regarding a community incident involving the client.',
    'SAW027-SEED: Choking risk noted at mealtime; first aid and monitoring applied.',
    'SAW027-SEED: Stroke symptoms reported — face droop and speech difficulty; urgent review.',
    'SAW027-SEED: Neglect concern raised by family regarding missed supports.',
    'SAW027-SEED: Paramedic attended support location and provided clinical advice.'
  ];
  v_comments TEXT[] := ARRAY[
    'Location note: bathroom / home support.',
    'Follow-up: hospital discharge summary to be filed.',
    'Emergency services contacted by staff.',
    'Seizure protocol followed.',
    'Pharmacy / RN to confirm chart.',
    'Incident logged for duty manager.',
    'Texture / fluid consistency reviewed.',
    'Urgent medical pathway activated.',
    'Escalate to QSR / care coordination.',
    'Clinical hand-over to on-call nurse.'
  ];
  v_act_ids INTEGER[];
  v_bp INTEGER;
  v_emp INTEGER;
  v_loc INTEGER;
  v_org INTEGER;
  v_act INTEGER;
BEGIN
  -- Prefer recent active roster/support activities with client + location + employee
  SELECT ARRAY_AGG(x.c_contactactivity_id ORDER BY x.updated DESC)
  INTO v_act_ids
  FROM (
    SELECT a.c_contactactivity_id, a.updated
    FROM c_contactactivity a
    WHERE a.ad_client_id = v_client
      AND a.isactive = 'Y'
      AND a.c_bpartner_id IS NOT NULL
      AND a.c_bpartner_id > 0
      AND COALESCE(a.aberp_support_location_id, a.aberp_masterlocation_id) IS NOT NULL
      AND COALESCE(a.aberp_support_location_id, a.aberp_masterlocation_id) > 0
      AND a.ad_user_id IS NOT NULL
      AND a.ad_user_id > 0
      AND COALESCE(a.description,'') NOT LIKE 'SAW027-SEED:%'
    ORDER BY a.updated DESC
    LIMIT 10
  ) x;

  IF v_act_ids IS NULL OR array_length(v_act_ids, 1) IS NULL THEN
    -- Fallback: any recent activities with client only
    SELECT ARRAY_AGG(x.c_contactactivity_id ORDER BY x.updated DESC)
    INTO v_act_ids
    FROM (
      SELECT a.c_contactactivity_id, a.updated
      FROM c_contactactivity a
      WHERE a.ad_client_id = v_client
        AND a.isactive = 'Y'
        AND a.c_bpartner_id IS NOT NULL
        AND a.c_bpartner_id > 0
        AND COALESCE(a.description,'') NOT LIKE 'SAW027-SEED:%'
      ORDER BY a.updated DESC
      LIMIT 10
    ) x;
  END IF;

  IF v_act_ids IS NULL OR array_length(v_act_ids, 1) IS NULL THEN
    RAISE EXCEPTION 'SAW027 seed: no suitable Contact Activities found for client %', v_client;
  END IF;

  -- Default BP / location / employee if a chosen row is missing one
  SELECT c_bpartner_id INTO v_bp
  FROM c_bpartner
  WHERE ad_client_id = v_client AND isactive = 'Y' AND iscustomer = 'Y'
  ORDER BY updated DESC
  LIMIT 1;

  SELECT ad_user_id INTO v_emp
  FROM ad_user
  WHERE ad_client_id = v_client AND isactive = 'Y'
  ORDER BY updated DESC
  LIMIT 1;

  SELECT aberp_support_location_id INTO v_loc
  FROM aberp_support_location
  WHERE ad_client_id = v_client AND isactive = 'Y'
  ORDER BY updated DESC
  LIMIT 1;

  SELECT ad_org_id INTO v_org
  FROM ad_org
  WHERE ad_client_id = v_client AND ad_org_id <> 0 AND isactive = 'Y'
  ORDER BY ad_org_id
  LIMIT 1;

  FOR v_i IN 1 .. LEAST(array_length(v_act_ids, 1), 10) LOOP
    v_act := v_act_ids[v_i];

    UPDATE c_contactactivity a SET
      description = left(v_texts[v_i], 255),
      comments = left(
        COALESCE(NULLIF(a.comments,''), '') ||
        CASE WHEN COALESCE(a.comments,'') = '' THEN '' ELSE E'\n' END ||
        v_comments[v_i],
        2000),
      c_bpartner_id = COALESCE(NULLIF(a.c_bpartner_id,0), v_bp),
      ad_user_id = COALESCE(NULLIF(a.ad_user_id,0), v_emp),
      aberp_support_location_id = COALESCE(
        NULLIF(a.aberp_support_location_id,0),
        NULLIF(a.aberp_masterlocation_id,0),
        v_loc),
      ad_org_id = CASE WHEN a.ad_org_id = 0 THEN COALESCE(v_org, a.ad_org_id) ELSE a.ad_org_id END,
      startdate = COALESCE(a.startdate, NOW() - ((10 - v_i) || ' hours')::interval),
      contactactivitytype = COALESCE(NULLIF(a.contactactivitytype,''), 'roster'),
      updated = NOW(),
      updatedby = v_user
    WHERE a.c_contactactivity_id = v_act;

    RAISE NOTICE 'Seeded activity % with word [%]', v_act, v_words[v_i];
  END LOOP;
END $$;

-- Summary for the operator
SELECT
  a.c_contactactivity_id AS activity_id,
  left(a.description, 70) AS description,
  bp.name AS client,
  u.name AS employee,
  COALESCE(sl.name, ml.name) AS location,
  a.contactactivitytype AS type,
  a.startdate,
  a.updated
FROM c_contactactivity a
LEFT JOIN c_bpartner bp ON bp.c_bpartner_id = a.c_bpartner_id
LEFT JOIN ad_user u ON u.ad_user_id = a.ad_user_id
LEFT JOIN aberp_support_location sl ON sl.aberp_support_location_id = a.aberp_support_location_id
LEFT JOIN aberp_masterlocation ml ON ml.aberp_masterlocation_id = a.aberp_masterlocation_id
WHERE a.ad_client_id = 1000003
  AND a.description LIKE 'SAW027-SEED:%'
ORDER BY a.updated DESC
LIMIT 15;

SELECT COUNT(*) AS seeded_count
FROM c_contactactivity
WHERE ad_client_id = 1000003 AND description LIKE 'SAW027-SEED:%';
