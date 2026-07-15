-- =============================================================================
-- SAW019 — Fix "No PK nor FK" when login language is en_AU / es_CO
-- POInfo INNER JOINs AD_Element_Trl for system languages. Missing trl rows drop
-- columns (including IsKey), so GenericPO.setKeyInfo throws on save.
-- =============================================================================
SET search_path TO adempiere;

INSERT INTO ad_element_trl (
  ad_element_id, ad_language, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, printname, description, help, istranslated, ad_element_trl_uu
)
SELECT
  e.ad_element_id, l.ad_language, 0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  e.name, COALESCE(e.printname, e.name), e.description, e.help, 'N',
  generate_uuid()::text
FROM ad_element e
JOIN ad_language l ON l.issystemlanguage = 'Y' AND l.isactive = 'Y'
WHERE e.ad_element_id IN (
  SELECT DISTINCT c.ad_element_id
  FROM ad_column c
  JOIN ad_table t ON t.ad_table_id = c.ad_table_id
  WHERE t.tablename IN ('AbERP_InvoiceCapture', 'AbERP_InvoiceCaptureLog')
    AND c.ad_element_id IS NOT NULL
)
AND NOT EXISTS (
  SELECT 1 FROM ad_element_trl trl
  WHERE trl.ad_element_id = e.ad_element_id
    AND trl.ad_language = l.ad_language
);

INSERT INTO ad_element_trl (
  ad_element_id, ad_language, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, printname, description, help, istranslated, ad_element_trl_uu
)
SELECT
  e.ad_element_id, l.ad_language, 0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  e.name, COALESCE(e.printname, e.name), e.description, e.help, 'N',
  generate_uuid()::text
FROM ad_element e
JOIN ad_language l ON l.issystemlanguage = 'Y' AND l.isactive = 'Y'
WHERE e.entitytype = 'Ab_ERP'
  AND e.columnname LIKE 'AbERP_%'
  AND NOT EXISTS (
    SELECT 1 FROM ad_element_trl trl
    WHERE trl.ad_element_id = e.ad_element_id
      AND trl.ad_language = l.ad_language
  );

UPDATE ad_table SET updated = NOW(), updatedby = 100
WHERE tablename IN ('AbERP_InvoiceCapture', 'AbERP_InvoiceCaptureLog');

UPDATE ad_column SET updated = NOW(), updatedby = 100
WHERE ad_table_id IN (
  SELECT ad_table_id FROM ad_table
  WHERE tablename IN ('AbERP_InvoiceCapture', 'AbERP_InvoiceCaptureLog')
);

DO $$
DECLARE
  v_cnt INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_cnt
  FROM ad_table t
  INNER JOIN ad_column c ON t.ad_table_id = c.ad_table_id
  INNER JOIN ad_element_trl e ON c.ad_element_id = e.ad_element_id AND e.ad_language = 'en_AU'
  WHERE t.tablename = 'AbERP_InvoiceCapture' AND c.isactive = 'Y' AND c.iskey = 'Y';
  IF v_cnt < 1 THEN
    RAISE EXCEPTION 'SAW019: PK still missing from en_AU Element_Trl after fix';
  END IF;
  RAISE NOTICE 'SAW019 PK visible under en_AU POInfo join (count=%)', v_cnt;
END $$;
