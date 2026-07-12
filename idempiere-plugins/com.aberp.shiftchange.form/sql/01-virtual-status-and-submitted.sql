SET search_path TO adempiere;

-- =============================================================================
-- SAW013: Status + Submitted as physical columns, synced from R_Request
-- Virtual ColumnSQL times out on HCO Forms (3.8k+ rows in GridTable).
-- =============================================================================

ALTER TABLE aberp_shiftchange
  ADD COLUMN IF NOT EXISTS aberp_requestsubmitted CHAR(1) DEFAULT 'N';

DO $$
DECLARE
  v_table NUMERIC;
  v_tab NUMERIC;
  v_el NUMERIC;
  v_col NUMERIC;
  v_seq_el INTEGER;
  v_seq_col INTEGER;
  v_seq_field INTEGER;
  v_uu_el CONSTANT VARCHAR := 'a0130001-5a01-4e13-a013-000000000001';
  v_uu_col CONSTANT VARCHAR := 'a0130002-5a01-4e13-a013-000000000002';
  v_uu_field CONSTANT VARCHAR := 'a0130003-5a01-4e13-a013-000000000003';
BEGIN
  SELECT ad_table_id INTO v_table
  FROM ad_table
  WHERE ad_table_uu = '136fd0b7-e2b0-40a1-846f-1e198b8c232d'
     OR tablename = 'AbERP_ShiftChange'
  LIMIT 1;
  IF v_table IS NULL THEN
    RAISE EXCEPTION 'AbERP_ShiftChange not found';
  END IF;

  SELECT ad_tab_id INTO v_tab
  FROM ad_tab t
  JOIN ad_window w ON w.ad_window_id = t.ad_window_id
  WHERE t.ad_table_id = v_table
    AND t.tablevel = 0
    AND (
      t.ad_tab_uu = 'a22481e4-c47f-43e3-ab9e-6c54a31ce2a1'
      OR w.ad_window_uu = 'b3919637-5125-4d2d-a9f7-6d751835f537'
      OR w.name = 'HCO Forms and Approvals'
    )
  LIMIT 1;
  IF v_tab IS NULL THEN
    RAISE EXCEPTION 'HCO Forms main tab not found';
  END IF;

  SELECT ad_sequence_id::integer INTO v_seq_el FROM ad_sequence WHERE name = 'AD_Element' AND istableid = 'Y' LIMIT 1;
  SELECT ad_sequence_id::integer INTO v_seq_col FROM ad_sequence WHERE name = 'AD_Column' AND istableid = 'Y' LIMIT 1;
  SELECT ad_sequence_id::integer INTO v_seq_field FROM ad_sequence WHERE name = 'AD_Field' AND istableid = 'Y' LIMIT 1;

  -- Status: physical, read-only (no ColumnSQL)
  UPDATE ad_column
  SET columnsql = NULL,
      isupdateable = 'N',
      isalwaysupdateable = 'N',
      ismandatory = 'N',
      updated = NOW(),
      updatedby = 100
  WHERE ad_table_id = v_table AND columnname = 'R_Status_ID';

  UPDATE ad_field f
  SET isreadonly = 'Y',
      ismandatory = 'N',
      name = 'Status',
      description = 'Current status of the linked Request (auto-synced; read-only)',
      help = 'Maintained automatically from the linked Request. Staff do not edit this field.',
      updated = NOW(),
      updatedby = 100
  WHERE f.ad_tab_id = v_tab
    AND f.ad_column_id = (
      SELECT ad_column_id FROM ad_column
      WHERE ad_table_id = v_table AND columnname = 'R_Status_ID'
    );

  -- Element AbERP_RequestSubmitted
  IF EXISTS (SELECT 1 FROM ad_element WHERE ad_element_uu = v_uu_el) THEN
    UPDATE ad_element SET
      columnname = 'AbERP_RequestSubmitted',
      name = 'Request Submitted',
      printname = 'Request Submitted',
      description = 'Y when an active R_Request is linked to this form',
      entitytype = 'Ab_ERP',
      updated = NOW(), updatedby = 100
    WHERE ad_element_uu = v_uu_el;
  ELSIF EXISTS (SELECT 1 FROM ad_element WHERE columnname = 'AbERP_RequestSubmitted') THEN
    UPDATE ad_element SET
      name = 'Request Submitted', printname = 'Request Submitted',
      description = 'Y when an active R_Request is linked to this form',
      entitytype = 'Ab_ERP', updated = NOW(), updatedby = 100
    WHERE columnname = 'AbERP_RequestSubmitted';
  ELSE
    INSERT INTO ad_element (
      ad_element_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      columnname, entitytype, name, printname, description, ad_element_uu
    ) VALUES (
      nextid(v_seq_el, 'N'::varchar), 0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_RequestSubmitted', 'Ab_ERP', 'Request Submitted', 'Request Submitted',
      'Y when an active R_Request is linked to this form', v_uu_el
    );
  END IF;

  SELECT ad_element_id INTO v_el
  FROM ad_element WHERE ad_element_uu = v_uu_el OR columnname = 'AbERP_RequestSubmitted' LIMIT 1;

  IF EXISTS (SELECT 1 FROM ad_column WHERE ad_column_uu = v_uu_col) THEN
    UPDATE ad_column SET
      name = 'Request Submitted', columnname = 'AbERP_RequestSubmitted',
      ad_table_id = v_table, ad_reference_id = 20, fieldlength = 1,
      ad_element_id = v_el, entitytype = 'Ab_ERP',
      isupdateable = 'N', ismandatory = 'N', isactive = 'Y',
      columnsql = NULL, issyncdatabase = 'Y',
      updated = NOW(), updatedby = 100
    WHERE ad_column_uu = v_uu_col;
  ELSIF EXISTS (
    SELECT 1 FROM ad_column WHERE ad_table_id = v_table AND columnname = 'AbERP_RequestSubmitted'
  ) THEN
    UPDATE ad_column SET
      name = 'Request Submitted', ad_reference_id = 20, fieldlength = 1,
      ad_element_id = v_el, entitytype = 'Ab_ERP',
      isupdateable = 'N', ismandatory = 'N', isactive = 'Y',
      columnsql = NULL, issyncdatabase = 'Y',
      updated = NOW(), updatedby = 100
    WHERE ad_table_id = v_table AND columnname = 'AbERP_RequestSubmitted';
  ELSE
    INSERT INTO ad_column (
      ad_column_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, help, version, entitytype,
      columnname, ad_table_id, ad_reference_id,
      fieldlength, iskey, isparent, ismandatory, isupdateable,
      isidentifier, seqno, istranslated, isencrypted, isselectioncolumn,
      ad_element_id, issyncdatabase, isalwaysupdateable,
      isallowlogging, isallowcopy, seqnoselection, istoolbarbutton, issecure,
      ad_column_uu
    ) VALUES (
      nextid(v_seq_col, 'N'::varchar), 0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Request Submitted',
      'Y when an active Request already exists for this form',
      'Shows Yes after Create Request From Template has been run.',
      0, 'Ab_ERP', 'AbERP_RequestSubmitted', v_table, 20,
      1, 'N', 'N', 'N', 'N',
      'N', 0, 'N', 'N', 'N',
      v_el, 'Y', 'N',
      'Y', 'N', 0, 'N', 'N',
      v_uu_col
    );
  END IF;

  SELECT ad_column_id INTO v_col
  FROM ad_column WHERE ad_table_id = v_table AND columnname = 'AbERP_RequestSubmitted';

  IF EXISTS (SELECT 1 FROM ad_field WHERE ad_field_uu = v_uu_field) THEN
    UPDATE ad_field SET
      name = 'Request Submitted', ad_tab_id = v_tab, ad_column_id = v_col,
      isdisplayed = 'Y', isdisplayedgrid = 'Y', isreadonly = 'Y',
      seqno = 35, seqnogrid = 35, displaylength = 1, entitytype = 'Ab_ERP',
      iscentrallymaintained = 'N',
      description = 'Yes = a Request already exists for this form',
      updated = NOW(), updatedby = 100
    WHERE ad_field_uu = v_uu_field;
  ELSIF EXISTS (SELECT 1 FROM ad_field f WHERE f.ad_tab_id = v_tab AND f.ad_column_id = v_col) THEN
    UPDATE ad_field SET
      name = 'Request Submitted', isdisplayed = 'Y', isdisplayedgrid = 'Y',
      isreadonly = 'Y', seqno = 35, seqnogrid = 35, displaylength = 1,
      entitytype = 'Ab_ERP', iscentrallymaintained = 'N',
      description = 'Yes = a Request already exists for this form',
      updated = NOW(), updatedby = 100
    WHERE ad_tab_id = v_tab AND ad_column_id = v_col;
  ELSE
    INSERT INTO ad_field (
      ad_field_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, iscentrallymaintained,
      ad_tab_id, ad_column_id,
      isdisplayed, displaylength, isreadonly, seqno,
      issameline, isheading, isfieldonly, isencrypted, entitytype,
      isdisplayedgrid, seqnogrid, xposition, columnspan, numlines,
      isquickentry, istoolbarbutton, ad_field_uu
    ) VALUES (
      nextid(v_seq_field, 'N'::varchar), 0, 0, 'Y', NOW(), 100, NOW(), 100,
      'Request Submitted', 'Yes = a Request already exists for this form', 'N',
      v_tab, v_col, 'Y', 1, 'Y', 35,
      'Y', 'N', 'N', 'N', 'Ab_ERP',
      'Y', 35, 4, 2, 1, 'N', 'N', v_uu_field
    );
  END IF;

  UPDATE ad_field f
  SET displaylogic = '@AbERP_RequestSubmitted@=N',
      updated = NOW(), updatedby = 100
  WHERE f.ad_tab_id = v_tab
    AND f.ad_column_id = (
      SELECT ad_column_id FROM ad_column
      WHERE ad_table_id = v_table AND columnname = 'AbERP_CreateShiftChangeRequest'
    );

  RAISE NOTICE 'SAW013: physical Status/Submitted AD applied';
