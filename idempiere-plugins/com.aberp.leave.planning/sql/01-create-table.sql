-- =============================================================================
-- SAW016 — Leave Planning: physical table + sequences
-- =============================================================================
SET search_path TO adempiere;

CREATE TABLE IF NOT EXISTS aberp_leave_planning (
  aberp_leave_planning_id          numeric(10)  NOT NULL,
  ad_client_id                     numeric(10)  NOT NULL,
  ad_org_id                        numeric(10)  NOT NULL,
  isactive                         character(1) NOT NULL DEFAULT 'Y',
  created                          timestamp    NOT NULL DEFAULT NOW(),
  createdby                        numeric(10)  NOT NULL,
  updated                          timestamp    NOT NULL DEFAULT NOW(),
  updatedby                        numeric(10)  NOT NULL,
  aberp_leave_planning_uu          character varying(36) DEFAULT NULL,
  name                             character varying(120),
  startdate                        timestamp    NOT NULL,
  enddate                          timestamp    NOT NULL,
  isalllocations                   character(1) NOT NULL DEFAULT 'N',
  c_bpartner_location_ids          character varying(4000),
  aberp_filterapproverstatus       character varying(4),
  aberp_filterunavailability_type_id numeric(10),
  CONSTRAINT aberp_leave_planning_pkey PRIMARY KEY (aberp_leave_planning_id),
  CONSTRAINT aberp_leave_planning_isactive_chk CHECK (isactive IN ('Y','N')),
  CONSTRAINT aberp_leave_planning_allloc_chk CHECK (isalllocations IN ('Y','N')),
  CONSTRAINT aberp_leave_planning_dates_chk CHECK (enddate >= startdate)
);

CREATE UNIQUE INDEX IF NOT EXISTS aberp_leave_planning_uu_idx
  ON aberp_leave_planning (aberp_leave_planning_uu);

-- Table ID sequence (iDempiere convention)
DO $$
DECLARE
  v_seq_id INTEGER;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ad_sequence WHERE name = 'AbERP_Leave_Planning' AND istableid = 'Y') THEN
    INSERT INTO ad_sequence (
      ad_sequence_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      name, description, vformat, isautosequence,
      incrementno, startno, currentnext, currentnextsys,
      isaudited, istableid, prefix, suffix, startnewyear,
      decimalpattern, ad_sequence_uu
    ) VALUES (
      nextidfunc((SELECT ad_sequence_id FROM ad_sequence WHERE name = 'AD_Sequence' AND istableid = 'Y')::integer, 'N'),
      0, 0, 'Y', NOW(), 100, NOW(), 100,
      'AbERP_Leave_Planning', 'Table AbERP_Leave_Planning', NULL, 'Y',
      1, 1000000, 1000000, 1000000,
      'N', 'Y', NULL, NULL, 'N',
      NULL, '16a01600-0001-4f01-8e15-000000000001'
    );
  END IF;
END $$;
