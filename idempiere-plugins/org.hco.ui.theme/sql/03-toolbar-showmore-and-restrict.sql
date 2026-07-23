-- SAW033 — Make Show-More toolbar Restrict effective + hide extra chrome
--
-- Root cause: Restrict names are "Btn" + ComponentName and removeChild works on
-- the main toolbar. Buttons with IsShowMore='Y' live in the More menupopup;
-- Menuitem value matching often leaves Attachment/Chat/Requests visible even
-- when Restrict rows exist.
--
-- Fix: put those buttons back on the main toolbar (IsShowMore='N') so Restrict
-- can remove them like New/Delete. Also add Print / Document Explorer /
-- PrintFormatEditor window-level Restrict for Support Worker on key windows.
--
-- Idempotent. Does not touch Save/Ignore (state buttons — theme CSS hides when disabled).

SET search_path TO adempiere, public;

-- 1) Move role-sensitive buttons out of Show More so Restrict can remove them
UPDATE ad_toolbarbutton
SET isshowmore = 'N',
    updated = NOW(),
    updatedby = 100
WHERE action = 'W'
  AND ad_tab_id IS NULL
  AND isactive = 'Y'
  AND isshowmore = 'Y'
  AND componentname IN ('Attachment', 'Chat', 'Requests');

-- 2) Window-level Restrict for remaining clutter (Support Worker)
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
BEGIN
	SELECT ad_client_id INTO v_client_id
	FROM ad_client
	WHERE name = 'HCO - Disability and Community Services' AND isactive = 'Y'
	ORDER BY ad_client_id
	LIMIT 1;

	IF v_client_id IS NULL THEN
		RAISE EXCEPTION 'SAW033: HCO client not found';
	END IF;

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

	FOREACH r_window IN ARRAY ARRAY['Client', 'Support Location', 'Incident Report', 'Animal', 'Login', 'Employee']
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

		FOREACH r_btn IN ARRAY ARRAY[
			'Attachment', 'Chat', 'Requests', 'Print',
			'Document Explorer', 'PrintFormatEditor'
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
				CONTINUE;
			END IF;

			v_uu := md5('SAW033|' || v_role_id::text || '|' || v_window_id::text || '|' || v_btn_id::text || '|W');
			v_uu := substr(v_uu,1,8) || '-' || substr(v_uu,9,4) || '-' || substr(v_uu,13,4) || '-' ||
			        substr(v_uu,17,4) || '-' || substr(v_uu,21,12);

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
				RAISE NOTICE 'SAW033: INSERT Restrict % / %', r_window, r_btn;
			ELSE
				UPDATE ad_toolbarbuttonrestrict
				SET isactive = 'Y', isexclude = 'Y', action = 'W',
				    updated = NOW(), updatedby = 100
				WHERE ad_toolbarbuttonrestrict_id = v_id AND ad_tab_id IS NULL;
				RAISE NOTICE 'SAW033: UPDATE Restrict % / %', r_window, r_btn;
			END IF;
		END LOOP;
	END LOOP;
END $$;