END $$;

-- Sync function: keep Shift Change Status + Submitted in sync with linked Request
CREATE OR REPLACE FUNCTION adempiere.aberp_shiftchange_sync_from_request()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_table_id NUMERIC;
  v_sc_id NUMERIC;
  v_status NUMERIC;
  v_has CHAR(1);
BEGIN
  SELECT ad_table_id INTO v_table_id FROM ad_table WHERE tablename = 'AbERP_ShiftChange' LIMIT 1;
  IF v_table_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  IF TG_OP = 'DELETE' THEN
    IF OLD.ad_table_id IS DISTINCT FROM v_table_id THEN
      RETURN OLD;
    END IF;
    v_sc_id := OLD.record_id;
  ELSE
    IF NEW.ad_table_id IS DISTINCT FROM v_table_id
       AND (TG_OP <> 'UPDATE' OR OLD.ad_table_id IS DISTINCT FROM v_table_id) THEN
      -- Also resync old parent if AD_Table_ID / Record_ID changed away
      IF TG_OP = 'UPDATE' AND OLD.ad_table_id = v_table_id AND OLD.record_id IS NOT NULL THEN
        UPDATE aberp_shiftchange sc
        SET r_status_id = (
              SELECT r.r_status_id FROM r_request r
              WHERE r.ad_table_id = v_table_id AND r.record_id = sc.aberp_shiftchange_id AND r.isactive = 'Y'
              ORDER BY r.r_request_id DESC LIMIT 1
            ),
            aberp_requestsubmitted = CASE WHEN EXISTS (
              SELECT 1 FROM r_request r
              WHERE r.ad_table_id = v_table_id AND r.record_id = sc.aberp_shiftchange_id AND r.isactive = 'Y'
            ) THEN 'Y' ELSE 'N' END,
            updated = NOW()
        WHERE sc.aberp_shiftchange_id = OLD.record_id;
      END IF;
      IF NEW.ad_table_id IS DISTINCT FROM v_table_id THEN
        RETURN NEW;
      END IF;
    END IF;
    v_sc_id := NEW.record_id;
  END IF;

  IF v_sc_id IS NULL OR v_sc_id <= 0 THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  SELECT r.r_status_id INTO v_status
  FROM r_request r
  WHERE r.ad_table_id = v_table_id
    AND r.record_id = v_sc_id
    AND r.isactive = 'Y'
  ORDER BY r.r_request_id DESC
  LIMIT 1;

  v_has := CASE WHEN v_status IS NOT NULL
                  OR EXISTS (
                    SELECT 1 FROM r_request r
                    WHERE r.ad_table_id = v_table_id AND r.record_id = v_sc_id AND r.isactive = 'Y'
                  ) THEN 'Y' ELSE 'N' END;

  -- If only inactive remain, clear status
  IF NOT EXISTS (
    SELECT 1 FROM r_request r
    WHERE r.ad_table_id = v_table_id AND r.record_id = v_sc_id AND r.isactive = 'Y'
  ) THEN
    v_status := NULL;
    v_has := 'N';
  END IF;

  UPDATE aberp_shiftchange
  SET r_status_id = v_status,
      aberp_requestsubmitted = v_has,
      updated = NOW()
  WHERE aberp_shiftchange_id = v_sc_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS aberp_shiftchange_sync_from_request_trg ON adempiere.r_request;
