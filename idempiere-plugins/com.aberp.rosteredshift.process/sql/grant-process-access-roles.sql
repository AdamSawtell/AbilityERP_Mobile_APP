-- Grant AD_Process_Access for a process to standard AbilityERP roles.
-- Usage: set PROCESS_VALUE below, then run against idempiere schema.
--
-- REQUIRED for every new process/button (see docs/DEV-REQUIREMENTS.md):
--   - AbilityERP Admin (1000004) — always
--   - System Administrator (0) — SuperUser / system maintenance
--   - Plus any operational roles (e.g. Rostering Officer 1000012)
SET search_path TO adempiere;

-- <<< SET THIS for each new process >>>
-- PROCESS_VALUE examples: 'SHIFT_ACCEPT_REQUEST', 'ShiftOfferNotification'

INSERT INTO ad_process_access (
  ad_process_id, ad_role_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby, isreadwrite, ad_process_access_uu
)
SELECT p.ad_process_id, roles.ad_role_id, roles.ad_client_id, 0, 'Y',
  NOW(), 100, NOW(), 100, 'Y', NULL
FROM ad_process p
CROSS JOIN (
  VALUES
    (1000004, 1000002),  -- AbilityERP Admin (mandatory)
    (1000012, 1000002),  -- Rostering Officer
    (0, 0)               -- System Administrator
) AS roles(ad_role_id, ad_client_id)
WHERE p.value = 'SHIFT_ACCEPT_REQUEST'
  AND NOT EXISTS (
    SELECT 1 FROM ad_process_access x
    WHERE x.ad_process_id = p.ad_process_id
      AND x.ad_role_id = roles.ad_role_id
      AND x.ad_client_id = roles.ad_client_id
  );
