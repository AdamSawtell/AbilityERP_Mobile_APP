SET search_path TO adempiere;

-- Seed HCO + update one HCO activity for nightly window
DO $$
DECLARE
  v_act INTEGER;
BEGIN
  SELECT c_contactactivity_id INTO v_act
  FROM c_contactactivity
  WHERE ad_client_id = 1000003 AND isactive = 'Y'
  ORDER BY updated DESC
  LIMIT 1;

  UPDATE c_contactactivity
  SET description = left(COALESCE(description,'') || ' SAW027 smoke: the client had a fall in the bathroom', 255),
      updated = NOW(),
      updatedby = 100
  WHERE c_contactactivity_id = v_act;

  RAISE NOTICE 'Updated HCO activity %', v_act;
END $$;

SELECT ad_client_id, COUNT(*) FROM aberp_activityauditterm GROUP BY ad_client_id;
