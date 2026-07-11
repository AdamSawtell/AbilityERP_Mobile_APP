-- Preflight: ensure target Info Window exists by UUID (IDs differ per client).
-- Fail closed — do not apply 01/04 if this raises.

SET search_path TO adempiere;

DO $$
DECLARE
  v_iw NUMERIC;
  v_from TEXT;
BEGIN
  SELECT ad_infowindow_id, fromclause
    INTO v_iw, v_from
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '8fb1cd46-ed81-4cb9-8b83-7662caed9e62';

  IF v_iw IS NULL THEN
    RAISE EXCEPTION
      'PREFLIGHT FAIL: AD_InfoWindow UU 8fb1cd46-ed81-4cb9-8b83-7662caed9e62 not found. '
      'Do not apply Paid filter SQL on this client until the Notification SR Invoice Send Info window is present (same UU from shared pack). '
      'Numeric AD_InfoWindow_ID differs between clients — never patch by ID alone.';
  END IF;

  IF v_from IS NULL OR v_from !~* 'C_Invoice[[:space:]]+i' THEN
    RAISE EXCEPTION
      'PREFLIGHT FAIL: Info Window ID=% UU ok but FROM clause does not expose C_Invoice alias i (fromclause=%).',
      v_iw, v_from;
  END IF;

  RAISE NOTICE 'PREFLIGHT OK: AD_InfoWindow_ID=% (client-local) UU=8fb1cd46-ed81-4cb9-8b83-7662caed9e62 fromclause=%',
    v_iw, v_from;
END $$;

SELECT ad_infowindow_id AS client_local_id,
       ad_infowindow_uu,
       name,
       fromclause,
       isvalid
FROM ad_infowindow
WHERE ad_infowindow_uu = '8fb1cd46-ed81-4cb9-8b83-7662caed9e62';
