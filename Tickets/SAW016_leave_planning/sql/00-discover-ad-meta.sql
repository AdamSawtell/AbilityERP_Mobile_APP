\echo === Entity Ab_ERP ===
SELECT * FROM ad_entitytype WHERE entitytype IN ('Ab_ERP','U','HCO','D','C');

\echo === How Unavailability Leave table was registered (sample cols) ===
SELECT ad_reference_id, name FROM ad_reference WHERE ad_reference_id IN (15,16,19,20,10,14,13,17,30,28,11,200162);

\echo === C_BPartner_Location table id ===
SELECT ad_table_id, tablename, ad_table_uu FROM ad_table WHERE tablename='C_BPartner_Location';

\echo === Existing table ref for C_BPartner_Location ===
SELECT ad_reference_id, name, validationtype, ad_reference_uu FROM ad_reference
WHERE name ILIKE '%Partner Location%' OR name ILIKE '%C_BPartner_Location%'
ORDER BY name LIMIT 20;

\echo === Tree for menu ===
SELECT ad_tree_id, name, treetype, ad_client_id FROM ad_tree WHERE treetype='MM' ORDER BY ad_client_id;

SELECT tn.parent_id, m.name, m.ad_menu_id
FROM ad_treenodemm tn
JOIN ad_menu m ON m.ad_menu_id=tn.node_id
WHERE m.name='Rostering' OR tn.parent_id IN (SELECT ad_menu_id FROM ad_menu WHERE name='Rostering')
ORDER BY tn.seqno LIMIT 40;

\echo === Access on Unavailability Leave window ===
SELECT r.name, wa.isreadwrite
FROM ad_window_access wa
JOIN ad_role r ON r.ad_role_id=wa.ad_role_id
WHERE wa.ad_window_id=1000128
ORDER BY r.name;
