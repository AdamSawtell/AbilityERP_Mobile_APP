-- SAW033 — point core ThemeManager logos at HCO theme images.
-- Empty ZK_LOGO_SMALL is non-null and breaks HeaderPanel (returns "").
SET search_path TO adempiere;

UPDATE ad_sysconfig
   SET value = '/theme/hco/images/login-logo.png',
       updated = NOW()
 WHERE name = 'ZK_LOGO_LARGE';

UPDATE ad_sysconfig
   SET value = '/theme/hco/images/header-logo.png',
       updated = NOW()
 WHERE name = 'ZK_LOGO_SMALL';

UPDATE ad_sysconfig
   SET value = '/theme/hco/images/header-logo.png',
       updated = NOW()
 WHERE name = 'WEBUI_LOGOURL';

-- Browser icon: only replace Flamingo leftovers; keep existing HCO S3 URL if present
UPDATE ad_sysconfig
   SET value = '/theme/hco/images/icon.png',
       updated = NOW()
 WHERE name = 'ZK_BROWSER_ICON'
   AND (value IS NULL OR value = '' OR value ILIKE '%flamingo%' OR value ILIKE '%fllogo%');

SELECT name, value
  FROM ad_sysconfig
 WHERE name IN ('ZK_THEME','ZK_LOGO_LARGE','ZK_LOGO_SMALL','WEBUI_LOGOURL','ZK_BROWSER_ICON')
 ORDER BY 1;
