SET search_path TO adempiere, public;

-- =============================================================================
-- Live header refresh for Rostering Chat
-- Custom AD_TabType → RosteringChatTabPanel re-reads R_Request on navigate + timer
-- =============================================================================

-- Allow AD_TabType = ROSTERING_CHAT (List reference 200117)
INSERT INTO ad_ref_list (
  ad_ref_list_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  value, name, description, ad_reference_id, entitytype,
  ad_ref_list_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_ref_list_id), 0) + 1 FROM ad_ref_list),
  0, 0, 'Y',
  NOW(), 100, NOW(), 100,
  'ROSTERING_CHAT', 'Rostering Chat',
  'Auto-refresh Chat Assigned / Last Message from DB',
  200117, 'U',
  generate_uuid()
WHERE NOT EXISTS (
  SELECT 1 FROM ad_ref_list
  WHERE ad_reference_id = 200117 AND value = 'ROSTERING_CHAT'
);

UPDATE ad_tab t
SET ad_tabtype = 'ROSTERING_CHAT',
    updated = NOW(),
    updatedby = 100
FROM ad_window w
WHERE t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat'
  AND t.name = 'Chat';

SELECT 'tabtype' AS c, t.name, t.ad_tabtype, w.name AS window
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
WHERE w.name = 'Rostering Chat';
