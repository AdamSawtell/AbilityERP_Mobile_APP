-- =============================================================================
-- SAW019 — physical tables + ID sequences
-- =============================================================================
SET search_path TO adempiere;

CREATE TABLE IF NOT EXISTS aberp_invoicecapture (
  aberp_invoicecapture_id     numeric(10)  NOT NULL,
  ad_client_id                numeric(10)  NOT NULL,
  ad_org_id                   numeric(10)  NOT NULL,
  isactive                    character(1) NOT NULL DEFAULT 'Y',
  created                     timestamp    NOT NULL DEFAULT NOW(),
  createdby                   numeric(10)  NOT NULL,
  updated                     timestamp    NOT NULL DEFAULT NOW(),
  updatedby                   numeric(10)  NOT NULL,
  aberp_invoicecapture_uu     character varying(36) DEFAULT NULL,
  documentno                  character varying(60),
  name                        character varying(120),
  capturestatus               character varying(2) NOT NULL DEFAULT 'PE',
  filepath                    character varying(1000),
  vendorinvoiceno             character varying(60),
  taxid                       character varying(40),
  invoicedate                 timestamp,
  grandtotal                  numeric,
  c_bpartner_id               numeric(10),
  c_order_id                  numeric(10),
  c_invoice_id                numeric(10),
  extractedtext               character varying(4000),
  lastresult                  character varying(255),
  processed                   character(1) DEFAULT 'N',
  aberp_processselected       character(1),
  CONSTRAINT aberp_invoicecapture_pkey PRIMARY KEY (aberp_invoicecapture_id),
  CONSTRAINT aberp_invoicecapture_isactive_chk CHECK (isactive IN ('Y','N')),
  CONSTRAINT aberp_invoicecapture_processed_chk CHECK (processed IN ('Y','N') OR processed IS NULL)
);

CREATE UNIQUE INDEX IF NOT EXISTS aberp_invoicecapture_uu_idx
  ON aberp_invoicecapture (aberp_invoicecapture_uu);

CREATE INDEX IF NOT EXISTS aberp_invoicecapture_status_idx
  ON aberp_invoicecapture (ad_client_id, capturestatus);

CREATE TABLE IF NOT EXISTS aberp_invoicecapturelog (
  aberp_invoicecapturelog_id  numeric(10)  NOT NULL,
  ad_client_id                numeric(10)  NOT NULL,
  ad_org_id                   numeric(10)  NOT NULL,
  isactive                    character(1) NOT NULL DEFAULT 'Y',
  created                     timestamp    NOT NULL DEFAULT NOW(),
  createdby                   numeric(10)  NOT NULL,
  updated                     timestamp    NOT NULL DEFAULT NOW(),
  updatedby                   numeric(10)  NOT NULL,
  aberp_invoicecapturelog_uu  character varying(36) DEFAULT NULL,
  aberp_invoicecapture_id     numeric(10)  NOT NULL,
  processedat                 timestamp    NOT NULL DEFAULT NOW(),
  resultcode                  character varying(40),
  message                     character varying(2000),
  triggertype                 character varying(20),
  c_invoice_id                numeric(10),
  CONSTRAINT aberp_invoicecapturelog_pkey PRIMARY KEY (aberp_invoicecapturelog_id),
  CONSTRAINT aberp_invoicecapturelog_isactive_chk CHECK (isactive IN ('Y','N'))
);

CREATE UNIQUE INDEX IF NOT EXISTS aberp_invoicecapturelog_uu_idx
  ON aberp_invoicecapturelog (aberp_invoicecapturelog_uu);

CREATE INDEX IF NOT EXISTS aberp_invoicecapturelog_parent_idx
  ON aberp_invoicecapturelog (aberp_invoicecapture_id);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ad_sequence WHERE name = 'AbERP_InvoiceCapture' AND istableid = 'Y') THEN
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
      'AbERP_InvoiceCapture', 'Table AbERP_InvoiceCapture', NULL, 'Y',
      1, 1000000, 1000000, 1000000,
      'N', 'Y', NULL, NULL, 'N',
      NULL, '19a0190c-c0d4-4f01-8e15-000000000001'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ad_sequence WHERE name = 'AbERP_InvoiceCaptureLog' AND istableid = 'Y') THEN
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
      'AbERP_InvoiceCaptureLog', 'Table AbERP_InvoiceCaptureLog', NULL, 'Y',
      1, 1000000, 1000000, 1000000,
      'N', 'Y', NULL, NULL, 'N',
      NULL, '19a0190d-c0d4-4f01-8e15-000000000001'
    );
  END IF;
END $$;
