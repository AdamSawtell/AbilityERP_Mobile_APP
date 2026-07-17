-- =============================================================================
-- SAW027 — physical tables + ID sequences
-- =============================================================================
SET search_path TO adempiere;

CREATE TABLE IF NOT EXISTS aberp_activityauditterm (
  aberp_activityauditterm_id   numeric(10)  NOT NULL,
  ad_client_id                 numeric(10)  NOT NULL,
  ad_org_id                    numeric(10)  NOT NULL DEFAULT 0,
  isactive                     character(1) NOT NULL DEFAULT 'Y',
  created                      timestamp    NOT NULL DEFAULT NOW(),
  createdby                    numeric(10)  NOT NULL,
  updated                      timestamp    NOT NULL DEFAULT NOW(),
  updatedby                    numeric(10)  NOT NULL,
  aberp_activityauditterm_uu   character varying(36) DEFAULT NULL,
  auditword                    character varying(255) NOT NULL,
  description                  character varying(500),
  category                     character varying(2) NOT NULL DEFAULT 'OT',
  risklevel                    character varying(2) NOT NULL DEFAULT 'MD',
  matchtype                    character varying(2) NOT NULL DEFAULT 'EW',
  validfrom                    timestamp,
  validto                      timestamp,
  CONSTRAINT aberp_activityauditterm_pkey PRIMARY KEY (aberp_activityauditterm_id),
  CONSTRAINT aberp_activityauditterm_isactive_chk CHECK (isactive IN ('Y','N'))
);

CREATE UNIQUE INDEX IF NOT EXISTS aberp_activityauditterm_uu_idx
  ON aberp_activityauditterm (aberp_activityauditterm_uu);
CREATE INDEX IF NOT EXISTS aberp_activityauditterm_client_idx
  ON aberp_activityauditterm (ad_client_id, ad_org_id, isactive);

CREATE TABLE IF NOT EXISTS aberp_activityaudittermaudit (
  aberp_activityaudittermaudit_id numeric(10)  NOT NULL,
  ad_client_id                    numeric(10)  NOT NULL,
  ad_org_id                       numeric(10)  NOT NULL DEFAULT 0,
  isactive                        character(1) NOT NULL DEFAULT 'Y',
  created                         timestamp    NOT NULL DEFAULT NOW(),
  createdby                       numeric(10)  NOT NULL,
  updated                         timestamp    NOT NULL DEFAULT NOW(),
  updatedby                       numeric(10)  NOT NULL,
  aberp_activityaudittermaudit_uu character varying(36) DEFAULT NULL,
  aberp_activityauditterm_id      numeric(10)  NOT NULL,
  fieldname                       character varying(60),
  changetype                      character varying(40),
  oldvalue                        character varying(2000),
  newvalue                        character varying(2000),
  changedby                       numeric(10),
  changeddate                     timestamp    NOT NULL DEFAULT NOW(),
  CONSTRAINT aberp_activityaudittermaudit_pkey PRIMARY KEY (aberp_activityaudittermaudit_id),
  CONSTRAINT aberp_activityaudittermaudit_isactive_chk CHECK (isactive IN ('Y','N'))
);

CREATE UNIQUE INDEX IF NOT EXISTS aberp_activityaudittermaudit_uu_idx
  ON aberp_activityaudittermaudit (aberp_activityaudittermaudit_uu);
CREATE INDEX IF NOT EXISTS aberp_activityaudittermaudit_parent_idx
  ON aberp_activityaudittermaudit (aberp_activityauditterm_id);

CREATE TABLE IF NOT EXISTS aberp_activityauditproc (
  aberp_activityauditproc_id   numeric(10)  NOT NULL,
  ad_client_id                 numeric(10)  NOT NULL,
  ad_org_id                    numeric(10)  NOT NULL DEFAULT 0,
  isactive                     character(1) NOT NULL DEFAULT 'Y',
  created                      timestamp    NOT NULL DEFAULT NOW(),
  createdby                    numeric(10)  NOT NULL,
  updated                      timestamp    NOT NULL DEFAULT NOW(),
  updatedby                    numeric(10)  NOT NULL,
  aberp_activityauditproc_uu   character varying(36) DEFAULT NULL,
  c_contactactivity_id         numeric(10)  NOT NULL,
  activityupdated              timestamp    NOT NULL,
  lastaudited                  timestamp    NOT NULL DEFAULT NOW(),
  auditresult                  character varying(2) NOT NULL DEFAULT 'NM',
  matchedterms                 character varying(2000),
  termsapplied                 character varying(2000),
  CONSTRAINT aberp_activityauditproc_pkey PRIMARY KEY (aberp_activityauditproc_id),
  CONSTRAINT aberp_activityauditproc_isactive_chk CHECK (isactive IN ('Y','N'))
);

CREATE UNIQUE INDEX IF NOT EXISTS aberp_activityauditproc_uu_idx
  ON aberp_activityauditproc (aberp_activityauditproc_uu);
CREATE UNIQUE INDEX IF NOT EXISTS aberp_activityauditproc_act_idx
  ON aberp_activityauditproc (c_contactactivity_id);
CREATE INDEX IF NOT EXISTS aberp_activityauditproc_client_idx
  ON aberp_activityauditproc (ad_client_id, lastaudited);

