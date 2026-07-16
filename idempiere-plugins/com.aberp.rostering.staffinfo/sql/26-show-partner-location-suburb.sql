-- Show Partner Location as suburb text in Staff Info search results only.
-- Was deactivated in 22-harden (Table/Search ID editor risk). Display as String
-- like Gender/Position — never query criteria.
-- Prefer C_Location.City; fall back to C_BPartner_Location.Name.
SET search_path TO adempiere;

UPDATE ad_infocolumn SET
  isactive = 'Y',
  isdisplayed = 'Y',
  isquerycriteria = 'N',
  ishideinfocolumn = 'N',
  seqnoselection = 0,
  defaultvalue = NULL,
  queryoperator = NULL,
  queryfunction = NULL,
  ad_reference_id = 10, -- String (no Intbox / Search editor)
  ad_reference_value_id = NULL,
  name = 'Partner Location',
  description = 'Staff partner location suburb (City) for search results. Not a filter.',
  help = 'Shows the suburb from the contact Partner Location (City, else location name). Display only.',
  selectclause = '(SELECT COALESCE(NULLIF(TRIM(l.City), ''''), bpl.Name) FROM C_BPartner_Location bpl LEFT JOIN C_Location l ON (l.C_Location_ID = bpl.C_Location_ID) WHERE bpl.C_BPartner_Location_ID = au.C_BPartner_Location_ID)',
  updated = NOW(),
  updatedby = 100
WHERE ad_infocolumn_uu = '904ffc84-b66a-4ec4-9984-5b85f9ad9545';

UPDATE ad_infocolumn_trl t SET
  name = 'Partner Location',
  istranslated = 'Y',
  updated = NOW(),
  updatedby = 100
FROM ad_infocolumn c
WHERE t.ad_infocolumn_id = c.ad_infocolumn_id
  AND c.ad_infocolumn_uu = '904ffc84-b66a-4ec4-9984-5b85f9ad9545';

SELECT columnname, name, isactive, isdisplayed, isquerycriteria, ad_reference_id,
       left(selectclause, 100) AS selectclause
FROM ad_infocolumn
WHERE ad_infocolumn_uu = '904ffc84-b66a-4ec4-9984-5b85f9ad9545';
