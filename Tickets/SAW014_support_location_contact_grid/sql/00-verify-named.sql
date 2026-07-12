-- Verify blank grid rows vs DB contact for visible names
SELECT sl.name, bpl.email, bpl.phone, bpl.phone2
FROM aberp_support_location sl
LEFT JOIN c_bpartner_location bpl ON bpl.c_bpartner_location_id = sl.c_bpartner_location_id
WHERE sl.name ILIKE ANY (ARRAY[
  'Unit 4 Mais','Unit 4 Lehmann','Unit 3 Lehmann','Unit 2 Lehmann','Unit 1 Lehmann',
  'The Shed','Swinley 14','Swinley 15','Swinley 19','Swinley 20','Glenlea 124','Glenlea 126'
])
ORDER BY sl.name;
