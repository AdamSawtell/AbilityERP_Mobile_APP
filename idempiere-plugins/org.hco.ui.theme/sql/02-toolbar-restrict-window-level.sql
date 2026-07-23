-- SAW033 — Window-level toolbar Restrict (hide role-unavailable buttons)
--
-- Problem: many existing AD_ToolBarButtonRestrict rows are tab-scoped
-- (AD_Tab_ID NOT NULL). MToolBarButtonRestrict.getOfWindow() only returns
-- rows with AD_Tab_ID IS NULL, so those tab Restricts never hide the
-- main window toolbar (buttons stay visible / greying is state, not role).
--
-- This script upserts WINDOW-LEVEL excludes (AD_Tab_ID NULL) for the
-- Support Worker role on high-traffic windows, for buttons that should
-- not appear at all for that role.
--
-- Safe / portable: resolves Role / Window / ToolBarButton by UU or Name.
-- Does NOT hide state-based buttons (Save / Ignore) — those stay grey when
-- not currently usable.
--
-- Idempotent. HCO client assumed via role/window lookup (no hardcoded AD_*_ID).

SET search_path TO adempiere, public;

DO $$
DECLARE
	v_client_id numeric;
	v_role_id   numeric;
	v_window_id numeric;
	v_btn_id    numeric;
	v_id        numeric;
	v_uu        text;
	r_window    text;
	r_btn       text;
	-- Fixed UUs we own for new Restrict rows (stable across re-runs)
	-- format: role|window|component -> restrict UU
BEGIN
	SELECT ad_client_id INTO v_client_id
	FROM ad_client
	WHERE name = 'HCO - Disability and Community Services' AND isactive = 'Y'
	ORDER BY ad_client_id
	LIMIT 1;

	IF v_client_id IS NULL THEN
		RAISE EXCEPTION 'SAW033: HCO client not found by name';
	END IF;

	-- Prefer the Support Worker role that already owns Restrict rows
	SELECT ad_role_id INTO v_role_id
	FROM ad_role
	WHERE ad_client_id = v_client_id
	  AND name = 'Support Worker'
	  AND ad_role_uu = '7c953364-e393-4522-ac9f-3478203c1ee3'
	LIMIT 1;

	IF v_role_id IS NULL THEN
		SELECT ad_role_id INTO v_role_id
		FROM ad_role
		WHERE ad_client_id = v_client_id AND name = 'Support Worker' AND isactive = 'Y'
		ORDER BY ad_role_id
		LIMIT 1;
	END IF;

	IF v_role_id IS NULL THEN
		RAISE EXCEPTION 'SAW033: Support Worker role not found';
	END IF;

	-- Windows to clean (name-stable on HCO)
	FOREACH r_window IN ARRAY ARRAY['Client', 'Support Location', 'Incident Report', 'Animal', 'Login']
	LOOP
		SELECT ad_window_id INTO v_window_id
		FROM ad_window
		WHERE name = r_window AND isactive = 'Y'
		ORDER BY ad_window_id
		LIMIT 1;

		IF v_window_id IS NULL THEN
			RAISE NOTICE 'SAW033: window % missing — skip', r_window;
			CONTINUE;
		END IF;

		-- Buttons to hide for Support Worker at WINDOW level (not state Save/Ignore)
		FOREACH r_btn IN ARRAY ARRAY[
			'New', 'Delete', 'Copy', 'Attachment', 'Chat', 'Requests',
			'Export', 'FileImport', 'CSVImport', 'ProductInfo', 'QuickForm',
			'Process', 'DetailRecord', 'ParentRecord', 'Archive', 'Help',
			'Lock', 'ActiveWorkflows', 'SaveCreate', 'AttributeForm',
			'Customize'
		]
		LOOP
			SELECT ad_toolbarbutton_id INTO v_btn_id
			FROM ad_toolbarbutton
			WHERE componentname = r_btn
			  AND action = 'W'
			  AND ad_tab_id IS NULL
			  AND isactive = 'Y'
			ORDER BY ad_toolbarbutton_id
			LIMIT 1;

			IF v_btn_id IS NULL THEN
				CONTINUE; -- button not on this build
			END IF;

			-- Stable UU from role+window+button UUs (deterministic-ish via md5 hex)
			v_uu := md5(
				'SAW033|' || v_role_id::text || '|' || v_window_id::text || '|' || v_btn_id::text || '|W'
			);
			-- normalize to UUID form
			v_uu := substr(v_uu,1,8) || '-' || substr(v_uu,9,4) || '-' || substr(v_uu,13,4) || '-' ||
			        substr(v_uu,17,4) || '-' || substr(v_uu,21,12);

			-- Only match WINDOW-level rows (never rewrite tab-scoped Restricts)
			SELECT ad_toolbarbuttonrestrict_id INTO v_id
			FROM ad_toolbarbuttonrestrict
			WHERE ad_tab_id IS NULL
			  AND (
					ad_toolbarbuttonrestrict_uu = v_uu
				 OR (
						ad_client_id = v_client_id
					AND ad_role_id = v_role_id
					AND ad_window_id = v_window_id
					AND ad_toolbarbutton_id = v_btn_id
					AND action = 'W'
				)
			)
			ORDER BY ad_toolbarbuttonrestrict_id
			LIMIT 1;

			IF v_id IS NULL THEN
				SELECT nextid(
					(SELECT ad_sequence_id::integer FROM ad_sequence
					 WHERE name = 'AD_ToolBarButtonRestrict' AND istableid = 'Y' LIMIT 1),
					'N'::varchar
				) INTO v_id;

				INSERT INTO ad_toolbarbuttonrestrict (
					ad_toolbarbuttonrestrict_id, ad_toolbarbuttonrestrict_uu,
					ad_client_id, ad_org_id, isactive,
					created, createdby, updated, updatedby,
					ad_role_id, ad_window_id, ad_toolbarbutton_id,
					action, isexclude, ad_tab_id, ad_process_id
				) VALUES (
					v_id, v_uu,
					v_client_id, 0, 'Y',
					NOW(), 100, NOW(), 100,
					v_role_id, v_window_id, v_btn_id,
					'W', 'Y', NULL, NULL
				);
				RAISE NOTICE 'SAW033: INSERT Restrict % / % / %', r_window, r_btn, v_uu;
			ELSE
				UPDATE ad_toolbarbuttonrestrict
				SET isactive = 'Y',
				    isexclude = 'Y',
				    action = 'W',
				    ad_toolbarbuttonrestrict_uu = COALESCE(NULLIF(ad_toolbarbuttonrestrict_uu, ''), v_uu),
				    updated = NOW(),
				    updatedby = 100
				WHERE ad_toolbarbuttonrestrict_id = v_id
				  AND ad_tab_id IS NULL;
				RAISE NOTICE 'SAW033: UPDATE Restrict % / % id=%', r_window, r_btn, v_id;
			END IF;
		END LOOP;
	END LOOP;

	RAISE NOTICE 'SAW033: toolbar Restrict window-level upsert complete (role=%, client=%)', v_role_id, v_client_id;
END $$;
