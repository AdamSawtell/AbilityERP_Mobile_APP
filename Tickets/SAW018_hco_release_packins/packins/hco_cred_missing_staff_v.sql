--
-- PostgreSQL database dump
--

-- Dumped from database version 12.22 (Ubuntu 12.22-0ubuntu0.20.04.4)
-- Dumped by pg_dump version 12.22 (Ubuntu 12.22-0ubuntu0.20.04.4)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: hco_cred_missing_staff_v; Type: VIEW; Schema: adempiere; Owner: adempiere
--

CREATE VIEW adempiere.hco_cred_missing_staff_v AS
 SELECT bp.ad_client_id,
    bp.ad_org_id,
    'Y'::character(1) AS isactive,
    bp.created,
    COALESCE(bp.createdby, (0)::numeric) AS createdby,
    bp.updated,
    COALESCE(bp.updatedby, (0)::numeric) AS updatedby,
    (((cred.aberp_credentials_id)::bigint << 32) + (bp.c_bpartner_id)::bigint) AS hco_cred_missing_staff_v_id,
    cred.aberp_credentials_id,
    bp.c_bpartner_id,
    bp.name
   FROM (adempiere.aberp_credentials cred
     CROSS JOIN adempiere.c_bpartner bp)
  WHERE ((COALESCE(bp.isemployee, 'N'::bpchar) = 'Y'::bpchar) AND (COALESCE(bp.isactive, 'Y'::bpchar) = 'Y'::bpchar) AND (bp.ad_client_id = cred.ad_client_id) AND (NOT (EXISTS ( SELECT 1
           FROM (adempiere.aberp_credentialassignment ca
             JOIN adempiere.ad_user u ON (((u.ad_user_id = ca.aberp_user_contact_id) AND (COALESCE(u.isactive, 'Y'::bpchar) = 'Y'::bpchar))))
          WHERE ((u.c_bpartner_id = bp.c_bpartner_id) AND (ca.aberp_credentials_id = cred.aberp_credentials_id) AND (COALESCE(ca.isactive, 'Y'::bpchar) = 'Y'::bpchar))))));


ALTER TABLE adempiere.hco_cred_missing_staff_v OWNER TO adempiere;

--
-- PostgreSQL database dump complete
--

