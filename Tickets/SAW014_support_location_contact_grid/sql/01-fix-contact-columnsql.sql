-- SAW014: replace @SQL= virtual columns with correlated subquery ColumnSQL
-- so Email / Phone / Phone2 (and Location Name / Location Is Active) evaluate
-- for every Grid View row in iDempiere 7 — not only the selected row.
--
-- Pattern matches existing AbERP_Location_Address / AbERP_Occupant_Type on this table.
-- No physical columns added; values still read live from C_BPartner_Location.
-- Resolve targets by AD_Column_UU only.

DO $$
DECLARE
  v_email_uu   CONSTANT varchar := 'bd54d23d-44b6-42d7-b8c8-30b3e7b826e6'; -- AbERP_Email (seed hint 1001645)
  v_phone_uu   CONSTANT varchar := '5f9a40e5-248b-48bd-848f-532ae4601006'; -- AbERP_Phone (seed hint 1001646)
  v_phone2_uu  CONSTANT varchar := 'f41c821a-90fb-4b8b-95c6-8bf2f181f8e7'; -- AbERP_Phone2 (seed hint 1001647)
  v_locname_uu CONSTANT varchar := '21b6490e-5aea-4035-b64c-c45c7cc05161'; -- AbERP_LocationName (seed hint 1000357)
  v_locact_uu  CONSTANT varchar := 'a77b2962-807c-464b-a8f5-1871ffd9fd1c'; -- AbERP_Location_IsActive (seed hint 1000361)

  v_email_sql   CONSTANT text :=
    '(SELECT Email FROM C_BPartner_Location WHERE C_BPartner_Location_ID=AbERP_Support_Location.C_BPartner_Location_ID)';
  v_phone_sql   CONSTANT text :=
    '(SELECT Phone FROM C_BPartner_Location WHERE C_BPartner_Location_ID=AbERP_Support_Location.C_BPartner_Location_ID)';
  v_phone2_sql  CONSTANT text :=
    '(SELECT Phone2 FROM C_BPartner_Location WHERE C_BPartner_Location_ID=AbERP_Support_Location.C_BPartner_Location_ID)';
  v_locname_sql CONSTANT text :=
    '(SELECT Name FROM C_BPartner_Location WHERE C_BPartner_Location_ID=AbERP_Support_Location.C_BPartner_Location_ID)';
  v_locact_sql  CONSTANT text :=
    '(SELECT IsActive FROM C_BPartner_Location WHERE C_BPartner_Location_ID=AbERP_Support_Location.C_BPartner_Location_ID)';

  v_n integer;
BEGIN
  UPDATE ad_column
     SET columnsql = v_email_sql,
         updated = NOW(),
         updatedby = 100
   WHERE ad_column_uu = v_email_uu;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'SAW014: AbERP_Email column UU % not found', v_email_uu;
  END IF;

  UPDATE ad_column
     SET columnsql = v_phone_sql,
         updated = NOW(),
         updatedby = 100
   WHERE ad_column_uu = v_phone_uu;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'SAW014: AbERP_Phone column UU % not found', v_phone_uu;
  END IF;

  UPDATE ad_column
     SET columnsql = v_phone2_sql,
         updated = NOW(),
         updatedby = 100
   WHERE ad_column_uu = v_phone2_uu;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'SAW014: AbERP_Phone2 column UU % not found', v_phone2_uu;
  END IF;

  -- Same @SQL= defect for Location Name / Location Is Active (fix for grid consistency)
  UPDATE ad_column
     SET columnsql = v_locname_sql,
         updated = NOW(),
         updatedby = 100
   WHERE ad_column_uu = v_locname_uu;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'SAW014: AbERP_LocationName column UU % not found', v_locname_uu;
  END IF;

  UPDATE ad_column
     SET columnsql = v_locact_sql,
         updated = NOW(),
         updatedby = 100
   WHERE ad_column_uu = v_locact_uu;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'SAW014: AbERP_Location_IsActive column UU % not found', v_locact_uu;
  END IF;

  RAISE NOTICE 'SAW014: ColumnSQL updated for Email/Phone/Phone2/LocationName/LocationIsActive';
END $$;
