SET search_path TO adempiere;

-- Silent Send: no dialog, but pass form Reply via hidden default @AbERP_RosteringReply@
UPDATE ad_process
SET showhelp = 'S',
    updated = NOW(),
    updatedby = 100
WHERE value IN ('AbERP_RosteringChat_Send', 'AbERP_RosteringChat_Close');

-- Reply param: ACTIVE + HIDDEN + default from form field (critical for silent send)
UPDATE ad_process_para pp
SET isactive = 'Y',
    ismandatory = 'N',
    displaylogic = '@0@=1',
    defaultvalue = '@AbERP_RosteringReply@',
    updated = NOW(),
    updatedby = 100
FROM ad_process p
WHERE pp.ad_process_id = p.ad_process_id
  AND p.value = 'AbERP_RosteringChat_Send'
  AND pp.columnname = 'Reply';

UPDATE ad_process_para pp
SET isactive = 'Y',
    ismandatory = 'N',
    displaylogic = '@0@=1',
    defaultvalue = '@R_Request_ID@',
    updated = NOW(),
    updatedby = 100
FROM ad_process p
WHERE pp.ad_process_id = p.ad_process_id
  AND p.value IN ('AbERP_RosteringChat_Send', 'AbERP_RosteringChat_Close')
  AND pp.columnname = 'R_Request_ID';

SELECT p.value, p.showhelp, pp.columnname, pp.isactive, pp.displaylogic, pp.defaultvalue
FROM ad_process p
LEFT JOIN ad_process_para pp ON pp.ad_process_id = p.ad_process_id
WHERE p.value IN ('AbERP_RosteringChat_Send', 'AbERP_RosteringChat_Close')
ORDER BY p.value, pp.seqno;
