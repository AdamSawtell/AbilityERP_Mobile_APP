SET search_path TO adempiere, public;

-- =============================================================================
-- Rename Rostering Chat process search keys (AD_Process.Value):
--   ROSTERING_CHAT_REPLY → AbERP_RosteringChat_Send
--   ROSTERING_CHAT_CLOSE → AbERP_RosteringChat_Close
-- Display names stay Send Chat / Close Chat (button labels).
-- =============================================================================

UPDATE ad_process
SET value = 'AbERP_RosteringChat_Send',
    name = 'Send Chat',
    description = 'Send the Reply field to the worker app',
    help = 'Type your message in Reply, then click Send Chat.',
    updated = NOW(),
    updatedby = 100
WHERE value = 'ROSTERING_CHAT_REPLY';

UPDATE ad_process
SET value = 'AbERP_RosteringChat_Close',
    name = 'Close Chat',
    description = 'Close this chat so the worker can start a new conversation',
    help = 'Marks the Rostering Chat as Closed.',
    updated = NOW(),
    updatedby = 100
WHERE value = 'ROSTERING_CHAT_CLOSE';

-- Idempotent if already renamed
UPDATE ad_process
SET name = 'Send Chat',
    description = 'Send the Reply field to the worker app',
    help = 'Type your message in Reply, then click Send Chat.',
    updated = NOW(),
    updatedby = 100
WHERE value = 'AbERP_RosteringChat_Send';

UPDATE ad_process
SET name = 'Close Chat',
    description = 'Close this chat so the worker can start a new conversation',
    help = 'Marks the Rostering Chat as Closed.',
    updated = NOW(),
    updatedby = 100
WHERE value = 'AbERP_RosteringChat_Close';

SELECT 'processes' AS c, value, name, classname, isactive
FROM ad_process
WHERE value IN (
  'AbERP_RosteringChat_Send', 'AbERP_RosteringChat_Close',
  'ROSTERING_CHAT_REPLY', 'ROSTERING_CHAT_CLOSE'
)
ORDER BY value;

SELECT 'access' AS c, p.value, r.name AS role, pa.isreadwrite
FROM ad_process_access pa
JOIN ad_process p ON p.ad_process_id = pa.ad_process_id
JOIN ad_role r ON r.ad_role_id = pa.ad_role_id
WHERE p.value IN ('AbERP_RosteringChat_Send', 'AbERP_RosteringChat_Close')
  AND pa.isactive = 'Y'
ORDER BY p.value, r.name;
