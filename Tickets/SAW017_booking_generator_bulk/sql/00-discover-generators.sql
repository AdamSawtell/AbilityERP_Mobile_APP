-- SAW017 Phase 0 — discover Generate* and Booking Generator processes
-- Run on a host that has Flamingo/Logilite customization JARs installed.
SET search_path TO adempiere;

-- 1) All generate / booking-related processes
SELECT p.ad_process_id, p.ad_process_uu, p.value, p.name, p.classname, p.procedurename, p.isactive
FROM ad_process p
WHERE p.classname ILIKE '%Generate%'
   OR p.name ILIKE '%Generate%'
   OR p.name ILIKE '%Booking%'
   OR p.value ILIKE '%Booking%'
   OR p.value ILIKE '%Generate%'
ORDER BY p.name;

-- 2) Parameters for those processes (run after noting IDs from #1, or join)
SELECT p.value AS process_value, p.name AS process_name, pp.seqno, pp.columnname, pp.name,
       pp.ad_reference_id, pp.ismandatory, pp.defaultvalue, pp.isactive
FROM ad_process p
JOIN ad_process_para pp ON pp.ad_process_id = p.ad_process_id
WHERE p.classname ILIKE '%Generate%'
   OR p.name ILIKE '%Generate%Booking%'
   OR p.name ILIKE '%Generate Bookings%'
   OR p.name ILIKE '%Generate Timesheet%'
   OR p.name ILIKE '%Generate Invoice%'
   OR p.name ILIKE '%Generate Roster%'
ORDER BY p.name, pp.seqno;

-- 3) Buttons on Booking Generator table
SELECT t.tablename, c.columnname, c.name, c.ad_reference_id, c.ad_process_id,
       p.value AS process_value, p.classname, c.istoolbarbutton
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
LEFT JOIN ad_process p ON p.ad_process_id = c.ad_process_id
WHERE t.tablename = 'AbERP_BookingGenerator'
  AND (c.ad_reference_id = 28 OR c.ad_process_id IS NOT NULL)
ORDER BY c.columnname;

-- 4) BG columns useful for Standards / POS / dates / activity
SELECT c.columnname, c.name, c.ad_reference_id, c.fieldlength, c.isactive
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'AbERP_BookingGenerator'
  AND (
    c.columnname ILIKE '%date%'
    OR c.columnname ILIKE '%template%'
    OR c.columnname ILIKE '%program%'
    OR c.columnname ILIKE '%quote%'
    OR c.columnname ILIKE '%invoice%'
    OR c.columnname ILIKE '%desc%'
    OR c.columnname ILIKE '%activ%'
    OR c.columnname ILIKE '%type%'
    OR c.columnname ILIKE '%standard%'
    OR c.columnname ILIKE '%bulk%'
  )
ORDER BY c.columnname;

-- 5) SB flags used as generation targets / filters
SELECT c.columnname, c.name, c.ad_reference_id
FROM ad_column c
JOIN ad_table t ON t.ad_table_id = c.ad_table_id
WHERE t.tablename = 'C_Order'
  AND c.columnname IN (
    'AbERP_BookingGenerator_ID', 'AbERP_IsTemplate', 'AbERP_IsProgramOfSupports',
    'InvoiceRule', 'AbERP_StartDate', 'AbERP_EndDate', 'Description', 'C_DocTypeTarget_ID'
  )
ORDER BY c.columnname;
