SET search_path TO adempiere;

-- Create a clean target header for UAT smoke (idempotent by name)
DO $$
DECLARE
  v_id INTEGER;
  v_client INTEGER;
  v_org INTEGER := 0;
BEGIN
  SELECT ad_client_id INTO v_client FROM ad_client WHERE name ILIKE 'HCO%' LIMIT 1;
  SELECT aberp_skip_dates_id INTO v_id FROM aberp_skip_dates WHERE name = 'SAW015 UAT Copy Test' LIMIT 1;
  IF v_id IS NULL THEN
    v_id := nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AbERP_Skip_Dates' AND istableid = 'Y')::integer, 'N');
    INSERT INTO aberp_skip_dates (
      aberp_skip_dates_id, name, description, isactive,
      created, createdby, updated, updatedby,
      ad_client_id, ad_org_id, aberp_skip_dates_uu
    ) VALUES (
      v_id, 'SAW015 UAT Copy Test', 'Created by SAW015 smoke', 'Y',
      NOW(), 100, NOW(), 100,
      v_client, v_org,
      substring(md5('SAW015-uat-' || v_id::text || clock_timestamp()::text), 1, 8) || '-' ||
      substring(md5('SAW015-uat2-' || v_id::text), 1, 4) || '-4a15-8e15-' ||
      substring(md5('SAW015-uat3-' || v_id::text), 1, 12)
    );
  ELSE
    DELETE FROM aberp_dates WHERE aberp_skip_dates_id = v_id;
  END IF;
  RAISE NOTICE 'target skip dates id=%', v_id;
END $$;

SELECT s.aberp_skip_dates_id, s.name,
       (SELECT COUNT(*) FROM aberp_dates d WHERE d.aberp_skip_dates_id = s.aberp_skip_dates_id) AS lines
FROM aberp_skip_dates s
WHERE s.name IN ('SAW015 UAT Copy Test', 'Public Holidays 2025+2026')
ORDER BY s.name;

-- Source line count for expected copy
SELECT COUNT(*) AS source_lines FROM aberp_dates d
JOIN aberp_skip_dates s ON s.aberp_skip_dates_id = d.aberp_skip_dates_id
WHERE s.name = 'Public Holidays 2025+2026';
