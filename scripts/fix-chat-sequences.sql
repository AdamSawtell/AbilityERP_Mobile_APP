SET search_path TO adempiere;

-- Sync sequences ahead of live MAX ids (fixes duplicate key on new chat)
UPDATE ad_sequence s
SET currentnext = GREATEST(
      s.currentnext,
      COALESCE((SELECT MAX(r_request_id) + s.incrementno FROM r_request), s.currentnext)
    ),
    updated = NOW(),
    updatedby = 100
WHERE s.name = 'R_Request';

UPDATE ad_sequence s
SET currentnext = GREATEST(
      s.currentnext,
      COALESCE((SELECT MAX(r_requestupdate_id) + s.incrementno FROM r_requestupdate), s.currentnext)
    ),
    updated = NOW(),
    updatedby = 100
WHERE s.name = 'R_RequestUpdate';

SELECT 'R_Request' AS tbl,
       (SELECT currentnext FROM ad_sequence WHERE name = 'R_Request') AS seq_next,
       (SELECT MAX(r_request_id) FROM r_request) AS max_id;

SELECT 'R_RequestUpdate' AS tbl,
       (SELECT currentnext FROM ad_sequence WHERE name = 'R_RequestUpdate') AS seq_next,
       (SELECT MAX(r_requestupdate_id) FROM r_requestupdate) AS max_id;

-- Closed status id used by app + iDempiere
SELECT r_status_id, name FROM r_status WHERE LOWER(name) = 'closed' AND isactive = 'Y';
