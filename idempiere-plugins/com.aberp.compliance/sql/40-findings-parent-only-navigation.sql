-- SAW024-40 — Hide category Findings subtabs until their parent category is selected
-- Owned by SAW024 (Findings navigation). Requires SAW025 population columns
-- (ActiveEmployees / ActiveClients / ActiveIncidents / PeriodShifts / TotalDocuments
--  / ActiveSupportLocations) because DisplayLogic evaluates those parent fields
-- while the category tab is active.
SET search_path TO adempiere;

DO $$
DECLARE
  v_count INTEGER;
BEGIN
  UPDATE ad_tab SET
    displaylogic = CASE ad_tab_uu
      WHEN '24a02410-c0d4-4f01-8e15-000000000001' THEN '@ActiveEmployees@>-1'
      WHEN '24a02411-c0d4-4f01-8e15-000000000001' THEN '@ActiveClients@>-1'
      WHEN '24a02412-c0d4-4f01-8e15-000000000001' THEN '@ActiveIncidents@>-1'
      WHEN '24a02413-c0d4-4f01-8e15-000000000001' THEN '@PeriodShifts@>-1'
      WHEN '24a02414-c0d4-4f01-8e15-000000000001' THEN '@TotalDocuments@>-1'
      WHEN '24a02415-c0d4-4f01-8e15-000000000001' THEN '@ActiveSupportLocations@>-1'
    END,
    isadvancedtab = 'N',
    updated = NOW(),
    updatedby = 100
  WHERE ad_tab_uu IN (
    '24a02410-c0d4-4f01-8e15-000000000001',
    '24a02411-c0d4-4f01-8e15-000000000001',
    '24a02412-c0d4-4f01-8e15-000000000001',
    '24a02413-c0d4-4f01-8e15-000000000001',
    '24a02414-c0d4-4f01-8e15-000000000001',
    '24a02415-c0d4-4f01-8e15-000000000001'
  );

  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count < 5 THEN
    RAISE EXCEPTION 'SAW024-40: expected at least 5 Findings tabs, updated %', v_count;
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM ad_tab parent
  JOIN ad_tab child ON child.ad_tab_id = parent.included_tab_id
  WHERE child.ad_tab_uu IN (
    '24a02410-c0d4-4f01-8e15-000000000001',
    '24a02411-c0d4-4f01-8e15-000000000001',
    '24a02412-c0d4-4f01-8e15-000000000001',
    '24a02413-c0d4-4f01-8e15-000000000001',
    '24a02414-c0d4-4f01-8e15-000000000001'
  );
  IF v_count <> 5 OR EXISTS (
    SELECT 1
    FROM ad_tab parent
    JOIN ad_tab child ON child.ad_tab_id = parent.included_tab_id
    WHERE child.ad_tab_uu IN (
      '24a02410-c0d4-4f01-8e15-000000000001',
      '24a02411-c0d4-4f01-8e15-000000000001',
      '24a02412-c0d4-4f01-8e15-000000000001',
      '24a02413-c0d4-4f01-8e15-000000000001',
      '24a02414-c0d4-4f01-8e15-000000000001'
    )
    GROUP BY child.ad_tab_id
    HAVING COUNT(*) <> 1
  ) THEN
    RAISE EXCEPTION 'SAW024-40: invalid category-to-Findings included-tab linkage (count=%)', v_count;
  END IF;
END $$;

SELECT p.name AS parent_tab, c.name AS findings_tab, c.displaylogic
FROM ad_tab p
JOIN ad_tab c ON c.ad_tab_id = p.included_tab_id
WHERE c.ad_tab_uu IN (
  '24a02410-c0d4-4f01-8e15-000000000001',
  '24a02411-c0d4-4f01-8e15-000000000001',
  '24a02412-c0d4-4f01-8e15-000000000001',
  '24a02413-c0d4-4f01-8e15-000000000001',
  '24a02414-c0d4-4f01-8e15-000000000001',
  '24a02415-c0d4-4f01-8e15-000000000001'
)
ORDER BY p.seqno;
