SELECT pid, state, wait_event_type, left(query,160) AS q
FROM pg_stat_activity
WHERE datname='idempiere' AND state <> 'idle'
ORDER BY pid;

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname='idempiere'
  AND state <> 'idle'
  AND pid <> pg_backend_pid()
  AND (query ILIKE '%ad_pinstance%' OR query ILIKE '%Generate Bookings%' OR query ILIKE '%saw017%');
