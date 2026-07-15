-- =============================================================================
-- SAW023 — physical tables + ID sequences
-- =============================================================================
SET search_path TO adempiere;

CREATE TABLE IF NOT EXISTS aberp_compliancerule (
  aberp_compliancerule_id   numeric(10)  NOT NULL,
  ad_client_id              numeric(10)  NOT NULL,
  ad_org_id                 numeric(10)  NOT NULL,
  isactive                  character(1) NOT NULL DEFAULT 'Y',
  created                   timestamp    NOT NULL DEFAULT NOW(),
  createdby                 numeric(10)  NOT NULL,
  updated                   timestamp    NOT NULL DEFAULT NOW(),
  updatedby                 numeric(10)  NOT NULL,
  aberp_compliancerule_uu   character varying(36) DEFAULT NULL,
  name                      character varying(100) NOT NULL,
  description               character varying(500),
  compliancecategory        character varying(2) NOT NULL,
  severity                  character varying(10) NOT NULL,
  weight                    numeric      NOT NULL DEFAULT 1,
  daysbeforeexpiry          numeric,
  ad_window_id              numeric(10),
  ad_infowindow_id          numeric(10),
  ad_table_id               numeric(10)  NOT NULL,
  CONSTRAINT aberp_compliancerule_pkey PRIMARY KEY (aberp_compliancerule_id),
  CONSTRAINT aberp_compliancerule_isactive_chk CHECK (isactive IN ('Y','N'))
);

CREATE UNIQUE INDEX IF NOT EXISTS aberp_compliancerule_uu_idx
  ON aberp_compliancerule (aberp_compliancerule_uu);

CREATE TABLE IF NOT EXISTS aberp_complianceresult (
  aberp_complianceresult_id numeric(10)  NOT NULL,
  ad_client_id              numeric(10)  NOT NULL,
  ad_org_id                 numeric(10)  NOT NULL,
  isactive                  character(1) NOT NULL DEFAULT 'Y',
  created                   timestamp    NOT NULL DEFAULT NOW(),
  createdby                 numeric(10)  NOT NULL,
  updated                   timestamp    NOT NULL DEFAULT NOW(),
  updatedby                 numeric(10)  NOT NULL,
  aberp_complianceresult_uu character varying(36) DEFAULT NULL,
  aberp_compliancerule_id   numeric(10)  NOT NULL,
  ad_table_id               numeric(10)  NOT NULL,
  record_id                 numeric(10)  NOT NULL,
  ad_user_id                numeric(10),
  c_bpartner_id             numeric(10),
  aberp_support_location_id numeric(10),
  datedetected              timestamp    NOT NULL,
  datechecked               timestamp,
  duedate                   timestamp,
  compliancestatus          character varying(10) NOT NULL,
  severity                  character varying(10) NOT NULL,
  resultmessage             character varying(2000),
  isresolved                character(1) NOT NULL DEFAULT 'N',
  resolveddate              timestamp,
  resolvedby                numeric(10),
  CONSTRAINT aberp_complianceresult_pkey PRIMARY KEY (aberp_complianceresult_id),
  CONSTRAINT aberp_complianceresult_isactive_chk CHECK (isactive IN ('Y','N')),
  CONSTRAINT aberp_complianceresult_isresolved_chk CHECK (isresolved IN ('Y','N'))
);

CREATE UNIQUE INDEX IF NOT EXISTS aberp_complianceresult_uu_idx
  ON aberp_complianceresult (aberp_complianceresult_uu);
CREATE INDEX IF NOT EXISTS aberp_complianceresult_status_idx
  ON aberp_complianceresult (ad_client_id, compliancestatus, severity);
CREATE INDEX IF NOT EXISTS aberp_complianceresult_date_idx
  ON aberp_complianceresult (ad_client_id, datedetected);
CREATE INDEX IF NOT EXISTS aberp_complianceresult_user_idx
  ON aberp_complianceresult (ad_user_id);
CREATE INDEX IF NOT EXISTS aberp_complianceresult_bp_idx
  ON aberp_complianceresult (c_bpartner_id);
CREATE INDEX IF NOT EXISTS aberp_complianceresult_rule_rec_idx
  ON aberp_complianceresult (aberp_compliancerule_id, ad_table_id, record_id);

CREATE TABLE IF NOT EXISTS aberp_compliancesnapshot (
  aberp_compliancesnapshot_id numeric(10)  NOT NULL,
  ad_client_id                numeric(10)  NOT NULL,
  ad_org_id                   numeric(10)  NOT NULL,
  isactive                    character(1) NOT NULL DEFAULT 'Y',
  created                     timestamp    NOT NULL DEFAULT NOW(),
  createdby                   numeric(10)  NOT NULL,
  updated                     timestamp    NOT NULL DEFAULT NOW(),
  updatedby                   numeric(10)  NOT NULL,
  aberp_compliancesnapshot_uu character varying(36) DEFAULT NULL,
  snapshotdate                timestamp    NOT NULL,
  aberp_support_location_id   numeric(10),
  compliancecategory          character varying(2) NOT NULL,
  totalitems                  numeric      NOT NULL DEFAULT 0,
  compliant                   numeric      NOT NULL DEFAULT 0,
  warning                     numeric      NOT NULL DEFAULT 0,
  noncompliant                numeric      NOT NULL DEFAULT 0,
  critical                    numeric      NOT NULL DEFAULT 0,
  overdue                     numeric      NOT NULL DEFAULT 0,
  atrisk                      numeric      NOT NULL DEFAULT 0,
  ontrack                     numeric      NOT NULL DEFAULT 0,
  auditreadinessscore         numeric(5,2) NOT NULL DEFAULT 0,
  trafficlight                character varying(2) NOT NULL,
  lastcalculated              timestamp    NOT NULL,
  CONSTRAINT aberp_compliancesnapshot_pkey PRIMARY KEY (aberp_compliancesnapshot_id),
  CONSTRAINT aberp_compliancesnapshot_isactive_chk CHECK (isactive IN ('Y','N'))
);

CREATE UNIQUE INDEX IF NOT EXISTS aberp_compliancesnapshot_uu_idx
  ON aberp_compliancesnapshot (aberp_compliancesnapshot_uu);
CREATE INDEX IF NOT EXISTS aberp_compliancesnapshot_date_idx
  ON aberp_compliancesnapshot (ad_client_id, snapshotdate, compliancecategory);
CREATE INDEX IF NOT EXISTS aberp_compliancesnapshot_loc_idx
  ON aberp_compliancesnapshot (aberp_support_location_id);

-- Table ID sequences (nextid) — match SAW019 / iDempiere 7 columns
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ('AbERP_ComplianceRule', 'Table AbERP_ComplianceRule', '23a023s1-c0d4-4f01-8e15-000000000001'),
      ('AbERP_ComplianceResult', 'Table AbERP_ComplianceResult', '23a023s2-c0d4-4f01-8e15-000000000001'),
      ('AbERP_ComplianceSnapshot', 'Table AbERP_ComplianceSnapshot', '23a023s3-c0d4-4f01-8e15-000000000001')
    ) AS t(seqname, description, seq_uu)
  LOOP
    IF NOT EXISTS (SELECT 1 FROM ad_sequence WHERE name = r.seqname AND istableid = 'Y') THEN
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
        r.seqname, r.description, NULL, 'Y',
        1, 1000000, 1000000, 1000000,
        'N', 'Y', NULL, NULL, 'N',
        NULL, r.seq_uu
      );
    END IF;
  END LOOP;
END $$;
