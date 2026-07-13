SET search_path TO adempiere;

-- Standards candidate counts
SELECT
  COUNT(*) FILTER (WHERE dt.name='Service Booking - Standard') AS dt_standard,
  COUNT(*) FILTER (WHERE dt.name='Service Booking - Non Binding Offer') AS dt_nbo,
  COUNT(*) FILTER (WHERE dt.name='Service Booking - Standard'
    AND COALESCE(bg.istemplate,'N')='N'
    AND COALESCE(bg.aberp_isprogramofsupports,'N')='N'
    AND bg.description ILIKE '%Standard%') AS std_doctype_desc,
  COUNT(*) FILTER (WHERE dt.name='Service Booking - Standard'
    AND COALESCE(bg.istemplate,'N')='N'
    AND COALESCE(bg.aberp_isprogramofsupports,'N')='N') AS std_doctype_only
FROM aberp_bookinggenerator bg
JOIN c_doctype dt ON dt.c_doctype_id=bg.c_doctypetarget_id
WHERE bg.isactive='Y';

-- Activity x DocType
SELECT COALESCE(a.name,'(none)') AS activity, dt.name AS doctype, COUNT(*)
FROM aberp_bookinggenerator bg
LEFT JOIN c_activity a ON a.c_activity_id=bg.c_activity_id
JOIN c_doctype dt ON dt.c_doctype_id=bg.c_doctypetarget_id
WHERE bg.isactive='Y'
GROUP BY 1,2
ORDER BY 1,3 DESC;

-- Plan/wait columns on BG
SELECT c.columnname, c.name
FROM ad_column c
JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE t.tablename='AbERP_BookingGenerator'
  AND (c.columnname ILIKE '%plan%' OR c.columnname ILIKE '%wait%' OR c.columnname ILIKE '%status%'
       OR c.name ILIKE '%plan%' OR c.name ILIKE '%wait%')
ORDER BY 1;

-- All BG columns
SELECT c.columnname, c.name, c.ad_reference_id
FROM ad_column c JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE t.tablename='AbERP_BookingGenerator'
ORDER BY c.columnname;

-- Buttons for generate processes
SELECT t.tablename, c.columnname, c.name, p.value, p.classname, c.istoolbarbutton
FROM ad_column c
JOIN ad_table t ON t.ad_table_id=c.ad_table_id
JOIN ad_process p ON p.ad_process_id=c.ad_process_id
WHERE p.value IN ('Shift_Generate','Timesheet_Generate','Generate Bookings','C_Invoice_Generate','C_Invoice_Generate (manual)')
ORDER BY p.value, t.tablename;

-- Info process bindings
SELECT iw.name, iw.ad_infowindow_uu, p.value, p.classname
FROM ad_infoprocess ip
JOIN ad_infowindow iw ON iw.ad_infowindow_id=ip.ad_infowindow_id
JOIN ad_process p ON p.ad_process_id=ip.ad_process_id
WHERE p.classname ILIKE '%Generate%' OR p.name ILIKE '%Generate%'
ORDER BY iw.name;
