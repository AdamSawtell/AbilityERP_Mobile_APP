SELECT ad_reference_id, name FROM ad_reference WHERE ad_reference_id IN (200138,200139,200162,15);
SELECT ic.ad_reference_id, ic.ad_reference_value_id, r.name, ic.queryoperator
FROM ad_infocolumn ic
LEFT JOIN ad_reference r ON r.ad_reference_id=ic.ad_reference_id
WHERE ic.columnname='AbERP_MasterLocation_ID' AND ic.ismultiselectcriteria='Y'
LIMIT 5;
