# SAW012 — Deploy to another build (agent)

**Ticket / slug:** `SAW012_session_process_audit_perf`  
**Kind:** idempiere · **JAR:** No · **Status:** in-progress

## Required host access

- SSH · `psql` · WebUI Admin · Cache Reset  
- OSGi console: **not** required  
- Disk / maintenance window for index build + optional purge (large tables)

## Agent one-liner

```bash
cd Tickets/SAW012_session_process_audit_perf
# After SQL files exist (ordered):
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f sql/00-preflight.sql \
  -f sql/01-highvolume-and-tab-ux.sql \
  -f sql/02-indexes.sql \
  -f sql/03-housekeeping.sql \
  -f sql/04-verify.sql
# Optional off-peak: sql/10-batched-purge.sql (retention days as agreed)
# Then Cache Reset / re-login.
```

Or thin prod pack: `Downloads\AbilityERP-ProdUpdate-SAW012_session_process_audit_perf-*\` → `HOW-TO.txt`.

## Package

`Tickets/SAW012_session_process_audit_perf/sql/` (UU/name lookups only — never hardcode AD_*_ID).

Rollback: `sql/99-rollback.sql` (AD flags only; indexes/purge not fully reversible).

## AbilityERP Admin access

No new window/process. Core **Session Audit** / **Process Audit** — grant/verify System Admin (and AbilityERP Admin if used) already have window access. Smoke as **Admin** on HCO.

## WebUI smoke

1. Cache Reset.
2. Open **Process Audit** → Find dialog appears (High Volume) → filter last 7 days / one process → results in seconds, ≤ MaxQueryRecords.
3. Open **Session Audit** → Find → recent sessions load; Change Audit child usable for a selected session.
4. Confirm older rows still findable via date criteria (functionality preserved).

## Packs

- Staging: `AbilityERP-ClientUpdate-SAW012_session_process_audit_perf-*`  
- Prod: `AbilityERP-ProdUpdate-SAW012_session_process_audit_perf-*`

## External ticket text

`Tickets/SAW012_session_process_audit_perf/EXTERNAL-SUMMARY.md`

## Blockers / decisions before apply

- Retention days for purge + HouseKeeping (suggested 90).
- Whether Prod purge runs in same pack or as a separate maintenance step.
