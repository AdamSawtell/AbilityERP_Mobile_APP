-- SAW033 — preflight: required sysconfig keys must exist (fail closed)
SET search_path TO adempiere;

DO $$
DECLARE
	v_missing text;
BEGIN
	SELECT string_agg(n, ', ' ORDER BY n) INTO v_missing
	FROM (
		SELECT unnest(ARRAY[
			'ZK_THEME',
			'ZK_LOGIN_LEFTPANEL_SHOWN',
			'ZK_LOGO_LARGE',
			'ZK_LOGO_SMALL',
			'WEBUI_LOGOURL',
			'ZK_BROWSER_ICON'
		]) AS n
	) req
	WHERE NOT EXISTS (
		SELECT 1 FROM ad_sysconfig s WHERE s.name = req.n
	);

	IF v_missing IS NOT NULL THEN
		RAISE EXCEPTION 'SAW033 preflight: missing AD_SysConfig row(s): %', v_missing;
	END IF;
END $$;

SELECT name, value
  FROM ad_sysconfig
 WHERE name IN (
	'ZK_THEME','ZK_LOGIN_LEFTPANEL_SHOWN','ZK_LOGO_LARGE','ZK_LOGO_SMALL','WEBUI_LOGOURL','ZK_BROWSER_ICON'
 )
 ORDER BY 1;
