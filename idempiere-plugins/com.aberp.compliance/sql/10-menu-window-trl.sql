-- =============================================================================
-- SAW023 — English translations for menu/window (search + display)
-- =============================================================================
SET search_path TO adempiere;

DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT ad_menu_id, name, description
    FROM ad_menu
    WHERE ad_menu_uu IN (
      '23a02330-c0d4-4f01-8e15-000000000001',
      '23a02331-c0d4-4f01-8e15-000000000001',
      '23a02332-c0d4-4f01-8e15-000000000001'
    )
       OR name IN ('Compliance & Audit Hub','Compliance Summary','Compliance Rules')
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM ad_menu_trl WHERE ad_menu_id = r.ad_menu_id AND ad_language = 'en_US'
    ) THEN
      INSERT INTO ad_menu_trl (
        ad_menu_id, ad_language, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby,
        name, description, istranslated
      ) VALUES (
        r.ad_menu_id, 'en_US', 0, 0, 'Y',
        NOW(), 100, NOW(), 100,
        r.name, COALESCE(r.description, r.name), 'Y'
      );
    END IF;
  END LOOP;

  FOR r IN
    SELECT ad_window_id, name, description
    FROM ad_window
    WHERE ad_window_uu IN (
      '23a02305-c0d4-4f01-8e15-000000000001',
      '23a02306-c0d4-4f01-8e15-000000000001'
    )
       OR name IN ('Compliance Summary','Compliance Rules')
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM ad_window_trl WHERE ad_window_id = r.ad_window_id AND ad_language = 'en_US'
    ) THEN
      INSERT INTO ad_window_trl (
        ad_window_id, ad_language, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby,
        name, description, help, istranslated
      ) VALUES (
        r.ad_window_id, 'en_US', 0, 0, 'Y',
        NOW(), 100, NOW(), 100,
        r.name, COALESCE(r.description, r.name), NULL, 'Y'
      );
    END IF;
  END LOOP;

  RAISE NOTICE 'SAW023 en_US menu/window trl ensured';
END $$;