CREATE TRIGGER aberp_shiftchange_sync_from_request_trg
  AFTER INSERT OR UPDATE OF r_status_id, isactive, ad_table_id, record_id OR DELETE
  ON adempiere.r_request
  FOR EACH ROW
  EXECUTE PROCEDURE adempiere.aberp_shiftchange_sync_from_request();

-- One-time backfill
UPDATE aberp_shiftchange sc
SET r_status_id = r.r_status_id,
    aberp_requestsubmitted = 'Y',
    updated = NOW()
FROM (
  SELECT DISTINCT ON (record_id) record_id, r_status_id
  FROM r_request
  WHERE ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_ShiftChange')
    AND isactive = 'Y'
    AND record_id IS NOT NULL
  ORDER BY record_id, r_request_id DESC
) r
WHERE sc.aberp_shiftchange_id = r.record_id;

UPDATE aberp_shiftchange sc
SET aberp_requestsubmitted = 'N',
    updated = NOW()
WHERE COALESCE(aberp_requestsubmitted, 'N') <> 'N'
  AND NOT EXISTS (
    SELECT 1 FROM r_request r
    WHERE r.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename = 'AbERP_ShiftChange')
      AND r.record_id = sc.aberp_shiftchange_id
      AND r.isactive = 'Y'
  );

SELECT 'backfill' AS c,
       COUNT(*) FILTER (WHERE aberp_requestsubmitted = 'Y') AS submitted_y,
       COUNT(*) FILTER (WHERE r_status_id IS NOT NULL) AS with_status
FROM aberp_shiftchange;