CREATE TABLE IF NOT EXISTS aberp_activityauditreview (
  aberp_activityauditreview_id numeric(10)  NOT NULL,
  ad_client_id                 numeric(10)  NOT NULL,
  ad_org_id                    numeric(10)  NOT NULL DEFAULT 0,
  isactive                     character(1) NOT NULL DEFAULT 'Y',
  created                      timestamp    NOT NULL DEFAULT NOW(),
  createdby                    numeric(10)  NOT NULL,
  updated                      timestamp    NOT NULL DEFAULT NOW(),
  updatedby                    numeric(10)  NOT NULL,
  aberp_activityauditreview_uu character varying(36) DEFAULT NULL,
  c_contactactivity_id         numeric(10)  NOT NULL,
  activitydate                 timestamp,
  c_bpartner_id                numeric(10),
  ad_user_id                   numeric(10),
  contactactivitytype          character varying(10),
  matchedterms                 character varying(2000),
  matchedextract               character varying(4000),
  category                     character varying(2),
  highestrisklevel             character varying(2),
  reviewstatus                 character varying(2) NOT NULL DEFAULT 'NW',
  isreviewed                   character(1) NOT NULL DEFAULT 'N',
  reviewedby                   numeric(10),
  revieweddate                 timestamp,
  reviewnotes                  character varying(2000),
  isfollowuprequired           character(1) DEFAULT 'N',
  activityupdatedaudited       timestamp,
  processing                   character(1) NOT NULL DEFAULT 'N',
  CONSTRAINT aberp_activityauditreview_pkey PRIMARY KEY (aberp_activityauditreview_id),
  CONSTRAINT aberp_activityauditreview_isactive_chk CHECK (isactive IN ('Y','N')),
  CONSTRAINT aberp_activityauditreview_isreviewed_chk CHECK (isreviewed IN ('Y','N')),
  CONSTRAINT aberp_activityauditreview_isfollowup_chk CHECK (isfollowuprequired IN ('Y','N') OR isfollowuprequired IS NULL),
  CONSTRAINT aberp_activityauditreview_processing_chk CHECK (processing IN ('Y','N'))
);

CREATE UNIQUE INDEX IF NOT EXISTS aberp_activityauditreview_uu_idx
  ON aberp_activityauditreview (aberp_activityauditreview_uu);
CREATE INDEX IF NOT EXISTS aberp_activityauditreview_act_idx
  ON aberp_activityauditreview (c_contactactivity_id);
CREATE INDEX IF NOT EXISTS aberp_activityauditreview_queue_idx
  ON aberp_activityauditreview (ad_client_id, isreviewed, reviewstatus);
CREATE INDEX IF NOT EXISTS aberp_activityauditreview_bp_idx
  ON aberp_activityauditreview (c_bpartner_id);

CREATE TABLE IF NOT EXISTS aberp_activityauditrunt (
  aberp_activityauditrunt_id   numeric(10)  NOT NULL,
  ad_client_id                 numeric(10)  NOT NULL,
  ad_org_id                    numeric(10)  NOT NULL DEFAULT 0,
  isactive                     character(1) NOT NULL DEFAULT 'Y',
  created                      timestamp    NOT NULL DEFAULT NOW(),
  createdby                    numeric(10)  NOT NULL,
  updated                      timestamp    NOT NULL DEFAULT NOW(),
  updatedby                    numeric(10)  NOT NULL,
  aberp_activityauditrunt_uu   character varying(36) DEFAULT NULL,
  starttime                    timestamp    NOT NULL,
  endtime                      timestamp,
  periodfrom                   timestamp,
  periodto                     timestamp,
  triggertype                  character varying(2) NOT NULL DEFAULT 'NT',
  orgsprocessed                character varying(500),
  activitiesidentified         numeric DEFAULT 0,
  activitiesskipped            numeric DEFAULT 0,
  activitiesprocessed          numeric DEFAULT 0,
  activitiesnomatch            numeric DEFAULT 0,
  reviewscreated               numeric DEFAULT 0,
  reviewsreopened              numeric DEFAULT 0,
  termsappliedcount            numeric DEFAULT 0,
  errorcount                   numeric DEFAULT 0,
  summarymsg                   character varying(2000),
  CONSTRAINT aberp_activityauditrunt_pkey PRIMARY KEY (aberp_activityauditrunt_id),
  CONSTRAINT aberp_activityauditrunt_isactive_chk CHECK (isactive IN ('Y','N'))
);

CREATE UNIQUE INDEX IF NOT EXISTS aberp_activityauditrunt_uu_idx
  ON aberp_activityauditrunt (aberp_activityauditrunt_uu);
CREATE INDEX IF NOT EXISTS aberp_activityauditrunt_start_idx
  ON aberp_activityauditrunt (ad_client_id, starttime);

DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ('AbERP_ActivityAuditTerm', 'Table AbERP_ActivityAuditTerm', '27a027s1-c0d4-4f01-8e15-000000000001'),
      ('AbERP_ActivityAuditTermAudit', 'Table AbERP_ActivityAuditTermAudit', '27a027s2-c0d4-4f01-8e15-000000000001'),
      ('AbERP_ActivityAuditProc', 'Table AbERP_ActivityAuditProc', '27a027s3-c0d4-4f01-8e15-000000000001'),
      ('AbERP_ActivityAuditReview', 'Table AbERP_ActivityAuditReview', '27a027s4-c0d4-4f01-8e15-000000000001'),
      ('AbERP_ActivityAuditRunt', 'Table AbERP_ActivityAuditRunt', '27a027s5-c0d4-4f01-8e15-000000000001')
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
