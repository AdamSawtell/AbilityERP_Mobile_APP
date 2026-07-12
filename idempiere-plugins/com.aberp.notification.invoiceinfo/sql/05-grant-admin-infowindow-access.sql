-- Grant Info Window access to operational Admin roles (by name).
-- Safe for HCO / multi-client: resolves IW by UU; roles by name; never changes *_UU.

SET search_path TO adempiere;

DO $$
DECLARE
  v_iw NUMERIC;
  r RECORD;
BEGIN
  SELECT ad_infowindow_id INTO v_iw
  FROM ad_infowindow
  WHERE ad_infowindow_uu = '8fb1cd46-ed81-4cb9-8b83-7662caed9e62';

  IF v_iw IS NULL THEN
    RAISE EXCEPTION 'Info Window UU 8fb1cd46-ed81-4cb9-8b83-7662caed9e62 not found';
  END IF;

  FOR r IN
    SELECT ad_role_id, name
    FROM ad_role
    WHERE isactive = 'Y'
      AND name IN ('Admin', 'AbilityERP Admin')
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM ad_infowindow_access
      WHERE ad_role_id = r.ad_role_id AND ad_infowindow_id = v_iw
    ) THEN
      INSERT INTO ad_infowindow_access (
        ad_infowindow_id, ad_role_id, ad_client_id, ad_org_id, isactive,
        created, createdby, updated, updatedby
      ) VALUES (
        v_iw, r.ad_role_id, 0, 0, 'Y', NOW(), 100, NOW(), 100
      );
      RAISE NOTICE 'Granted InfoWindow access to role % (%)', r.name, r.ad_role_id;
    ELSE
      UPDATE ad_infowindow_access
      SET isactive = 'Y', updated = NOW(), updatedby = 100
      WHERE ad_role_id = r.ad_role_id AND ad_infowindow_id = v_iw;
    END IF;
  END LOOP;
END $$;
