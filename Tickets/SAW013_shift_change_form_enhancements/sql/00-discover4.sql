-- residual discovery
SELECT COUNT(*) AS sc_with_req_blank_status
FROM aberp_shiftchange sc
WHERE EXISTS (
  SELECT 1 FROM r_request r
  WHERE r.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename='AbERP_ShiftChange')
    AND r.record_id = sc.aberp_shiftchange_id AND r.isactive='Y'
)
AND sc.r_status_id IS NULL;

SELECT COUNT(*) AS sc_status_mismatch
FROM aberp_shiftchange sc
JOIN LATERAL (
  SELECT r.r_status_id FROM r_request r
  WHERE r.ad_table_id = (SELECT ad_table_id FROM ad_table WHERE tablename='AbERP_ShiftChange')
    AND r.record_id = sc.aberp_shiftchange_id AND r.isactive='Y'
  ORDER BY r.created DESC LIMIT 1
) r ON TRUE
WHERE sc.r_status_id IS DISTINCT FROM r.r_status_id;

-- ad_column columns available for virtual
SELECT column_name FROM information_schema.columns
WHERE table_schema='adempiere' AND table_name='ad_column'
  AND column_name IN ('columnsql','isallowcopy','isalwaysupdateable','istoolbarbutton','ad_reference_id');

-- element for Submitted?
SELECT ad_element_id, columnname, name FROM ad_element
WHERE columnname IN ('Processed','IsSubmitted','Submitted','R_Status_ID')
   OR name ILIKE '%Submitted%'
LIMIT 20;

-- Does Logilite jar exist on server?
-- (run via shell separately)
