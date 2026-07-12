-- SAW014: preflight — Support Location contact ColumnSQL (@SQL= → subquery)
-- Resolve by *_UU only. Never change existing UUs.

DO $$
DECLARE
  v_missing text := '';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ad_table WHERE ad_table_uu = '4ed40b98-ca31-4404-a20b-ea9000d5c51d') THEN
    v_missing := v_missing || 'AbERP_Support_Location table UU; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ad_column WHERE ad_column_uu = 'bd54d23d-44b6-42d7-b8c8-30b3e7b826e6') THEN
    v_missing := v_missing || 'AbERP_Email column UU; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ad_column WHERE ad_column_uu = '5f9a40e5-248b-48bd-848f-532ae4601006') THEN
    v_missing := v_missing || 'AbERP_Phone column UU; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ad_column WHERE ad_column_uu = 'f41c821a-90fb-4b8b-95c6-8bf2f181f8e7') THEN
    v_missing := v_missing || 'AbERP_Phone2 column UU; ';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ad_window WHERE ad_window_uu = '6ef3c558-3ec8-4f0c-be40-89f35d8acebf') THEN
    v_missing := v_missing || 'Support Location window UU; ';
  END IF;

  IF v_missing <> '' THEN
    RAISE EXCEPTION 'SAW014 preflight failed — missing: %', v_missing;
  END IF;

  RAISE NOTICE 'SAW014 preflight OK — Support Location contact columns present';
END $$;

SELECT c.columnname, c.ad_column_uu, left(c.columnsql, 80) AS columnsql_preview
FROM ad_column c
WHERE c.ad_column_uu IN (
  'bd54d23d-44b6-42d7-b8c8-30b3e7b826e6',
  '5f9a40e5-248b-48bd-848f-532ae4601006',
  'f41c821a-90fb-4b8b-95c6-8bf2f181f8e7',
  '21b6490e-5aea-4035-b64c-c45c7cc05161',
  'a77b2962-807c-464b-a8f5-1871ffd9fd1c'
)
ORDER BY c.columnname;
