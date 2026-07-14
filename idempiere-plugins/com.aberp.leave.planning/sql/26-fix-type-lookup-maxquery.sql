-- =============================================================================
-- SAW016 — Qualify Unavailability Type lookup + raise MaxQueryRecords safety
-- Lookup WHERE/ORDER BY must be table-qualified or WTableEditor falls back to text.
-- MaxQueryRecords 500 trips when Match-Any ORs date criteria (1228); JAR forces AND.
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  v_iw INTEGER;
  v_ref INTEGER;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001';
  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'SAW016: Leave Planning Info Window missing';
  END IF;

  SELECT ad_reference_id INTO v_ref
  FROM ad_reference
  WHERE name = 'AbERP Leave Planning Unavailability Type'
  ORDER BY ad_reference_id DESC
  LIMIT 1;

  IF v_ref IS NOT NULL THEN
    UPDATE ad_ref_table SET
      whereclause = 'AbERP_Unavailability_Type.IsActive=''Y''',
      orderbyclause = 'AbERP_Unavailability_Type.Name',
      updated = NOW(), updatedby = 100
    WHERE ad_reference_id = v_ref;
  END IF;

  -- Safety net if OR ever leaks again; normal Jul overlap is ~46
  UPDATE ad_infowindow SET
    maxqueryrecords = 5000,
    updated = NOW(), updatedby = 100
  WHERE ad_infowindow_id = v_iw
    AND COALESCE(maxqueryrecords, 0) < 5000;

  RAISE NOTICE 'SAW016: qualified Unavailability Type ref %; MaxQueryRecords raised', v_ref;
END $$;

SELECT r.name, rt.whereclause, rt.orderbyclause
FROM ad_reference r
JOIN ad_ref_table rt ON rt.ad_reference_id = r.ad_reference_id
WHERE r.name = 'AbERP Leave Planning Unavailability Type';

SELECT name, maxqueryrecords
FROM ad_infowindow
WHERE ad_infowindow_uu = '16a016iw-c0d4-4f01-8e15-000000000001';
