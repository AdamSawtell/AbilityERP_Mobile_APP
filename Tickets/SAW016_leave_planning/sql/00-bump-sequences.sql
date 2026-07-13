-- bump sequences past max used ids
UPDATE ad_sequence SET currentnext = GREATEST(currentnext,
  (SELECT COALESCE(MAX(ad_window_id),0)+1 FROM ad_window))
WHERE name='AD_Window' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext,
  (SELECT COALESCE(MAX(ad_tab_id),0)+1 FROM ad_tab))
WHERE name='AD_Tab' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext,
  (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field))
WHERE name='AD_Field' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext,
  (SELECT COALESCE(MAX(ad_column_id),0)+1 FROM ad_column))
WHERE name='AD_Column' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext,
  (SELECT COALESCE(MAX(ad_menu_id),0)+1 FROM ad_menu))
WHERE name='AD_Menu' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext,
  (SELECT COALESCE(MAX(ad_process_id),0)+1 FROM ad_process))
WHERE name='AD_Process' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext,
  (SELECT COALESCE(MAX(ad_process_para_id),0)+1 FROM ad_process_para))
WHERE name='AD_Process_Para' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext,
  (SELECT COALESCE(MAX(ad_reportview_id),0)+1 FROM ad_reportview))
WHERE name='AD_ReportView' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext,
  (SELECT COALESCE(MAX(ad_reference_id),0)+1 FROM ad_reference))
WHERE name='AD_Reference' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext,
  (SELECT COALESCE(MAX(ad_table_id),0)+1 FROM ad_table))
WHERE name='AD_Table' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext,
  (SELECT COALESCE(MAX(ad_val_rule_id),0)+1 FROM ad_val_rule))
WHERE name='AD_Val_Rule' AND istableid='Y';
UPDATE ad_sequence SET currentnext = GREATEST(currentnext,
  (SELECT COALESCE(MAX(ad_element_id),0)+1 FROM ad_element))
WHERE name='AD_Element' AND istableid='Y';

SELECT name, currentnext FROM ad_sequence
WHERE name IN ('AD_Window','AD_Tab','AD_Field','AD_Menu','AD_Process') AND istableid='Y';

SELECT ad_window_id, name, ad_window_uu FROM ad_window WHERE name='Leave Planning';
