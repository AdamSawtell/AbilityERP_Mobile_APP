-- =============================================================================
-- SAW016 — Leave Planning Line (bridge) so Leave Records tab is visible & linked
-- Auto-refreshed by trigger when planning criteria change.
-- Fixed UU: Table 16a0160b-c0d4-4f01-8e15-000000000001
-- =============================================================================
SET search_path TO adempiere;

CREATE TABLE IF NOT EXISTS aberp_leave_planning_line (
  aberp_leave_planning_line_id     numeric(10)  NOT NULL,
  ad_client_id                     numeric(10)  NOT NULL,
  ad_org_id                        numeric(10)  NOT NULL,
  isactive                         character(1) NOT NULL DEFAULT 'Y',
  created                          timestamp    NOT NULL DEFAULT NOW(),
  createdby                        numeric(10)  NOT NULL,
  updated                          timestamp    NOT NULL DEFAULT NOW(),
  updatedby                        numeric(10)  NOT NULL,
  aberp_leave_planning_line_uu     character varying(36),
  aberp_leave_planning_id          numeric(10)  NOT NULL,
  aberp_unavailability_leave_id    numeric(10)  NOT NULL,
  CONSTRAINT aberp_leave_planning_line_pkey PRIMARY KEY (aberp_leave_planning_line_id),
  CONSTRAINT aberp_leave_planning_line_uniq UNIQUE (aberp_leave_planning_id, aberp_unavailability_leave_id)
);

CREATE INDEX IF NOT EXISTS aberp_lp_line_plan_idx ON aberp_leave_planning_line (aberp_leave_planning_id);
CREATE INDEX IF NOT EXISTS aberp_lp_line_leave_idx ON aberp_leave_planning_line (aberp_unavailability_leave_id);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ad_sequence WHERE name = 'AbERP_Leave_Planning_Line' AND istableid = 'Y') THEN
    INSERT INTO ad_sequence (
      ad_sequence_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, isautosequence, incrementno, startno, currentnext, currentnextsys,
      isaudited, istableid, startnewyear, ad_sequence_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Sequence' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_Leave_Planning_Line', 'Table AbERP_Leave_Planning_Line', 'Y', 1, 1000000, 1000000, 1000000,
      'N', 'Y', 'N', '16a01600-0002-4000-8000-000000000001'
    );
  END IF;
END $$;

CREATE OR REPLACE FUNCTION aberp_lp_refresh_lines(p_planning_id numeric)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  v_client numeric;
  v_org numeric;
  v_user numeric := 100;
  v_cnt integer := 0;
  v_all char(1);
  v_start timestamp;
  v_end timestamp;
  v_locs text;
  v_filter_status text;
  v_filter_type numeric;
  v_next numeric;
BEGIN
  SELECT ad_client_id, ad_org_id, isalllocations, startdate, enddate,
         c_bpartner_location_ids, aberp_filterapproverstatus, aberp_filterunavailability_type_id
    INTO v_client, v_org, v_all, v_start, v_end, v_locs, v_filter_status, v_filter_type
  FROM aberp_leave_planning
  WHERE aberp_leave_planning_id = p_planning_id;

  IF NOT FOUND THEN
    RETURN 0;
  END IF;

  DELETE FROM aberp_leave_planning_line WHERE aberp_leave_planning_id = p_planning_id;

  FOR v_next IN
    SELECT ul.aberp_unavailability_leave_id
    FROM aberp_unavailability_leave ul
    JOIN ad_user u ON u.ad_user_id = ul.aberp_user_contact_id
    WHERE ul.isactive = 'Y'
      AND ul.startdate::date <= v_end::date
      AND ul.enddate::date >= v_start::date
      AND (
        v_all = 'Y'
        OR (
          COALESCE(v_locs, '') <> ''
          AND u.c_bpartner_location_id = ANY (
            string_to_array(regexp_replace(v_locs, '[^0-9,]', '', 'g'), ',')::numeric[]
          )
        )
      )
      AND (COALESCE(v_filter_status, '') = '' OR ul.aberp_approverstatus = v_filter_status)
      AND (COALESCE(v_filter_type, 0) = 0 OR ul.aberp_unavailability_type_id = v_filter_type)
  LOOP
    INSERT INTO aberp_leave_planning_line (
      aberp_leave_planning_line_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby, aberp_leave_planning_line_uu,
      aberp_leave_planning_id, aberp_unavailability_leave_id
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AbERP_Leave_Planning_Line' AND istableid = 'Y')::integer, 'N'),
      v_client, v_org, 'Y',
      NOW(), v_user, NOW(), v_user, generate_uuid(),
      p_planning_id, v_next
    );
    v_cnt := v_cnt + 1;
  END LOOP;

  RETURN v_cnt;
END;
$$;

CREATE OR REPLACE FUNCTION aberp_lp_refresh_lines_trg()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM aberp_lp_refresh_lines(NEW.aberp_leave_planning_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS aberp_lp_refresh_lines_trg ON aberp_leave_planning;
CREATE TRIGGER aberp_lp_refresh_lines_trg
  AFTER INSERT OR UPDATE OF startdate, enddate, isalllocations, c_bpartner_location_ids,
    aberp_filterapproverstatus, aberp_filterunavailability_type_id
  ON aberp_leave_planning
  FOR EACH ROW
  EXECUTE PROCEDURE aberp_lp_refresh_lines_trg();

-- Refresh existing smoke row
SELECT aberp_lp_refresh_lines(1000000) AS lines_loaded;
