-- =============================================================================
-- SAW016 — Risk-first sort: Declined → Reviewing → Approved → other, then date
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_iw INTEGER;
  v_order TEXT :=
    'CASE ul.AbERP_ApproverStatus WHEN ''DC'' THEN 1 WHEN ''RV'' THEN 2 WHEN ''AP'' THEN 3 ELSE 9 END, ul.StartDate, u.Name';
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001';
  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'SAW016: Leave Planning Info Window UU 16a016iw-… missing';
  END IF;

  UPDATE ad_infowindow SET
    orderbyclause = v_order,
    updated = NOW(),
    updatedby = 100
  WHERE ad_infowindow_id = v_iw;

  RAISE NOTICE 'SAW016: risk-first ORDER BY on InfoWindow %', v_iw;
END $$;

SELECT orderbyclause FROM ad_infowindow
WHERE ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001';
