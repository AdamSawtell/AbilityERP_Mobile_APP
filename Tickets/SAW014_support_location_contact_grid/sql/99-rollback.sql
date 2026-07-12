-- SAW014 rollback: restore prior @SQL= ColumnSQL (grid reverts to selected-row-only behaviour)
DO $$
BEGIN
  UPDATE ad_column SET columnsql =
    '@SQL=SELECT Email  FROM C_BPartner_Location   WHERE C_BPartner_Location_ID = @C_BPartner_Location_ID:0@',
    updated = NOW(), updatedby = 100
  WHERE ad_column_uu = 'bd54d23d-44b6-42d7-b8c8-30b3e7b826e6';

  UPDATE ad_column SET columnsql =
    '@SQL=SELECT Phone  FROM C_BPartner_Location   WHERE C_BPartner_Location_ID = @C_BPartner_Location_ID:0@',
    updated = NOW(), updatedby = 100
  WHERE ad_column_uu = '5f9a40e5-248b-48bd-848f-532ae4601006';

  UPDATE ad_column SET columnsql =
    '@SQL=SELECT Phone2  FROM C_BPartner_Location   WHERE C_BPartner_Location_ID = @C_BPartner_Location_ID:0@',
    updated = NOW(), updatedby = 100
  WHERE ad_column_uu = 'f41c821a-90fb-4b8b-95c6-8bf2f181f8e7';

  UPDATE ad_column SET columnsql =
    '@SQL=SELECT Name  FROM C_BPartner_Location   WHERE C_BPartner_Location_ID = @C_BPartner_Location_ID:0@',
    updated = NOW(), updatedby = 100
  WHERE ad_column_uu = '21b6490e-5aea-4035-b64c-c45c7cc05161';

  UPDATE ad_column SET columnsql =
    '@SQL=SELECT IsActive    FROM C_BPartner_Location  WHERE C_BPartner_Location_ID = @C_BPartner_Location_ID:0@',
    updated = NOW(), updatedby = 100
  WHERE ad_column_uu = 'a77b2962-807c-464b-a8f5-1871ffd9fd1c';

  RAISE NOTICE 'SAW014 rollback: restored @SQL= ColumnSQL';
END $$;
