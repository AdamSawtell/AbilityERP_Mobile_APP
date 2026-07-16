-- SAW024-34 — Distinct Open Findings tab names per category (avoids ZK selecting wrong twin)
SET search_path TO adempiere;

UPDATE ad_tab SET
  name = CASE ad_tab_uu
    WHEN '24a02410-c0d4-4f01-8e15-000000000001' THEN 'Open Findings'
    WHEN '24a02411-c0d4-4f01-8e15-000000000001' THEN 'Client Findings'
    WHEN '24a02412-c0d4-4f01-8e15-000000000001' THEN 'Incident Findings'
    WHEN '24a02413-c0d4-4f01-8e15-000000000001' THEN 'Rostering Findings'
    WHEN '24a02414-c0d4-4f01-8e15-000000000001' THEN 'Documentation Findings'
    ELSE name
  END,
  updated = NOW()
WHERE ad_tab_uu IN (
  '24a02410-c0d4-4f01-8e15-000000000001',
  '24a02411-c0d4-4f01-8e15-000000000001',
  '24a02412-c0d4-4f01-8e15-000000000001',
  '24a02413-c0d4-4f01-8e15-000000000001',
  '24a02414-c0d4-4f01-8e15-000000000001'
);

UPDATE ad_tab_trl SET
  name = t.name,
  istranslated = 'Y',
  updated = NOW()
FROM ad_tab t
WHERE ad_tab_trl.ad_tab_id = t.ad_tab_id
  AND ad_tab_trl.ad_language = 'en_US'
  AND t.ad_tab_uu IN (
    '24a02410-c0d4-4f01-8e15-000000000001',
    '24a02411-c0d4-4f01-8e15-000000000001',
    '24a02412-c0d4-4f01-8e15-000000000001',
    '24a02413-c0d4-4f01-8e15-000000000001',
    '24a02414-c0d4-4f01-8e15-000000000001'
  );

SELECT p.name AS parent, c.name AS child, c.seqno
FROM ad_tab c
JOIN ad_tab p ON p.included_tab_id = c.ad_tab_id
ORDER BY c.seqno;
