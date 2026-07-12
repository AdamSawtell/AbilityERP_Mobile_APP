# SAW012 — Deploy to another build (agent)

**Ticket / slug:** `SAW012_session_process_audit_perf`  
**Kind:** idempiere · **JAR:** No · **Status:** in-progress (HCO AD+HK applied; indexes/purge in flight)

## Required host access

- SSH · `psql` · WebUI Admin · Cache Reset  
- Maintenance window for indexes + batched purge on large `AD_PInstance`

## Agent one-liner

```bash
cd Tickets/SAW012_session_process_audit_perf/sql
psql -d idempiere -v ON_ERROR_STOP=1 \
  -f 00-preflight.sql \
  -f 01-highvolume-and-tab-ux.sql \
  -f 03-housekeeping.sql
bash run-indexes.sh          # CONCURRENTLY; long on big DBs
# Cache Reset
psql -d idempiere -v ON_ERROR_STOP=1 -f 10-batched-purge.sql   # re-run off-peak until 0
psql -d idempiere -v ON_ERROR_STOP=1 -f 04-verify.sql
```

Thin prod pack: `Downloads\AbilityERP-ProdUpdate-SAW012_session_process_audit_perf-20260712\` → `HOW-TO.txt`.

## Package

`Tickets/SAW012_session_process_audit_perf/sql/` — UU/name lookups only.

Rollback: `99-rollback.sql` (AD only).

## AbilityERP Admin access

No new window. Smoke as **Admin**.

## WebUI smoke

1. Cache Reset.
2. **Process Audit** → Lookup Record (Find) with Created / Process / User → OK → ≤200 rows.
3. **Session Audit** → Find → recent sessions.

## Safety

Never unbounded delete of `AD_PInstance` — FKs can CASCADE to `C_Order` / `C_OrderLine`. Use pack purge + `aberp_pinstance_ok_to_purge()`.

## Packs

- Staging: `AbilityERP-ClientUpdate-SAW012_session_process_audit_perf-20260712`
- Prod: `AbilityERP-ProdUpdate-SAW012_session_process_audit_perf-20260712`

## External ticket text

`EXTERNAL-SUMMARY.md`
