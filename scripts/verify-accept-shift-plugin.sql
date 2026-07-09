SET search_path TO adempiere;

SELECT ad_process_id, value, name, classname, isactive
FROM ad_process WHERE value = 'SHIFT_ACCEPT_REQUEST';

SELECT tb.ad_toolbarbutton_id, tb.name, tb.ad_tab_id, tb.ad_process_id, tb.displaylogic, tb.isactive
FROM ad_toolbarbutton tb
WHERE tb.name = 'Accept Shift Request';

SELECT COUNT(*) AS access_rows
FROM ad_process_access pa
JOIN ad_process p ON p.ad_process_id = pa.ad_process_id
WHERE p.value = 'SHIFT_ACCEPT_REQUEST' AND pa.isactive = 'Y';

SELECT rl.aberp_rosteredresponselog_id, rl.aberp_rostered_shift_id, rl.aberp_user_contact_id,
       rl.aberp_rosteredresponse, rl.isreviewed, rl.issuperseded
FROM aberp_rosteredresponselog rl
WHERE rl.aberp_rosteredresponselog_id = 1000002;

SELECT ss.aberp_rostered_shiftstaff_id, ss.c_bpartner_staff_id, ss.aberp_user_contact_id, ss.aberp_requestshift
FROM aberp_rostered_shiftstaff ss
WHERE ss.aberp_rostered_shift_id = 1000484 AND ss.isactive = 'Y';
