SET search_path TO adempiere;

-- Pick a recent activity or create a disposable test update
DO $$
DECLARE
  v_act INTEGER;
  v_client INTEGER;
BEGIN
  SELECT ad_client_id INTO v_client FROM ad_client WHERE ad_client_id > 0 ORDER BY ad_client_id LIMIT 1;

  SELECT c_contactactivity_id INTO v_act
  FROM c_contactactivity
  WHERE ad_client_id = v_client AND isactive = 'Y'
  ORDER BY updated DESC
  LIMIT 1;

  IF v_act IS NULL THEN
    RAISE EXCEPTION 'No Contact Activity found for smoke';
  END IF;

  UPDATE c_contactactivity
  SET description = COALESCE(description,'') || ' SAW027 smoke: the client had a fall in the bathroom',
      updated = NOW(),
      updatedby = 100
  WHERE c_contactactivity_id = v_act;

  RAISE NOTICE 'SAW027 smoke updated activity %', v_act;
END $$;

SELECT COUNT(*) AS terms FROM aberp_activityauditterm WHERE isactive='Y';
SELECT COUNT(*) AS windows FROM ad_window WHERE name LIKE 'Activity Audit%';
SELECT value, classname FROM ad_process WHERE value LIKE 'AbERP_ActivityAudit%';
