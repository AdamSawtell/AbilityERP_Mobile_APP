SET search_path TO adempiere;

SELECT ad_table_id, tablename, ad_table_uu FROM ad_table WHERE tablename='C_ContactActivity';

SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='c_contactactivity'
  AND column_name IN ('aberp_bookinggenerator_id','c_order_id','c_project_id','aberp_user_bp_id');

SELECT c.ad_column_id, c.columnname, c.ad_column_uu, c.ad_table_id
FROM ad_column c
JOIN ad_table t ON t.ad_table_id=c.ad_table_id
WHERE t.tablename='C_ContactActivity'
  AND c.columnname IN ('AbERP_BookingGenerator_ID','C_Order_ID','C_Project_ID','AbERP_User_BP_ID','AD_User_ID','ContactActivityType')
ORDER BY 2;

SELECT w.ad_window_id, w.name, w.ad_window_uu
FROM ad_window w
WHERE w.name IN ('Enquiry','Booking Generator','Service Booking','Service Agreement (Project)')
ORDER BY 2;

SELECT w.name AS window, t.ad_tab_id, t.name AS tab, t.ad_tab_uu, tb.tablename
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id=t.ad_window_id
JOIN ad_table tb ON tb.ad_table_id=t.ad_table_id
WHERE t.name='Activity'
  AND w.name IN ('Enquiry','Booking Generator','Service Booking','Service Agreement (Project)')
ORDER BY 1;

SELECT name FROM ad_element WHERE columnname='AbERP_BookingGenerator_ID';
SELECT name FROM ad_element WHERE columnname='AbERP_User_BP_ID';
