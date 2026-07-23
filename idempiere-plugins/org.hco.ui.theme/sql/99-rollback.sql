-- SAW033 — soft rollback: revert theme preference to default
-- Does NOT restore org.adempiere.ui.zk from .pre-hco.bak (OS-level — see DEPLOY.md).
SET search_path TO adempiere;

UPDATE ad_sysconfig SET value = 'default', updated = NOW() WHERE name = 'ZK_THEME';

SELECT name, value
  FROM ad_sysconfig
 WHERE name IN ('ZK_THEME','ZK_LOGO_LARGE','ZK_LOGO_SMALL','WEBUI_LOGOURL')
 ORDER BY 1;
