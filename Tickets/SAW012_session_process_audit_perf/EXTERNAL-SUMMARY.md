# SAW012 — External summary (customer / ticket paste)

## Windows / processes / objects affected

| Object | Type | Change |
|--------|------|--------|
| Session Audit | Window (core) | Faster open; Find-first; search fields; result cap |
| Process Audit | Window (core) | Faster open; Find-first; search fields; result cap |
| AD_Session / AD_PInstance | Tables | Marked high-volume; supporting indexes |
| House Keeping | Process / schedule | Retention purge for audit tables (when enabled) |

## What’s done

(Pending implementation after retention decision.) Plan: restore Session Audit and Process Audit so they open and search in seconds on large databases, keep full audit capability via Find, and optionally purge old audit rows on a schedule so the problem does not return.

## What changed (behaviour)

- Windows no longer try to load the entire audit history on open.
- Users search by date / process / user (Find), then see a limited recent result set.
- Optional cleanup removes audit rows older than the agreed retention period. Document Validation and other processes continue to write audit rows for new runs.

## Impact

Admins and support staff who use Session Audit or Process Audit. No change to day-to-day operational windows (Orders, Timesheets, Rostering, etc.).

## How to test

1. Log in as Admin → Cache Reset (or re-login).
2. Open Process Audit → complete Find (e.g. Created last 7 days) → results return quickly.
3. Open Session Audit → Find recent sessions → open Change Audit for one session.
4. Confirm you can still find older rows by widening the date range (until retention purge removes them).

## Access

AbilityERP Admin / System Admin retain access to these core windows. No new menu item.

## Caveats

- Very large historic tables may need a one-time off-peak purge and index build.
- If Document Validation continues to write a process-instance row on every document touch, Process Audit volume will grow again until that plugin behaviour is reviewed separately.
