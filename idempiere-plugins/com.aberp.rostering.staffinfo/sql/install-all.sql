-- Convenience runner when \ir is unavailable (e.g. some hosts).
-- Prefer deploy.sh which runs 01→04 explicitly.

SET search_path TO adempiere;
\echo Use deploy.sh or run 01-indexes, 02-rewrite-infowindow, 03-rewrite-infocolumns, 04-verify in order.
