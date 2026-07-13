SELECT sc.documentno, sc.aberp_requestsubmitted, sc.r_requesttype_id AS sc_type,
       (SELECT name FROM r_requesttype WHERE r_requesttype_id=sc.r_requesttype_id) AS sc_type_name,
       r.r_request_id, r.documentno AS req_doc, r.r_requesttype_id AS req_type,
       (SELECT name FROM r_requesttype WHERE r_requesttype_id=r.r_requesttype_id) AS req_type_name,
       r.created
FROM aberp_shiftchange sc
LEFT JOIN r_request r ON r.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename='AbERP_ShiftChange')
  AND r.record_id = sc.aberp_shiftchange_id AND r.isactive='Y'
WHERE sc.documentno = '1003715'
ORDER BY r.created DESC NULLS LAST;
