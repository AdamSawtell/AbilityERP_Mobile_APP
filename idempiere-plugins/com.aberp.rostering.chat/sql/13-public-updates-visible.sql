SET search_path TO adempiere;

-- Make Rostering Chat updates visible (Public) — Confidential hides them from officers
UPDATE r_requestupdate u
SET confidentialtypeentry = 'A',
    updated = NOW(),
    updatedby = 100
FROM r_request r
JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
WHERE u.r_request_id = r.r_request_id
  AND rt.name = 'Rostering Chat'
  AND COALESCE(u.confidentialtypeentry, '') <> 'A';

UPDATE r_request r
SET confidentialtype = 'A',
    updated = NOW(),
    updatedby = 100
FROM r_requesttype rt
WHERE r.r_requesttype_id = rt.r_requesttype_id
  AND rt.name = 'Rostering Chat'
  AND COALESCE(r.confidentialtype, '') <> 'A';

-- Default new Updates rows to Public on this tab
UPDATE ad_field f
SET defaultvalue = '''A''',
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Updates'
  AND c.columnname = 'ConfidentialTypeEntry';

-- Ensure ConfidentialTypeEntry field exists (hidden) with Public default
INSERT INTO ad_field (
  ad_field_id, ad_client_id, ad_org_id, isactive,
  created, createdby, updated, updatedby,
  name, iscentrallymaintained, ad_tab_id, ad_column_id,
  isdisplayed, displaylength, isreadonly, seqno, defaultvalue,
  issameline, isheading, isfieldonly, isencrypted, entitytype,
  isdisplayedgrid, xposition, numlines, columnspan,
  isquickentry, istoolbarbutton, ad_field_uu
)
SELECT
  (SELECT COALESCE(MAX(ad_field_id),0)+1 FROM ad_field),
  0, 0, 'Y', NOW(), 100, NOW(), 100,
  'Confidentiality', 'N', t.ad_tab_id, c.ad_column_id,
  'N', 1, 'Y', 5, '''A''',
  'N', 'N', 'N', 'N', 'Ab_ERP',
  'N', 1, 1, 1, 'N', 'N',
  substring(md5('AbERP_RosteringChat-upd-conf'), 1, 8) || '-' ||
  substring(md5('AbERP_RosteringChat-upd-conf'), 9, 4) || '-4a16-8016-000000000016'
FROM ad_tab t
JOIN ad_window w ON w.ad_window_id = t.ad_window_id
JOIN ad_column c ON c.ad_table_id = t.ad_table_id AND c.columnname = 'ConfidentialTypeEntry'
WHERE w.name = 'Rostering Chat' AND t.name = 'Updates'
  AND NOT EXISTS (
    SELECT 1 FROM ad_field f WHERE f.ad_tab_id = t.ad_tab_id AND f.ad_column_id = c.ad_column_id
  );

UPDATE ad_field f
SET defaultvalue = '''A''', isdisplayed = 'N', isreadonly = 'Y',
    updated = NOW(), updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Updates'
  AND c.columnname = 'ConfidentialTypeEntry';

-- Also default Chat header confidentiality to Public
UPDATE ad_field f
SET defaultvalue = '''A''',
    updated = NOW(),
    updatedby = 100
FROM ad_column c, ad_tab t, ad_window w
WHERE f.ad_column_id = c.ad_column_id
  AND f.ad_tab_id = t.ad_tab_id
  AND t.ad_window_id = w.ad_window_id
  AND w.name = 'Rostering Chat' AND t.name = 'Chat'
  AND c.columnname = 'ConfidentialType';

SELECT confidentialtypeentry, COUNT(*)
FROM r_requestupdate u
JOIN r_request r ON r.r_request_id = u.r_request_id
JOIN r_requesttype rt ON rt.r_requesttype_id = r.r_requesttype_id
WHERE rt.name = 'Rostering Chat'
GROUP BY 1;

SELECT r_request_id, confidentialtype FROM r_request WHERE r_request_id = 1000095;
