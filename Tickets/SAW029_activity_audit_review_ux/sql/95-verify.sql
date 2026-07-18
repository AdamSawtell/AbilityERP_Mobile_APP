-- SAW029 verify — expected Review form field groups / key placements
SET search_path TO adempiere;

SELECT
  c.columnname,
  f.name AS field_name,
  f.isdisplayed,
  f.isdisplayedgrid,
  f.seqno,
  f.xposition,
  f.issameline,
  COALESCE(fg.name, '(none)') AS fieldgroup,
  fg.ad_fieldgroup_uu
FROM ad_field f
JOIN ad_column c ON c.ad_column_id = f.ad_column_id
JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
LEFT JOIN ad_fieldgroup fg ON fg.ad_fieldgroup_id = f.ad_fieldgroup_id
WHERE (t.ad_tab_uu = '27a02751-c0d4-4f01-8e15-000000000001'
    OR (t.name = 'Reviews' AND EXISTS (
          SELECT 1 FROM ad_window w
          WHERE w.ad_window_id = t.ad_window_id
            AND (w.ad_window_uu = '27a02750-c0d4-4f01-8e15-000000000001'
                 OR w.name = 'Activity Audit Review'))))
  AND c.columnname IN (
    'ActivityDate','AbERP_OpenActivity','C_BPartner_ID','AD_User_ID','ContactActivityType',
    'MatchedTerms','Category','HighestRiskLevel','MatchedExtract',
    'ReviewStatus','IsReviewed','ReviewedBy','ReviewedDate','ReviewNotes','IsFollowUpRequired',
    'ActivityUpdatedAudited','IsActive','Created','CreatedBy','Updated','UpdatedBy')
ORDER BY f.seqno, c.columnname;

-- Hard checks
DO $$
DECLARE
  v_active_fg TEXT;
  v_follow_disp CHAR(1);
  v_fg_count INTEGER;
BEGIN
  SELECT fg.name INTO v_active_fg
  FROM ad_field f
  JOIN ad_column c ON c.ad_column_id = f.ad_column_id
  JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
  LEFT JOIN ad_fieldgroup fg ON fg.ad_fieldgroup_id = f.ad_fieldgroup_id
  WHERE c.columnname = 'IsActive'
    AND (t.ad_tab_uu = '27a02751-c0d4-4f01-8e15-000000000001' OR t.name = 'Reviews')
  ORDER BY CASE WHEN t.ad_tab_uu = '27a02751-c0d4-4f01-8e15-000000000001' THEN 0 ELSE 1 END
  LIMIT 1;

  IF v_active_fg IS DISTINCT FROM 'Audit' THEN
    RAISE EXCEPTION 'SAW029 verify FAIL: IsActive field group is % (expected Audit)', v_active_fg;
  END IF;

  SELECT f.isdisplayed INTO v_follow_disp
  FROM ad_field f
  JOIN ad_column c ON c.ad_column_id = f.ad_column_id
  JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
  WHERE c.columnname = 'IsFollowUpRequired'
    AND (t.ad_tab_uu = '27a02751-c0d4-4f01-8e15-000000000001' OR t.name = 'Reviews')
  ORDER BY CASE WHEN t.ad_tab_uu = '27a02751-c0d4-4f01-8e15-000000000001' THEN 0 ELSE 1 END
  LIMIT 1;

  IF v_follow_disp IS DISTINCT FROM 'N' THEN
    RAISE EXCEPTION 'SAW029 verify FAIL: IsFollowUpRequired IsDisplayed=% (expected N)', v_follow_disp;
  END IF;

  SELECT COUNT(DISTINCT fg.name) INTO v_fg_count
  FROM ad_field f
  JOIN ad_tab t ON t.ad_tab_id = f.ad_tab_id
  JOIN ad_fieldgroup fg ON fg.ad_fieldgroup_id = f.ad_fieldgroup_id
  WHERE (t.ad_tab_uu = '27a02751-c0d4-4f01-8e15-000000000001' OR t.name = 'Reviews')
    AND fg.name IN ('Activity','Match','Review','Audit');

  IF v_fg_count < 4 THEN
    RAISE EXCEPTION 'SAW029 verify FAIL: expected 4 field groups Activity/Match/Review/Audit, found %', v_fg_count;
  END IF;

  RAISE NOTICE 'SAW029 verify OK: Active in Audit; Follow-Up hidden; % named groups present', v_fg_count;
END $$;
